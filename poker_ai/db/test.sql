DECLARE

	v_tournament_play_count     INTEGER := 1;
	v_player_count              tournament_state.player_count%TYPE := 3;
	v_tournament_buy_in         tournament_state.buy_in_amount%TYPE := 500;
	v_initial_small_blind_value game_state.small_blind_value%TYPE := 5;
	v_double_blinds_interval    tournament_state.current_game_number%TYPE := 5;
	
	v_player_record         t_row_number := t_row_number(NULL);
	v_player_ids            t_tbl_number := t_tbl_number();
	v_current_game_number   tournament_state.current_game_number%TYPE;
	v_money_imbalance       VARCHAR2(1);
	
BEGIN

	-- setup players
	FOR v_rec IN (
		SELECT ROWNUM seat_number,
			   player_id
		FROM   player
		WHERE  player_id <= v_player_count
	) LOOP
	
		v_player_record.value := v_rec.player_id;
		v_player_ids.EXTEND;
		v_player_ids(v_rec.seat_number) := v_player_record;
		
	END LOOP;

	-- play tournaments
	FOR v_tournament_rec IN (
		SELECT ROWNUM tournament_number
		FROM   DUAL
		CONNECT BY ROWNUM <= v_tournament_play_count
		ORDER BY tournament_number
	) LOOP
	
		-- clear state logs
		EXECUTE IMMEDIATE 'TRUNCATE TABLE poker_ai_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE pot_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE pot_contribution_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE player_state_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE game_state_log';
		EXECUTE IMMEDIATE 'TRUNCATE TABLE tournament_state_log';

		pkg_poker_ai.log(p_message => 'Begin test play of tournament number ' || v_tournament_rec.tournament_number);

		-- play tournament
		pkg_poker_ai.play_tournament(
			p_player_ids                => v_player_ids,
			p_buy_in_amount             => v_tournament_buy_in,
			p_initial_small_blind_value => v_initial_small_blind_value,
			p_double_blinds_interval    => v_double_blinds_interval
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


