CREATE OR REPLACE PACKAGE BODY pkg_ga_evolver AS

PROCEDURE upsert_evolution_trial(
	p_trial_id                  evolution_trial.trial_id%TYPE,
	p_control_generation        evolution_trial.control_generation%TYPE,
	p_generation_size           evolution_trial.generation_size%TYPE,
	p_max_generations           evolution_trial.max_generations%TYPE,
	p_crossover_rate            evolution_trial.crossover_rate%TYPE,
	p_crossover_point           evolution_trial.crossover_point%TYPE,
	p_mutation_rate             evolution_trial.mutation_rate%TYPE,
	p_players_per_tournament    evolution_trial.players_per_tournament%TYPE,
	p_tournament_play_count     evolution_trial.tournament_play_count%TYPE,
	p_tournament_buy_in         evolution_trial.tournament_buy_in%TYPE,
	p_initial_small_blind_value evolution_trial.initial_small_blind_value%TYPE,
	p_double_blinds_interval    evolution_trial.double_blinds_interval%TYPE,
	p_current_generation        evolution_trial.current_generation%TYPE
) IS
BEGIN

	MERGE INTO evolution_trial et USING (SELECT dummy FROM DUAL) s ON (
		et.trial_id = p_trial_id
	) WHEN MATCHED THEN UPDATE SET
		control_generation = p_control_generation,
		generation_size = p_generation_size,
		max_generations = p_max_generations,
		crossover_rate = p_crossover_rate,
		crossover_point = p_crossover_point,
		mutation_rate = p_mutation_rate,
		players_per_tournament = p_players_per_tournament,
		tournament_play_count = p_tournament_play_count,
		tournament_buy_in = p_tournament_buy_in,
		initial_small_blind_value = p_initial_small_blind_value,
		double_blinds_interval = p_double_blinds_interval,
		current_generation = p_current_generation,
		trial_complete = 'N'
	WHEN NOT MATCHED THEN INSERT (
		trial_id,
		control_generation,
		generation_size,
		max_generations,
		crossover_rate,
		crossover_point,
		mutation_rate,
		players_per_tournament,
		tournament_play_count,
		tournament_buy_in,
		initial_small_blind_value,
		double_blinds_interval,
		current_generation,
		trial_complete
	) VALUES (
		p_trial_id,
		p_control_generation,
		p_generation_size,
		p_max_generations,
		p_crossover_rate,
		p_crossover_point,
		p_mutation_rate,
		p_players_per_tournament,
		p_tournament_play_count,
		p_tournament_buy_in,
		p_initial_small_blind_value,
		p_double_blinds_interval,
		p_current_generation,
		'N'
	);
	
	COMMIT;
	
END upsert_evolution_trial;

FUNCTION step_generation(
	p_trial_id evolution_trial.trial_id%TYPE
) RETURN INTEGER IS

	v_work_remains VARCHAR2(1);

BEGIN

	-- check if there is any remaining work to do by the tournament runner workers
	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END work_remains
	INTO   v_work_remains
	FROM   evolution_trial_work
	WHERE  trial_id = p_trial_id
	   AND played = 'N';
	IF v_work_remains = 'Y' THEN
		-- tournament runner work remains for current generation
		RETURN 0;
	END IF;

	-- check if trial is complete
	SELECT CASE WHEN current_generation >= max_generations THEN 'N' ELSE 'Y' END work_remains
	INTO   v_work_remains
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;
	IF v_work_remains = 'N' THEN
		-- all generations complete, no work to perform
		RETURN -1;
	END IF;
	
	-- a new generation should be created
	RETURN 1;
		
END step_generation;

PROCEDURE enqueue_tournaments(
	p_trial_id evolution_trial.trial_id%TYPE
) IS

	v_evolution_trial            evolution_trial%ROWTYPE;
	v_tournament_id              poker_state_log.tournament_id%TYPE;
	v_control_gen_strat_id_array t_strategy_id_varray;
	v_strategy_id_array          t_strategy_id_varray;
	v_rand_strategy_id_array     t_strategy_id_varray;
	v_payload                    t_row_evolution_trial_queue;
	v_enqueue_options            DBMS_AQ.ENQUEUE_OPTIONS_T;
	v_message_properties         DBMS_AQ.MESSAGE_PROPERTIES_T;
	v_message_handle             RAW(16);

