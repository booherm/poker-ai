CREATE OR REPLACE PACKAGE BODY pkg_ga_player AS

PROCEDURE perform_automatic_player_move (
	p_seat_number player_state.seat_number%TYPE
) IS

	v_can_fold           VARCHAR2(1) := pkg_poker_ai.get_can_fold(p_seat_number => p_seat_number);
	v_can_check          VARCHAR2(1) := pkg_poker_ai.get_can_check(p_seat_number => p_seat_number);
	v_can_call           VARCHAR2(1) := pkg_poker_ai.get_can_call(p_seat_number => p_seat_number);
	v_can_bet            VARCHAR2(1) := pkg_poker_ai.get_can_bet(p_seat_number => p_seat_number);
	v_can_raise          VARCHAR2(1) := pkg_poker_ai.get_can_raise(p_seat_number => p_seat_number);
	v_min_bet_amount     player_state.money%TYPE;
	v_max_bet_amount     player_state.money%TYPE;
	v_min_raise_amount   player_state.money%TYPE;
	v_max_raise_amount   player_state.money%TYPE;
	
	v_player_move        VARCHAR2(30);
	v_player_move_amount player_state.money%TYPE;
	
BEGIN

	WITH possible_moves AS (
		SELECT 'FOLD'  player_move FROM DUAL WHERE v_can_fold = 'Y'  UNION ALL
		SELECT 'CHECK' player_move FROM DUAL WHERE v_can_check = 'Y' UNION ALL
		SELECT 'CALL'  player_move FROM DUAL WHERE v_can_call = 'Y'  UNION ALL
		SELECT 'BET'   player_move FROM DUAL WHERE v_can_bet = 'Y'   UNION ALL
		SELECT 'RAISE' player_move FROM DUAL WHERE v_can_raise = 'Y'
	)
	
	SELECT MIN(player_move) KEEP (DENSE_RANK FIRST ORDER BY DBMS_RANDOM.RANDOM) player_move
	INTO   v_player_move
	FROM   possible_moves;
	
	IF v_player_move = 'BET' THEN
		v_min_bet_amount := pkg_poker_ai.get_min_bet_amount(p_seat_number => p_seat_number);
		v_max_bet_amount := pkg_poker_ai.get_max_bet_amount(p_seat_number => p_seat_number);
	   
		v_player_move_amount := pkg_ga_player.get_random_int(
			p_lower_limit => v_min_bet_amount,
			p_upper_limit => v_max_bet_amount
		);
	   
	ELSIF v_player_move = 'RAISE' THEN
		v_min_raise_amount := pkg_poker_ai.get_min_raise_amount(p_seat_number => p_seat_number);
		v_max_raise_amount := pkg_poker_ai.get_max_raise_amount(p_seat_number => p_seat_number);

		v_player_move_amount := pkg_ga_player.get_random_int(
			p_lower_limit => v_min_raise_amount,
			p_upper_limit => v_max_raise_amount
		);

	END IF;
	
	pkg_poker_ai.perform_explicit_player_move(
		p_seat_number        => p_seat_number,
		p_player_move        => v_player_move,
		p_player_move_amount => v_player_move_amount
	);
	
END perform_automatic_player_move;

FUNCTION get_random_int (
	p_lower_limit INTEGER,
	p_upper_limit INTEGER
) RETURN INTEGER IS
BEGIN

	RETURN ROUND(DBMS_RANDOM.VALUE(p_lower_limit - 0.5, p_upper_limit + 0.5));

END get_random_int;

END pkg_ga_player;
