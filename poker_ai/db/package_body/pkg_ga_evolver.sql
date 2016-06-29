CREATE OR REPLACE PACKAGE BODY pkg_ga_evolver AS

PROCEDURE init_evolution_trial(
	p_trial_id                  evolution_trial.trial_id%TYPE,
	p_generation_size           evolution_trial.generation_size%TYPE,
	p_max_generations           evolution_trial.max_generations%TYPE,
	p_crossover_rate            evolution_trial.crossover_rate%TYPE,
	p_crossover_point           evolution_trial.crossover_point%TYPE,
	p_mutation_rate             evolution_trial.mutation_rate%TYPE,
	p_players_per_tournament    evolution_trial.players_per_tournament%TYPE,
	p_tournament_play_count     evolution_trial.tournament_play_count%TYPE,
	p_tournament_buy_in         evolution_trial.tournament_buy_in%TYPE,
	p_initial_small_blind_value evolution_trial.initial_small_blind_value%TYPE,
	p_double_blinds_interval    evolution_trial.double_blinds_interval%TYPE
) IS

	v_crossover_point evolution_trial.crossover_point%TYPE;
	v_mutation_rate   evolution_trial.mutation_rate%TYPE;
	
BEGIN
	
	pkg_poker_ai.log(p_message => 'begin initialization of trial, p_trial_id = ' || p_trial_id);
	
	-- default crossover point to halfway through chromosome if no value specified
	IF p_crossover_point IS NULL THEN
		v_crossover_point := FLOOR(pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length / 2);
	ELSE
		v_crossover_point := p_crossover_point;
	END IF;
	
	-- default mutation rate to 1 / bit length is no value is specified
	IF p_mutation_rate IS NULL THEN
		v_mutation_rate := 1 / pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length;
	ELSE
		v_mutation_rate := p_mutation_rate;
	END IF;

	INSERT INTO evolution_trial (
		trial_id,
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
		current_generation
	) VALUES (
		p_trial_id,
		p_generation_size,
		p_max_generations,
		p_crossover_rate,
		v_crossover_point,
		v_mutation_rate,
		p_players_per_tournament,
		p_tournament_play_count,
		p_tournament_buy_in,
		p_initial_small_blind_value,
		p_double_blinds_interval,
		1
	);
	
	pkg_ga_evolver.create_initial_generation(
		p_trial_id               => p_trial_id,
		p_generation_size        => p_generation_size,
		p_tournament_play_count  => p_tournament_play_count,
		p_players_per_tournament => p_players_per_tournament
	);
	COMMIT;

	pkg_poker_ai.log(p_message => 'end initialization of trial, p_trial_id = ' || p_trial_id);
	
END init_evolution_trial;

PROCEDURE create_initial_generation(
	p_trial_id               evolution_trial.trial_id%TYPE,
	p_generation_size        evolution_trial.generation_size%TYPE,
	p_tournament_play_count  evolution_trial.tournament_play_count%TYPE,
	p_players_per_tournament evolution_trial.players_per_tournament%TYPE
) IS

	v_chromosome    strategy.strategy_chromosome%TYPE;
	v_strategy_proc strategy.strategy_procedure%TYPE;
	
BEGIN

	FOR v_i IN 1 .. p_generation_size LOOP
		-- generate random chromosome
		v_chromosome := pkg_ga_util.get_random_bit_string(p_length => pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length);
		v_strategy_proc := pkg_ga_player.get_strategy_procedure(p_strategy_chromosome => v_chromosome);
	
		INSERT INTO strategy (
			strategy_id,
			generation,
			strategy_chromosome,
			strategy_procedure
		) VALUES (
			pai_seq_stratid.NEXTVAL,
			1,
			v_chromosome,
			v_strategy_proc
		);
		
	END LOOP;

	pkg_ga_evolver.enqueue_tournaments(
		p_trial_id               => p_trial_id,
		p_generation             => 1,
		p_generation_size        => p_generation_size,
		p_tournament_play_count  => p_tournament_play_count,
		p_players_per_tournament => p_players_per_tournament
	);

END create_initial_generation;

PROCEDURE enqueue_tournaments(
	p_trial_id               evolution_trial.trial_id%TYPE,
	p_generation             evolution_trial.current_generation%TYPE,
	p_generation_size        evolution_trial.generation_size%TYPE,
	p_tournament_play_count  evolution_trial.tournament_play_count%TYPE,
	p_players_per_tournament evolution_trial.players_per_tournament%TYPE
) IS

	v_tournament_id      poker_state_log.tournament_id%TYPE;
	v_strategy_id_array  t_strategy_id_varray;
	v_payload            t_row_evolution_trial_queue;
	v_enqueue_options    DBMS_AQ.ENQUEUE_OPTIONS_T;
	v_message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
	v_message_handle     RAW(16);