BEGIN

	-- get trial attributes
	SELECT *
	INTO   v_evolution_trial
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;
	
	-- clear any trial work records from previous iteration
	DELETE FROM evolution_trial_work
	WHERE trial_id = p_trial_id;
	
	-- define tournament work
	FOR v_tournament_sequence IN 1 .. v_evolution_trial.tournament_play_count LOOP

		WITH full_control_generation AS (
			SELECT strategy_id
			FROM   strategy
			WHERE  generation = v_evolution_trial.control_generation
			ORDER BY DBMS_RANDOM.VALUE
		),
		
		control_generation AS (
			SELECT strategy_id
			FROM   full_control_generation
			WHERE  ROWNUM <= v_evolution_trial.players_per_tournament - 1
		)
		
		SELECT strategy_id
		BULK COLLECT INTO v_control_gen_strat_id_array
		FROM   control_generation;

		FOR v_current_gen_rec IN (
			SELECT strategy_id
			FROM   strategy
			WHERE  generation = v_evolution_trial.current_generation
			ORDER BY DBMS_RANDOM.VALUE
		) LOOP
		
			v_tournament_id := pai_seq_tid.NEXTVAL;
			v_strategy_id_array := v_control_gen_strat_id_array;
			v_strategy_id_array.EXTEND(1);
			v_strategy_id_array(v_strategy_id_array.LAST) := v_current_gen_rec.strategy_id;
			
			-- randomize seats
			SELECT column_value
			BULK COLLECT INTO v_rand_strategy_id_array
			FROM TABLE(v_strategy_id_array)
			ORDER BY DBMS_RANDOM.VALUE;
			
			INSERT INTO evolution_trial_work (
				trial_id,
				tournament_id,
				strategy_id,
				played
			)
			SELECT p_trial_id trial_id,
				   v_tournament_id tournament_id,
				   column_value strategy_id,
				   'N' played
			FROM   TABLE(v_rand_strategy_id_array);
			
			v_payload := t_row_evolution_trial_queue(
				trial_id      => p_trial_id,
				tournament_id => v_tournament_id,
				player_count  => v_evolution_trial.players_per_tournament,
				strategy_ids  => v_rand_strategy_id_array
			);
				
			DBMS_AQ.ENQUEUE(
				queue_name         => 'ev_trial_work_queue',
				enqueue_options    => v_enqueue_options,
				message_properties => v_message_properties,
				payload            => v_payload,
				msgid              => v_message_handle
			);

		END LOOP;
	
	END LOOP;
	COMMIT;
	
END enqueue_tournaments;

FUNCTION select_tournament_work (
	p_trial_id                   evolution_trial.trial_id%TYPE,
	p_tournament_work            OUT t_rc_generic,
	p_tournament_work_strategies OUT t_rc_generic
) RETURN INTEGER IS

	v_strategy_record           t_row_number := t_row_number(NULL);
	v_strategy_ids              t_tbl_number := t_tbl_number();
	v_dequeue_options           DBMS_AQ.DEQUEUE_OPTIONS_T;
	v_message_properties        DBMS_AQ.MESSAGE_PROPERTIES_T;
	v_payload                   t_row_evolution_trial_queue;
	v_message_handle            RAW(16);
	v_player_count_sanity_check evolution_trial.players_per_tournament%TYPE;
	v_ppt_sanity_check          evolution_trial.players_per_tournament%TYPE;
	v_trial_complete            evolution_trial.trial_complete%TYPE;
	v_work_to_perform           BOOLEAN := TRUE;
	
