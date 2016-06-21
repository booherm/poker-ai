DECLARE

	v_generation_size           INTEGER := 100;
	v_max_generations           strategy.generation%TYPE := 1000;
	v_crossover_rate            NUMBER := 0.85;
	
	v_tournament_groups         INTEGER := 10;
	v_tournament_play_count     INTEGER := 10;
	v_tournament_buy_in         tournament_state.buy_in_amount%TYPE := 500;
	v_initial_small_blind_value game_state.small_blind_value%TYPE := 5;
	v_double_blinds_interval    tournament_state.current_game_number%TYPE := 5;
	
	v_tournament_player_count   tournament_state.player_count%TYPE := v_generation_size / v_tournament_groups;
	v_crossover_point           INTEGER := FLOOR(pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length / 2);
	v_mutation_rate             NUMBER := 1 / pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length;
	v_chromosome                strategy.strategy_chromosome%TYPE;
	v_strategy_proc             strategy.strategy_procedure%TYPE;
	v_strategy_record           t_row_number := t_row_number(NULL);
	v_strategy_ids              t_tbl_number := t_tbl_number();

	CURSOR v_tournament_group_set(
		p_generation              strategy.generation%TYPE,
		p_tournament_group_number INTEGER
	) IS
		WITH strategy_ids AS (
			SELECT strategy_id
			FROM   strategy
			WHERE  generation = p_generation
			ORDER BY strategy_id
		),
		
		strategy_sequence AS (
			SELECT (FLOOR((ROWNUM - 1) / v_tournament_player_count) + 1) tournament_group,
				   strategy_id
			FROM   strategy_ids
		)
		
		SELECT ROWNUM seat_number,
			   strategy_id
		FROM   strategy_sequence
		WHERE  tournament_group = p_tournament_group_number
		ORDER BY strategy_id;
		
BEGIN

	-- create initial generation of random strategies
	pkg_poker_ai.log(p_message => 'evolver: begin creation of initial generation of random strategies');
	DELETE FROM strategy_fitness;
	DELETE FROM strategy;
	FOR v_i IN 1 .. v_generation_size LOOP
		-- generate random chromosome
		SELECT pkg_ga_util.get_random_bit_string(p_length => pkg_ga_player.v_strat_chromosome_metadata.chromosome_bit_length) strategy_chromosome
		INTO   v_chromosome
		FROM   DUAL;
		
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
	COMMIT;
	pkg_poker_ai.log(p_message => 'evolver: end creation of initial generation of random strategies');

	-- evolve to maximum generation
	pkg_poker_ai.log(p_message => 'evolver: begin generation evolution');
	FOR v_current_generation IN 1 .. v_max_generations LOOP
	
		pkg_poker_ai.log(p_message => 'evolver: begin fitness test for generation ' || v_current_generation);
		
		-- Evaluate fitness of current generation by playing them in tournaments against each other.  Break up the current generation
		-- into groups of reasonable size for tournament play.
		FOR v_tournament_group IN 1 .. v_tournament_groups LOOP
		
			-- setup tournament group
			v_strategy_ids.DELETE;
			FOR v_strategy_rec IN v_tournament_group_set(
				p_generation              => v_current_generation,
				p_tournament_group_number => v_tournament_group
			) LOOP
				v_strategy_record.value := v_strategy_rec.strategy_id;
				v_strategy_ids.EXTEND;
				v_strategy_ids(v_strategy_rec.seat_number) := v_strategy_record;
			END LOOP;
			
			-- play tournaments
			FOR v_tournament_rec IN (
				SELECT ROWNUM tournament_number
				FROM   DUAL
				CONNECT BY ROWNUM <= v_tournament_play_count
				ORDER BY tournament_number
			) LOOP
			
				pkg_poker_ai.log(p_message => 'evolver: begin play of generation ' || v_current_generation
					|| ' tournament group ' || v_tournament_group
					|| ' tournament number ' || v_tournament_rec.tournament_number
				);

				-- play tournament
				pkg_poker_ai.play_tournament(
					p_strategy_ids              => v_strategy_ids,
					p_buy_in_amount             => v_tournament_buy_in,
					p_initial_small_blind_value => v_initial_small_blind_value,
					p_double_blinds_interval    => v_double_blinds_interval,
					p_perform_state_logging     => 'N'
				);
				
				pkg_poker_ai.log(p_message => 'evolver: end play of generation ' || v_current_generation
					|| ' tournament group ' || v_tournament_group
					|| ' tournament number ' || v_tournament_rec.tournament_number
				);

			END LOOP;
		
		END LOOP;
		pkg_poker_ai.log(p_message => 'evolver: end fitness test for generation ' || v_current_generation);

		-- all tournaments have been played for current generation, generate next generation
		IF v_current_generation != v_max_generations THEN
			pkg_poker_ai.log(p_message => 'evolver: begin next generation creation');
			pkg_ga_player.create_new_generation(
				p_from_generation     => v_current_generation,
				p_fitness_test_id     => v_tournament_player_count || '_PLAYER_' || v_tournament_buy_in || '_BUYIN',
				p_new_generation_size => v_generation_size,
				p_crossover_rate      => v_crossover_rate,
				p_crossover_point     => v_crossover_point,
				p_mutation_rate       => v_mutation_rate
			);
			COMMIT;
			pkg_poker_ai.log(p_message => 'evolver: end next generation creation');
		END IF;

	END LOOP;
	pkg_poker_ai.log(p_message => 'evolver: end generation evolution');
	
END;

-- monitor progress
SELECT log_record_number,
	   TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
	   message
FROM   poker_ai_log
WHERE  message LIKE 'evolver:%'
ORDER BY log_record_number DESC;


-- average generation creation and test time
SELECT log_record_number,
       TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
       message
FROM   poker_ai_log
WHERE  message LIKE 'evolver: %begin%creation%'
ORDER BY log_record_number DESC;
-- ~48 min

-- average tournament play time
SELECT AVG(tournament_time_sec) FROM 
(
    SELECT log_record_number,
           TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
           ((mod_date - LAG(mod_date) OVER (ORDER BY log_record_number)) * 24 * 60 * 60) tournament_time_sec, 
           message
    FROM   poker_ai_log
    WHERE  message LIKE 'evolver:%begin play%'
       AND message NOT LIKE '%tournament group 1 tournament number 1%'
    ORDER BY log_record_number DESC
);
-- ~32 seconds


-- analyze evolution
SELECT s.generation,
	   MIN(s.strategy_id) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_strategy_id,
	   MIN(sf.fitness_score) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_fitness_score,
	   MIN(sf.average_game_profit) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_avgerage_game_profit,
	   ROUND(AVG(sf.fitness_score), 2) average_fitness_score,
	   ROUND(AVG(sf.average_game_profit), 2) average_average_game_profit
FROM   strategy s,
	   strategy_fitness sf
WHERE  s.strategy_id = sf.strategy_id
GROUP BY s.generation
ORDER BY generation;


