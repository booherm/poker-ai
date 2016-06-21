TRUNCATE TABLE poker_ai_log;
ALTER SYSTEM FLUSH SHARED_POOL;
		
DECLARE

	v_tournament_play_count     INTEGER := 1;
	v_player_count              tournament_state.player_count%TYPE := 10;
	v_tournament_buy_in         tournament_state.buy_in_amount%TYPE := 500;
	v_initial_small_blind_value game_state.small_blind_value%TYPE := 5;
	v_double_blinds_interval    tournament_state.current_game_number%TYPE := 5;
	
	v_strategy_record           t_row_number := t_row_number(NULL);
	v_strategy_ids              t_tbl_number := t_tbl_number();
	v_current_game_number       tournament_state.current_game_number%TYPE;
	v_money_imbalance           VARCHAR2(1);
	
BEGIN

	-- setup players
	FOR v_rec IN (
		WITH seats AS (
			SELECT ROWNUM seat_number
			FROM   DUAL
			CONNECT BY ROWNUM <= v_player_count
		),
		
		strategies AS (
			SELECT ROWNUM seat_number,
				   strategy_id
			FROM   strategy
			WHERE  ROWNUM <= v_player_count
		)
		
		SELECT s.seat_number,
			   st.strategy_id
		FROM   seats s,
			   strategies st
		WHERE  s.seat_number = st.seat_number (+)
		ORDER BY s.seat_number
	) LOOP
	
		v_strategy_record.value := v_rec.strategy_id;
		v_strategy_ids.EXTEND;
		v_strategy_ids(v_rec.seat_number) := v_strategy_record;
		
	END LOOP;

	-- play tournaments
	FOR v_tournament_rec IN (
		SELECT ROWNUM tournament_number
		FROM   DUAL
		CONNECT BY ROWNUM <= v_tournament_play_count
		ORDER BY tournament_number
	) LOOP
	
		-- clear state logs
		EXECUTE IMMEDIATE 'TRUNCATE TABLE pot_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE pot_contribution_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE player_state_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE game_state_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE tournament_state_log';

		pkg_poker_ai.log(p_message => 'Begin test play of tournament number ' || v_tournament_rec.tournament_number);

		-- play tournament
		pkg_poker_ai.play_tournament(
			p_strategy_ids              => v_strategy_ids,
			p_buy_in_amount             => v_tournament_buy_in,
			p_initial_small_blind_value => v_initial_small_blind_value,
			p_double_blinds_interval    => v_double_blinds_interval,
			p_perform_state_logging     => 'Y'
		);

		------------ check results of tournament play, abort on anomolies  -----------
		
		-- excessive number of games
		SELECT current_game_number
		INTO   v_current_game_number
		FROM   tournament_state;
		IF v_current_game_number >= 450 THEN
			RAISE_APPLICATION_ERROR(-20000, 'Excessive number of games played in tournament');
		END IF;
		
		-- money imbalance
		WITH player_money AS (
			SELECT state_id,
				   SUM(money) total_player_money
			FROM   player_state_log
			GROUP BY state_id
		),

		pot_money AS (
			SELECT state_id,
				   SUM(pot_contribution) total_pot_money
			FROM   pot_contribution_log
			GROUP BY state_id
		),

		total_money AS (
			SELECT NVL(plm.state_id, pom.state_id) state_id,
				   plm.total_player_money,
				   pom.total_pot_money,
				   NVL(plm.total_player_money, 0) + NVL(pom.total_pot_money, 0) total_money
			FROM   player_money plm
				   FULL OUTER JOIN pot_money pom ON plm.state_id = pom.state_id
		)

		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END money_imbalance
		INTO   v_money_imbalance
		FROM   total_money tm,
			   tournament_state_log tsl
		WHERE  tm.state_id = tsl.state_id
		   AND tsl.game_in_progress = 'Y'
		   AND tm.total_money != v_tournament_buy_in * v_player_count;
		   
		IF v_money_imbalance = 'Y' THEN
			RAISE_APPLICATION_ERROR(-20000, 'Money imbalance detected in tournament');
		END IF;

		pkg_poker_ai.log(p_message => 'Successfully completed test play of tournament number ' || v_tournament_rec.tournament_number);

	END LOOP;
	
	pkg_poker_ai.log(p_message => 'Successfully completed test play of all tournaments without anamoly');
	
	/*
	SELECT log_record_number,
		   TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
		   message
	FROM   poker_ai_log
	WHERE  message LIKE '%test play%'
	ORDER BY log_record_number DESC;
	
	SELECT AVG(play_time) FROM (
		SELECT log_record_number,
			   TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
			   message,
			   (mod_date - LAG(mod_date) OVER (ORDER BY log_record_number)) * 24 * 60 * 60 play_time
		FROM   poker_ai_log
		WHERE  message LIKE 'Begin test play%'
		ORDER BY log_record_number DESC
    )
	*/
	