BEGIN
	
	-- attempt to dequeue a message
	BEGIN
		v_dequeue_options.wait := DBMS_AQ.NO_WAIT;
		DBMS_AQ.DEQUEUE(
			queue_name         => 'ev_trial_work_queue',
			dequeue_options    => v_dequeue_options,
			message_properties => v_message_properties,
			payload            => v_payload,
			msgid              => v_message_handle
		);
		
		EXCEPTION WHEN OTHERS THEN
			IF SQLCODE = -25228 THEN  -- dequeue of an empty queue
				v_work_to_perform := FALSE;
			ELSE
				RAISE;
			END IF;
	END;
	
	IF v_work_to_perform THEN
	
		-- setup strategy IDs for tournament
		v_strategy_ids.DELETE;
		FOR v_i IN 1 .. v_payload.player_count LOOP
			v_strategy_record.value := v_payload.strategy_ids(v_i);
			v_strategy_ids.EXTEND;
			v_strategy_ids(v_i) := v_strategy_record;
		END LOOP;

		-- debug - player count sanity check
		SELECT players_per_tournament
		INTO   v_ppt_sanity_check
		FROM   evolution_trial
		WHERE  trial_id = p_trial_id;
		SELECT COUNT(*) player_count_sanity_check
		INTO   v_player_count_sanity_check
		FROM   TABLE(v_strategy_ids);
		IF v_player_count_sanity_check != v_ppt_sanity_check THEN
			RAISE_APPLICATION_ERROR(-20000, 'tournament player count sanity check failed, '
				|| v_player_count_sanity_check || ' players selected for tournament of '
				|| v_ppt_sanity_check || ' players');
		END IF;

		OPEN p_tournament_work FOR
			SELECT v_payload.tournament_id tournament_id,
				   v_payload.player_count player_count,
				   tournament_buy_in,
				   initial_small_blind_value,
				   double_blinds_interval
			FROM   evolution_trial
			WHERE  trial_id = p_trial_id;

		OPEN p_tournament_work_strategies FOR
			SELECT value strategy_id
			FROM   TABLE(v_strategy_ids)
			ORDER BY strategy_id;
			
		-- indicate tournament work to perform
		COMMIT;
		RETURN 0;
				   
	ELSE
	
		-- empty queue, check if trial is complete
		SELECT trial_complete
		INTO   v_trial_complete
		FROM   evolution_trial
		WHERE  trial_id = p_trial_id;

		IF v_trial_complete = 'Y' THEN
			-- all generations complete, no work to perform
			RETURN -1;
		ELSE
			-- there is no tournament work to perform, but generation work remains
			RETURN 1;
		END IF;
		
	END IF;
	
	EXCEPTION WHEN OTHERS THEN
		IF p_tournament_work%ISOPEN THEN
			CLOSE p_tournament_work;
		END IF;
		IF p_tournament_work_strategies%ISOPEN THEN
			CLOSE p_tournament_work_strategies;
		END IF;
		RAISE;
		
END select_tournament_work;

PROCEDURE set_current_generation(
	p_trial_id           evolution_trial.trial_id%TYPE,
	p_current_generation evolution_trial.current_generation%TYPE
) IS
BEGIN

	UPDATE evolution_trial
	SET    current_generation = p_current_generation
	WHERE  trial_id = p_trial_id;

	pkg_ga_evolver.enqueue_tournaments(p_trial_id => p_trial_id);

END set_current_generation;

PROCEDURE select_parent_generation(
	p_trial_id         evolution_trial.trial_id%TYPE,
	p_generation       strategy.generation%TYPE,
	p_trial_attributes OUT t_rc_generic,
	p_parents          OUT t_rc_generic
) IS

	v_crossover_rate  evolution_trial.crossover_rate%TYPE;
	v_crossover_point evolution_trial.crossover_point%TYPE;
	v_mutation_rate   evolution_trial.mutation_rate%TYPE;
	v_generation_size evolution_trial.generation_size%TYPE;