BEGIN

	DELETE FROM evolution_trial_work;
	INSERT INTO evolution_trial_work (
		trial_id,
		strategy_id,
		tournament_sequence,
		assigned,
		played
	)
	WITH tournament_sequence AS (
		SELECT ROWNUM tournament_sequence
		FROM   DUAL
		CONNECT BY ROWNUM <= p_tournament_play_count
	)
	SELECT p_trial_id trial_id,
		   s.strategy_id,
		   ts.tournament_sequence,
		   'N' assigned,
		   'N' played
	FROM   tournament_sequence ts,
		   strategy s
	WHERE  s.generation = p_generation;

	FOR v_tournament_sequence IN 1 .. p_tournament_play_count LOOP
	
		FOR v_tournament_group IN 1 .. (p_generation_size / p_players_per_tournament) LOOP
		
			v_tournament_id := pai_seq_tid.NEXTVAL;
			
			WITH available_strategies AS (
				SELECT strategy_id
				FROM   evolution_trial_work
				WHERE  trial_id = p_trial_id
				   AND tournament_sequence = v_tournament_sequence
				   AND assigned = 'N'
				ORDER BY DBMS_RANDOM.VALUE
			)		
			
			SELECT strategy_id
			BULK COLLECT INTO v_strategy_id_array
			FROM available_strategies
			WHERE ROWNUM <= p_players_per_tournament;
			
			UPDATE evolution_trial_work
			SET    tournament_id = v_tournament_id,
				   assigned = 'Y'
			WHERE  trial_id = p_trial_id
			   AND tournament_sequence = v_tournament_sequence
			   AND strategy_id IN (
					SELECT column_value strategy_id
					FROM   TABLE(v_strategy_id_array)
				);

			v_payload := t_row_evolution_trial_queue(
				trial_id      => p_trial_id,
				tournament_id => v_tournament_id,
				player_count  => p_players_per_tournament,
				strategy_ids  => v_strategy_id_array
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

END enqueue_tournaments;

FUNCTION step_generation (
	p_trial_id evolution_trial.trial_id%TYPE
) RETURN evolution_trial.current_generation%TYPE IS

	v_evolution_trial_rec        evolution_trial%ROWTYPE;
	v_current_gen_work_remaining VARCHAR2(1);
	v_new_generation             evolution_trial.current_generation%TYPE;
	
BEGIN

	pkg_poker_ai.log(p_message => 'begin step generation request for p_trial_id = ' || p_trial_id);

	SELECT *
	INTO   v_evolution_trial_rec
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;

	IF v_evolution_trial_rec.current_generation >= v_evolution_trial_rec.max_generations THEN
		-- all generations complete, no work to perform
		pkg_poker_ai.log(p_message => 'end step generation request for p_trial_id = ' || p_trial_id || ', no work to perform');
		RETURN -1;
	ELSE
	
		-- check if there is any remaining work to do by the tournament runner workers
		
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END current_gen_work_remaining
		INTO   v_current_gen_work_remaining
		FROM   evolution_trial_work
		WHERE  trial_id = p_trial_id
		   AND played = 'N';
		
		IF v_current_gen_work_remaining = 'Y' THEN
			-- tournament runner work remains for current generation
			pkg_poker_ai.log(p_message => 'end step generation request for p_trial_id = ' || p_trial_id || ', tournament runner work remains');
			RETURN 0;
		ELSE
		
			-- all tournament runs are complete, create new generation
			
			v_new_generation := pkg_ga_player.create_new_generation(
				p_evolution_trial_id  => p_trial_id,
				p_from_generation     => v_evolution_trial_rec.current_generation,
				p_new_generation_size => v_evolution_trial_rec.generation_size,
				p_crossover_rate      => v_evolution_trial_rec.crossover_rate,
				p_crossover_point     => v_evolution_trial_rec.crossover_point,
				p_mutation_rate       => v_evolution_trial_rec.mutation_rate
			);

			UPDATE evolution_trial
			SET    current_generation = v_new_generation
			WHERE  trial_id = p_trial_id;
			
			pkg_ga_evolver.enqueue_tournaments(
				p_trial_id               => p_trial_id,
				p_generation             => v_new_generation,
				p_generation_size        => v_evolution_trial_rec.generation_size,
				p_tournament_play_count  => v_evolution_trial_rec.tournament_play_count,
				p_players_per_tournament => v_evolution_trial_rec.players_per_tournament
			);

			COMMIT;
			
			-- generation work complete, new generation created
			pkg_poker_ai.log(p_message => 'end step generation request for p_trial_id = ' || p_trial_id || ', generation ' || v_new_generation || ' created');
			RETURN v_new_generation;
			
		END IF;
		
	END IF;
	
END step_generation;

FUNCTION step_tournament_work (
	p_trial_id  evolution_trial.trial_id%TYPE,
	p_worker_id VARCHAR2
) RETURN INTEGER IS

	v_evolution_trial_complete  VARCHAR2(1);
	v_evolution_trial           evolution_trial%ROWTYPE;
	v_strategy_record           t_row_number := t_row_number(NULL);
	v_strategy_ids              t_tbl_number := t_tbl_number();
	v_dequeue_options           DBMS_AQ.DEQUEUE_OPTIONS_T;
	v_message_properties        DBMS_AQ.MESSAGE_PROPERTIES_T;
	v_payload                   t_row_evolution_trial_queue;
	v_message_handle            RAW(16);
	v_player_count_sanity_check evolution_trial.players_per_tournament%TYPE;
	v_players_per_tournament    evolution_trial.players_per_tournament%TYPE;
	v_work_to_perform           BOOLEAN := TRUE;
	
BEGIN
	
	pkg_poker_ai.log(p_message => 'begin step tournament request for p_trial_id = ' || p_trial_id || ', p_worker_id = ' || p_worker_id);

	-- return stop flag if evolution trial is complete
	WITH final_generation AS (
		SELECT CASE WHEN current_generation = max_generations THEN 'Y' ELSE 'N' END on_last_generation
		FROM   evolution_trial
		WHERE  trial_id = p_trial_id
	),
	tournament_work_remaining AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END tournament_work_remains
		FROM   evolution_trial_work
		WHERE  trial_id = p_trial_id
		   AND played = 'N'
	)
	SELECT CASE WHEN fg.on_last_generation = 'Y' AND twr.tournament_work_remains = 'N' THEN 'Y' ELSE 'N' END evolution_trial_complete
	INTO   v_evolution_trial_complete
	FROM   final_generation fg,
		   tournament_work_remaining twr;

	IF v_evolution_trial_complete = 'Y' THEN
		-- all generations complete, no work to perform
		pkg_poker_ai.log(p_message => 'end step tournament request for p_trial_id = ' || p_trial_id || ', trial complete, no work to perform');
		RETURN -1;
	END IF;
		   
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
	
		-- gather evolution trial attributes
		SELECT *
		INTO   v_evolution_trial
		FROM   evolution_trial
		WHERE  trial_id = p_trial_id;

		-- setup strategy IDs for tournament
		v_strategy_ids.DELETE;
		FOR v_i IN 1 .. v_payload.player_count LOOP
			v_strategy_record.value := v_payload.strategy_ids(v_i);
			v_strategy_ids.EXTEND;
			v_strategy_ids(v_i) := v_strategy_record;
		END LOOP;

		-- debug - player count sanity check
		SELECT players_per_tournament
		INTO   v_players_per_tournament
		FROM   evolution_trial
		WHERE  trial_id = p_trial_id;
		SELECT COUNT(*) player_count_sanity_check
		INTO   v_player_count_sanity_check
		FROM   TABLE(v_strategy_ids);
		IF v_player_count_sanity_check != v_players_per_tournament THEN
			RAISE_APPLICATION_ERROR(-20000, 'tournament player count sanity check failed, '
				|| v_player_count_sanity_check || ' players selected for tournament of '
				|| v_players_per_tournament || ' players');
		END IF;
		
		-- play tournament
		pkg_poker_ai.log(p_message => 'step tournament playing tournament for p_trial_id = ' || p_trial_id || ', p_worker_id = ' || p_worker_id);
		pkg_poker_ai.play_tournament(
			p_evolution_trial_id        => p_trial_id,
			p_tournament_id             => v_payload.tournament_id,
			p_strategy_ids              => v_strategy_ids,
			p_buy_in_amount             => v_evolution_trial.tournament_buy_in,
			p_initial_small_blind_value => v_evolution_trial.initial_small_blind_value,
			p_double_blinds_interval    => v_evolution_trial.double_blinds_interval,
			p_perform_state_logging     => 'N'
		);
		
		-- update work table to indicate work complete
		UPDATE evolution_trial_work
		SET    played = 'Y'
		WHERE  trial_id = p_trial_id
		   AND tournament_id = v_payload.tournament_id;
		COMMIT;

		-- tournament execution complete
		pkg_poker_ai.log(p_message => 'step tournament playing tournament complete for p_trial_id = ' || p_trial_id || ', p_worker_id = ' || p_worker_id);
		RETURN 0;
		
	ELSE
		-- empty queue
		pkg_poker_ai.log(p_message => 'step tournament for p_trial_id = ' || p_trial_id || ', p_worker_id = ' || p_worker_id || ', queue is empty');
		RETURN 1;
	END IF;
	
END step_tournament_work;

END pkg_ga_evolver;