END;



-- debugging
SELECT * FROM tournament_state;
SELECT * FROM game_state;
SELECT * FROM player_state;

SELECT log_record_number,
	   TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
	   state_id,
	   message
FROM   poker_ai_log
ORDER BY log_record_number DESC;

SELECT * FROM tournament_state_log ORDER BY state_id DESC;
SELECT * FROM game_state_log ORDER BY state_id DESC;
SELECT * FROM player_state_log ORDER BY state_id DESC, seat_number;
SELECT * FROM pot_log ORDER BY state_id DESC, pot_number;
SELECT * FROM pot_contribution_log ORDER BY state_id DESC, pot_number, player_seat_number;

-- tournament results
SELECT * FROM tournament_state;
SELECT seat_number,
	   tournament_rank,
	   money
FROM   player_state
ORDER BY
	tournament_rank,
	seat_number;


-- money balance throughout tournament (ignoring states when game not in progress)
WITH player_money AS (
	SELECT state_id,
		   SUM(money) total_player_money
	FROM   player_state_log
	GROUP BY state_id
),

pot_money AS (
	SELECT state_id,
		   SUM(pot_contribution) total_pot_money
	FROM   pot_contribution_log
	GROUP BY state_id
),

total_money AS (
	SELECT NVL(plm.state_id, pom.state_id) state_id,
		   plm.total_player_money,
		   pom.total_pot_money,
		   NVL(plm.total_player_money, 0) + NVL(pom.total_pot_money, 0) total_money
	FROM   player_money plm
		   FULL OUTER JOIN pot_money pom ON plm.state_id = pom.state_id
)

SELECT tm.state_id,
	   tm.total_player_money,
	   tm.total_pot_money,
	   tm.total_money
FROM   total_money tm,
	   tournament_state_log tsl
WHERE  tm.state_id = tsl.state_id
   AND tsl.game_in_progress = 'Y'
ORDER BY state_id DESC;


--------------------------------------------------------------------------------------------------------------------

-- generate random strategies
DELETE FROM strategy_fitness;
DELETE FROM player_state;
DELETE FROM strategy;
COMMIT;
DECLARE

	v_strategy_count INTEGER := 100;
	v_chromosome     strategy.strategy_chromosome%TYPE;
	v_strategy_proc  strategy.strategy_procedure%TYPE;
	
BEGIN

	FOR v_i IN 1 .. v_strategy_count LOOP
	
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
	
END;

-- execute strategy
DECLARE

	v_strategy_procedure strategy.strategy_procedure%TYPE;
	v_player_move        VARCHAR2(30);
	v_player_move_amount player_state.money%TYPE;
	
BEGIN

	SELECT strategy_procedure
	INTO   v_strategy_procedure
	FROM   strategy
	WHERE  strategy_id = 808;
	
	pkg_ga_player.execute_strategy(
		p_strategy_procedure => v_strategy_procedure,
		p_seat_number        => 1,
		p_can_fold           => 'Y',
		p_can_check          => 'Y',
		p_can_call           => 'N',
		p_can_bet            => 'Y',
		p_can_raise          => 'N',
		p_player_move        => v_player_move,
		p_player_move_amount => v_player_move_amount
	);
	
	DBMS_OUTPUT.PUT_LINE('v_player_move = ' || v_player_move || ', v_player_move_amount = ' || v_player_move_amount);
	
END;

-- create new generation of strategies
DECLARE

	v_from_generation   strategy.generation%TYPE := 1;
	v_chromosome_length INTEGER;
	
BEGIN

	SELECT MAX(LENGTH(strategy_chromosome)) chromosome_length
	INTO   v_chromosome_length
	FROM   strategy
	WHERE  generation = v_from_generation;
	
	pkg_ga_player.create_new_generation(
		p_from_generation     => v_from_generation,
		p_fitness_test_id     => '10_PLAYER_500_BUYIN',
		p_new_generation_size => 10,
		p_crossover_rate      => 0.85,
		p_crossover_point     => FLOOR(v_chromosome_length / 2),
		p_mutation_rate       => 1 / v_chromosome_length
	);
	
	COMMIT;
	
END;