BEGIN

	SELECT crossover_rate,
		   crossover_point,
		   mutation_rate,
		   generation_size
	INTO   v_crossover_rate,
		   v_crossover_point,
		   v_mutation_rate,
		   v_generation_size
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;

	OPEN p_trial_attributes FOR
		SELECT v_crossover_point crossover_point,
			   v_mutation_rate mutation_rate,
			   v_generation_size generation_size
		FROM   DUAL;
		   
	OPEN p_parents FOR
		-- current generation attributes
		WITH current_generation AS (
			SELECT /*+ MATERIALIZE */
				   s.strategy_id,
				   sf.fitness_score
			FROM   strategy s,
				   strategy_fitness sf
			WHERE  s.generation = p_generation
			   AND s.strategy_id = sf.strategy_id
			   AND sf.evolution_trial_id = p_trial_id
		),

		-- total fitness of current generation
		total_fitness AS (
			SELECT /*+ MATERIALIZE */
				   SUM(fitness_score) total_fitness_score
			FROM   current_generation
		),

		-- fitness proportion of each strategy in current generation
		proportioned_generation AS (
			SELECT /*+ MATERIALIZE */
				   cg.strategy_id,
				   (cg.fitness_score / NULLIF(tf.total_fitness_score, 0)) fitness_proportion,
				   DENSE_RANK() OVER (ORDER BY cg.fitness_score / NULLIF(tf.total_fitness_score, 0), cg.strategy_id) strategy_rank
			FROM   current_generation cg,
				   total_fitness tf
		),

		-- ID of strategy with highest rank
		max_rank_strategy_id AS (
			SELECT /*+ MATERIALIZE */
				   strategy_id
			FROM   proportioned_generation
			WHERE  strategy_rank = (SELECT /*+ MATERIALIZE */ MAX(strategy_rank) FROM proportioned_generation)
		),
		
		-- fitness proportion limits of each strategy in current generation
		proportion_limits AS (
			SELECT /*+ MATERIALIZE */
				   pg_b.strategy_id,
				   NVL(SUM(CASE WHEN pg_a.strategy_rank < pg_b.strategy_rank THEN pg_a.fitness_proportion END), 0) lower_limit,
				   CASE WHEN pg_b.strategy_id = mrsid.strategy_id THEN 1
						ELSE (NVL(SUM(CASE WHEN pg_a.strategy_rank < pg_b.strategy_rank THEN pg_a.fitness_proportion END), 0)
								+ pg_b.fitness_proportion)
				   END upper_limit
			FROM   proportioned_generation pg_a,
				   proportioned_generation pg_b,
				   max_rank_strategy_id mrsid
			WHERE  pg_b.fitness_proportion > 0
			GROUP BY
				pg_b.strategy_id,
				pg_b.fitness_proportion,
				mrsid.strategy_id
		),

		-- random numbers to represent parent selection from current generation
		random_parent_numbers AS (
			SELECT /*+ MATERIALIZE */
				   CASE WHEN DBMS_RANDOM.VALUE < v_crossover_rate THEN 1 ELSE 0 END perform_crossover,
				   DBMS_RANDOM.VALUE parent_a_rand,
				   DBMS_RANDOM.VALUE parent_b_rand
			FROM   DUAL
			CONNECT BY ROWNUM <= v_generation_size / 2
		)

		-- roulette wheel selection of parent strategies from current generation
		SELECT /*+ MATERIALIZE */
			   rpn.perform_crossover,
			   pl_a.strategy_id parent_a_strategy_id,
			   pl_b.strategy_id parent_b_strategy_id
		FROM   random_parent_numbers rpn,
			   proportion_limits pl_a,
			   proportion_limits pl_b
		WHERE  pl_a.lower_limit <= rpn.parent_a_rand
		   AND pl_a.upper_limit > rpn.parent_a_rand
		   AND pl_b.lower_limit <= rpn.parent_b_rand
		   AND pl_b.upper_limit > rpn.parent_b_rand;
		
	EXCEPTION WHEN OTHERS THEN
		IF p_trial_attributes%ISOPEN THEN
			CLOSE p_trial_attributes;
		END IF;
		IF p_parents%ISOPEN THEN
			CLOSE p_parents;
		END IF;
		RAISE;
		
END select_parent_generation;

PROCEDURE mark_trial_complete(
	p_trial_id evolution_trial.trial_id%TYPE
) IS
BEGIN

	UPDATE evolution_trial
	SET    trial_complete = 'Y'
	WHERE  trial_id = p_trial_id;
	COMMIT;
	
END mark_trial_complete;

