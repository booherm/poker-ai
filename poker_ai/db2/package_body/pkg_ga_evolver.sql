CREATE OR REPLACE PACKAGE BODY pkg_ga_evolver AS

PROCEDURE insert_evolution_trial(
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
	p_double_blinds_interval    evolution_trial.double_blinds_interval%TYPE,
	p_current_generation        evolution_trial.current_generation%TYPE
) IS
BEGIN

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
		p_crossover_point,
		p_mutation_rate,
		p_players_per_tournament,
		p_tournament_play_count,
		p_tournament_buy_in,
		p_initial_small_blind_value,
		p_double_blinds_interval,
		p_current_generation
	);
	COMMIT;
	
END insert_evolution_trial;

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

	v_evolution_trial    evolution_trial%ROWTYPE;
	v_tournament_id      poker_state_log.tournament_id%TYPE;
	v_strategy_id_array  t_strategy_id_varray;
	v_payload            t_row_evolution_trial_queue;
	v_enqueue_options    DBMS_AQ.ENQUEUE_OPTIONS_T;
	v_message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
	v_message_handle     RAW(16);

BEGIN

	-- get trial attributes
	SELECT *
	INTO   v_evolution_trial
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;
	
	-- enqueue tournaments for current generation
	DELETE FROM evolution_trial_work
	WHERE trial_id = p_trial_id;
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
		CONNECT BY ROWNUM <= v_evolution_trial.tournament_play_count
	)
	SELECT p_trial_id trial_id,
		   s.strategy_id,
		   ts.tournament_sequence,
		   'N' assigned,
		   'N' played
	FROM   tournament_sequence ts,
		   strategy s
	WHERE  s.generation = v_evolution_trial.current_generation;

	-- enqueue tournament work
	FOR v_tournament_sequence IN 1 .. v_evolution_trial.tournament_play_count LOOP
	
		FOR v_tournament_group IN 1 .. (v_evolution_trial.generation_size / v_evolution_trial.players_per_tournament) LOOP
		
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
			WHERE ROWNUM <= v_evolution_trial.players_per_tournament;
			
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
				player_count  => v_evolution_trial.players_per_tournament,
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
	v_work_remains              VARCHAR2(1);
	v_work_to_perform           BOOLEAN := TRUE;
	
BEGIN

	-- check if trial is complete
	SELECT CASE WHEN current_generation >= max_generations THEN 'N' ELSE 'Y' END work_remains
	INTO   v_work_remains
	FROM   evolution_trial
	WHERE  trial_id = p_trial_id;
	IF v_work_remains = 'N' THEN
		-- all generations complete, no work to perform
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
		-- empty queue, no work to perform
		RETURN 1;
		-- debug - need to open?
		--OPEN p_tournament_work FOR SELECT dummy FROM DUAL WHERE 1 = 2;
		--OPEN p_tournament_work_strategies FOR SELECT dummy FROM DUAL WHERE 1 = 2;

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

END pkg_ga_evolver;