PROCEDURE update_strategy_fitness(
	p_trial_id evolution_trial.trial_id%TYPE
) IS

	v_min_average_game_profit strategy_fitness.average_game_profit%TYPE;

BEGIN

	-- update aggregate strategy fitness values
	MERGE INTO strategy_fitness d USING (
		SELECT tr.strategy_id,
			   COUNT(*) tournaments_played,
			   SUM(tr.games_played) games_played,
			   SUM(tr.main_pots_won) main_pots_won,
			   SUM(tr.main_pots_split) main_pots_split,
			   SUM(tr.side_pots_won) side_pots_won,
			   SUM(tr.side_pots_split) side_pots_split,
			   SUM(tr.flops_seen) flops_seen,
			   SUM(tr.turns_seen) turns_seen,
			   SUM(tr.rivers_seen) rivers_seen,
			   SUM(tr.pre_flop_folds) pre_flop_folds,
			   SUM(tr.flop_folds) flop_folds,
			   SUM(tr.turn_folds) turn_folds,
			   SUM(tr.river_folds) river_folds,
			   SUM(tr.total_folds) total_folds,
			   SUM(tr.pre_flop_checks) pre_flop_checks,
			   SUM(tr.flop_checks) flop_checks,
			   SUM(tr.turn_checks) turn_checks,
			   SUM(tr.river_checks) river_checks,
			   SUM(tr.total_checks) total_checks,
			   SUM(tr.pre_flop_calls) pre_flop_calls,
			   SUM(tr.flop_calls) flop_calls,
			   SUM(tr.turn_calls) turn_calls,
			   SUM(tr.river_calls) river_calls,
			   SUM(tr.total_calls) total_calls,
			   SUM(tr.pre_flop_bets) pre_flop_bets,
			   SUM(tr.flop_bets) flop_bets,
			   SUM(tr.turn_bets) turn_bets,
			   SUM(tr.river_bets) river_bets,
			   SUM(tr.total_bets) total_bets,
			   SUM(tr.pre_flop_total_bet_amount) pre_flop_total_bet_amount,
			   SUM(tr.flop_total_bet_amount) flop_total_bet_amount,
			   SUM(tr.turn_total_bet_amount) turn_total_bet_amount,
			   SUM(tr.river_total_bet_amount) river_total_bet_amount,
			   SUM(tr.total_bet_amount) total_bet_amount,
			   SUM(tr.pre_flop_raises) pre_flop_raises,
			   SUM(tr.flop_raises) flop_raises,
			   SUM(tr.turn_raises) turn_raises,
			   SUM(tr.river_raises) river_raises,
			   SUM(tr.total_raises) total_raises,
			   SUM(tr.pre_flop_total_raise_amount) pre_flop_total_raise_amount,
			   SUM(tr.flop_total_raise_amount) flop_total_raise_amount,
			   SUM(tr.turn_total_raise_amount) turn_total_raise_amount,
			   SUM(tr.river_total_raise_amount) river_total_raise_amount,
			   SUM(tr.total_raise_amount) total_raise_amount,
			   SUM(tr.times_all_in) times_all_in,
			   SUM(tr.total_money_played) total_money_played,
			   SUM(tr.total_money_won) total_money_won
		FROM   evolution_trial et,
			   tournament_result tr,
			   strategy s
		WHERE  et.trial_id = p_trial_id
		   AND et.trial_id = tr.evolution_trial_id
		   AND tr.strategy_id = s.strategy_id
		   AND et.current_generation = s.generation
		GROUP BY tr.strategy_id
	) s ON (
		d.strategy_id = s.strategy_id
		AND d.evolution_trial_id = p_trial_id
	) WHEN MATCHED THEN UPDATE SET
		d.tournaments_played = d.tournaments_played + s.tournaments_played,
		d.games_played = d.games_played + s.games_played,
		d.main_pots_won = d.main_pots_won + s.main_pots_won,
		d.main_pots_split = d.main_pots_split + s.main_pots_split,
		d.side_pots_won = d.side_pots_won + s.side_pots_won,
		d.side_pots_split = d.side_pots_split + s.side_pots_split,
		d.flops_seen = d.flops_seen + s.flops_seen,
		d.turns_seen = d.turns_seen + s.turns_seen,
		d.rivers_seen = d.rivers_seen + s.rivers_seen,
		d.pre_flop_folds = d.pre_flop_folds + s.pre_flop_folds,
		d.flop_folds = d.flop_folds + s.flop_folds,
		d.turn_folds = d.turn_folds + s.turn_folds,
		d.river_folds = d.river_folds + s.river_folds,
		d.total_folds = d.total_folds + s.total_folds,
		d.pre_flop_checks = d.pre_flop_checks + s.pre_flop_checks,
		d.flop_checks = d.flop_checks + s.flop_checks,
		d.turn_checks = d.turn_checks + s.turn_checks,
		d.river_checks = d.river_checks + s.river_checks,
		d.total_checks = d.total_checks + s.total_checks,
		d.pre_flop_calls = d.pre_flop_calls + s.pre_flop_calls,
		d.flop_calls = d.flop_calls + s.flop_calls,
		d.turn_calls = d.turn_calls + s.turn_calls,
		d.river_calls = d.river_calls + s.river_calls,
		d.total_calls = d.total_calls + s.total_calls,
		d.pre_flop_bets = d.pre_flop_bets + s.pre_flop_bets,
		d.flop_bets = d.flop_bets + s.flop_bets,
		d.turn_bets = d.turn_bets + s.turn_bets,
		d.river_bets = d.river_bets + s.river_bets,
		d.total_bets = d.total_bets + s.total_bets,
		d.pre_flop_total_bet_amount = d.pre_flop_total_bet_amount + s.pre_flop_total_bet_amount,
		d.flop_total_bet_amount = d.flop_total_bet_amount + s.flop_total_bet_amount,
		d.turn_total_bet_amount = d.turn_total_bet_amount + s.turn_total_bet_amount,
		d.river_total_bet_amount = d.river_total_bet_amount + s.river_total_bet_amount,
		d.total_bet_amount = d.total_bet_amount + s.total_bet_amount,
		d.pre_flop_raises = d.pre_flop_raises + s.pre_flop_raises,
		d.flop_raises = d.flop_raises + s.flop_raises,
		d.turn_raises = d.turn_raises + s.turn_raises,
		d.river_raises = d.river_raises + s.river_raises,
		d.total_raises = d.total_raises + s.total_raises,
		d.pre_flop_total_raise_amount = d.pre_flop_total_raise_amount + s.pre_flop_total_raise_amount,
		d.flop_total_raise_amount = d.flop_total_raise_amount + s.flop_total_raise_amount,
		d.turn_total_raise_amount = d.turn_total_raise_amount + s.turn_total_raise_amount,
		d.river_total_raise_amount = d.river_total_raise_amount + s.river_total_raise_amount,
		d.total_raise_amount = d.total_raise_amount + s.total_raise_amount,
		d.times_all_in = d.times_all_in + s.times_all_in,
		d.total_money_played = d.total_money_played + s.total_money_played,
		d.total_money_won = d.total_money_won + s.total_money_won
	WHEN NOT MATCHED THEN INSERT (
		strategy_id,
		evolution_trial_id,
		tournaments_played,
		games_played,
		main_pots_won,
		main_pots_split,
		side_pots_won,
		side_pots_split,
		flops_seen,
		turns_seen,
		rivers_seen,
		pre_flop_folds,
		flop_folds,
		turn_folds,
		river_folds,
		total_folds,
		pre_flop_checks,
		flop_checks,
		turn_checks,
		river_checks,
		total_checks,
		pre_flop_calls,
		flop_calls,
		turn_calls,
		river_calls,
		total_calls,
		pre_flop_bets,
		flop_bets,
		turn_bets,
		river_bets,
		total_bets,
		pre_flop_total_bet_amount,
		flop_total_bet_amount,
		turn_total_bet_amount,
		river_total_bet_amount,
		total_bet_amount,
		pre_flop_raises,
		flop_raises,
		turn_raises,
		river_raises,
		total_raises,
		pre_flop_total_raise_amount,
		flop_total_raise_amount,
		turn_total_raise_amount,
		river_total_raise_amount,
		total_raise_amount,
		times_all_in,
		total_money_played,
		total_money_won
	) VALUES (
		s.strategy_id,
		p_trial_id,
		s.tournaments_played,
		s.games_played,
		s.main_pots_won,
		s.main_pots_split,
		s.side_pots_won,
		s.side_pots_split,
		s.flops_seen,
		s.turns_seen,
		s.rivers_seen,
		s.pre_flop_folds,
		s.flop_folds,
		s.turn_folds,
		s.river_folds,
		s.total_folds,
		s.pre_flop_checks,
		s.flop_checks,
		s.turn_checks,
		s.river_checks,
		s.total_checks,
		s.pre_flop_calls,
		s.flop_calls,
		s.turn_calls,
		s.river_calls,
		s.total_calls,
		s.pre_flop_bets,
		s.flop_bets,
		s.turn_bets,
		s.river_bets,
		s.total_bets,
		s.pre_flop_total_bet_amount,
		s.flop_total_bet_amount,
		s.turn_total_bet_amount,
		s.river_total_bet_amount,
		s.total_bet_amount,
		s.pre_flop_raises,
		s.flop_raises,
		s.turn_raises,
		s.river_raises,
		s.total_raises,
		s.pre_flop_total_raise_amount,
		s.flop_total_raise_amount,
		s.turn_total_raise_amount,
		s.river_total_raise_amount,
		s.total_raise_amount,
		s.times_all_in,
		s.total_money_played,
		s.total_money_won
	);

	-- udpate averages dependent on newly updated aggregate values
	MERGE INTO strategy_fitness d USING (
		SELECT DISTINCT tr.strategy_id
		FROM   evolution_trial et,
			   tournament_result tr,
			   strategy s
		WHERE  et.trial_id = p_trial_id
		   AND et.trial_id = tr.evolution_trial_id
		   AND tr.strategy_id = s.strategy_id
		   AND et.current_generation = s.generation
	) s ON (
		d.strategy_id = s.strategy_id
		AND d.evolution_trial_id = p_trial_id
	) WHEN MATCHED THEN UPDATE SET
		d.average_tournament_profit = (d.total_money_won - d.total_money_played) / NULLIF(d.tournaments_played, 0),
		d.average_game_profit = (d.total_money_won - d.total_money_played) / NULLIF(d.games_played, 0),
		d.pre_flop_average_bet_amount = d.pre_flop_total_bet_amount / NULLIF(d.pre_flop_bets, 0),
		d.flop_average_bet_amount = d.flop_total_bet_amount / NULLIF(d.flop_bets, 0),
		d.turn_average_bet_amount = d.turn_total_bet_amount / NULLIF(d.turn_bets, 0),
		d.river_average_bet_amount = d.river_total_bet_amount / NULLIF(d.river_bets, 0),
		d.average_bet_amount = d.total_bet_amount / NULLIF(d.total_bets, 0),
		d.pre_flop_average_raise_amount = d.pre_flop_total_raise_amount / NULLIF(d.pre_flop_raises, 0),
		d.flop_average_raise_amount = d.flop_total_raise_amount / NULLIF(d.flop_raises, 0),
		d.turn_average_raise_amount = d.turn_total_raise_amount / NULLIF(d.turn_raises, 0),
		d.river_average_raise_amount = d.river_total_raise_amount / NULLIF(d.river_raises, 0),
		d.average_raise_amount = d.total_raise_amount / NULLIF(d.total_raises, 0);

	-- normalize fitness scores for the fitness test group to be a value >= 0
	SELECT MIN(average_game_profit) min_average_game_profit
	INTO   v_min_average_game_profit
	FROM   strategy_fitness
	WHERE  evolution_trial_id = p_trial_id
	   AND average_game_profit < 0;

	UPDATE strategy_fitness
	SET    fitness_score = NVL(ABS(v_min_average_game_profit), 0) + average_game_profit
	WHERE  evolution_trial_id = p_trial_id;
	
	COMMIT;

END update_strategy_fitness;

END pkg_ga_evolver;
