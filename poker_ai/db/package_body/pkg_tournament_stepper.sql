CREATE OR REPLACE PACKAGE BODY pkg_tournament_stepper AS

FUNCTION initialize_tournament(
	p_tournament_mode poker_state_log.tournament_mode%TYPE,
	p_player_count    poker_state_log.player_count%TYPE,
	p_buy_in_amount   poker_state_log.buy_in_amount%TYPE
) RETURN poker_state_log.state_id%TYPE IS

	v_poker_state t_poker_state;

BEGIN

	v_poker_state := pkg_poker_ai.initialize_tournament(
		p_tournament_id         => NULL,
		p_tournament_mode       => p_tournament_mode,
		p_evolution_trial_id    => NULL,
		p_strategy_ids          => NULL,
		p_player_count          => p_player_count,
		p_buy_in_amount         => p_buy_in_amount,
		p_perform_state_logging => 'Y'
	);

	COMMIT;
	
	RETURN v_poker_state.current_state_id;

END initialize_tournament;

FUNCTION step_play(
	p_state_id           poker_state_log.state_id%TYPE,
	p_small_blind_value  poker_state_log.small_blind_value%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
) RETURN poker_state_log.state_id%TYPE IS

	v_poker_state t_poker_state;
	
BEGIN

	v_poker_state := pkg_poker_ai.get_poker_state(p_state_id => p_state_id);
	v_poker_state.small_blind_value := p_small_blind_value;
	pkg_poker_ai.step_play(
		p_poker_state           => v_poker_state,
		p_player_move           => p_player_move,
		p_player_move_amount    => p_player_move_amount,
		p_perform_state_logging => 'Y'
	);

	COMMIT;
	
	RETURN v_poker_state.current_state_id;

END step_play;

FUNCTION edit_card(
	p_state_id    poker_state_log.state_id%TYPE,
	p_card_type   VARCHAR2,
	p_seat_number player_state_log.seat_number%TYPE,
	p_card_slot   NUMBER,
	p_card_id     poker_state_log.community_card_1%TYPE
) RETURN poker_state_log.state_id%TYPE IS

	v_poker_state     t_poker_state;
	v_current_card_id poker_state_log.community_card_1%TYPE;
	
BEGIN

	v_poker_state := pkg_poker_ai.get_poker_state(p_state_id => p_state_id);
	
	IF p_card_type = 'HOLE_CARD' THEN
	
		IF p_card_slot = 1 THEN
			v_current_card_id := v_poker_state.player_state(p_seat_number).hole_card_1;
			v_poker_state.player_state(p_seat_number).hole_card_1 := p_card_id;
		ELSE
			v_current_card_id := v_poker_state.player_state(p_seat_number).hole_card_2;
			v_poker_state.player_state(p_seat_number).hole_card_2 := p_card_id;
		END IF;

	ELSE
	
		IF p_card_slot = 1 THEN
			v_current_card_id := v_poker_state.community_card_1;
			v_poker_state.community_card_1 := p_card_id;
		ELSIF p_card_slot = 2 THEN
			v_current_card_id := v_poker_state.community_card_2;
			v_poker_state.community_card_2 := p_card_id;
		ELSIF p_card_slot = 3 THEN
			v_current_card_id := v_poker_state.community_card_3;
			v_poker_state.community_card_3 := p_card_id;
		ELSIF p_card_slot = 4 THEN
			v_current_card_id := v_poker_state.community_card_4;
			v_poker_state.community_card_4 := p_card_id;
		ELSIF p_card_slot = 5 THEN
			v_current_card_id := v_poker_state.community_card_5;
			v_poker_state.community_card_5 := p_card_id;
		END IF;
		
	END IF;
	
	IF v_current_card_id IS NOT NULL AND v_current_card_id != 0 THEN
		v_poker_state.deck(v_current_card_id).dealt := 'N';
	END IF;
	
	v_poker_state.deck(p_card_id).dealt := 'Y';
	
	pkg_poker_ai.calculate_best_hands(p_poker_state => v_poker_state);
	pkg_poker_ai.sort_hands(p_poker_state => v_poker_state);
	
	pkg_poker_ai.capture_state_log(p_poker_state => v_poker_state);
	
	COMMIT;
	
	RETURN v_poker_state.current_state_id;
		
END edit_card;

PROCEDURE select_ui_state(
	p_state_id         poker_state_log.state_id%TYPE,
	p_tournament_state OUT t_rc_generic,
	p_game_state       OUT t_rc_generic,
	p_player_state     OUT t_rc_generic,
	p_pots             OUT t_rc_generic,
	p_status           OUT t_rc_generic
) IS

	v_poker_state t_poker_state;
	
BEGIN

	v_poker_state := pkg_poker_ai.get_poker_state(p_state_id => p_state_id);

	OPEN p_tournament_state FOR
		SELECT v_poker_state.player_count player_count,
			   v_poker_state.buy_in_amount buy_in_amount,
			   v_poker_state.current_game_number current_game_number,
			   CASE v_poker_state.game_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END game_in_progress,
			   v_poker_state.current_state_id current_state_id
		FROM   DUAL;

	OPEN p_game_state FOR
		SELECT v_poker_state.small_blind_seat_number small_blind_seat_number,
			   v_poker_state.big_blind_seat_number big_blind_seat_number,
			   v_poker_state.turn_seat_number turn_seat_number,
			   v_poker_state.small_blind_value small_blind_value,
			   v_poker_state.big_blind_value big_blind_value,
			   display_value betting_round_number,
			   CASE v_poker_state.betting_round_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END betting_round_in_progress,
			   v_poker_state.last_to_raise_seat_number last_to_raise_seat_number,
			   v_poker_state.community_card_1 community_card_1,
			   v_poker_state.community_card_2 community_card_2,
			   v_poker_state.community_card_3 community_card_3,
			   v_poker_state.community_card_4 community_card_4,
			   v_poker_state.community_card_5 community_card_5
		FROM   master_field_value
		WHERE  field_name_code = 'BETTING_ROUND_NUMBER'
		   AND NVL(v_poker_state.betting_round_number, 0) = field_value_code;

	OPEN p_player_state FOR
		WITH player_state AS (
			SELECT /* MATERIALIZE */ *
			FROM   TABLE(v_poker_state.player_state)
		),
		
		pot AS (
			SELECT /* MATERIALIZE */ *
			FROM   TABLE(v_poker_state.pot)
		),
		
		pot_contribution AS (
			SELECT /* MATERIALIZE */ *
			FROM   TABLE(v_poker_state.pot_contribution)
		),
		
		seats AS (
			SELECT ROWNUM seat_number
			FROM   DUAL
			CONNECT BY ROWNUM <= pkg_poker_ai.v_max_player_count
		),

		pot_contributions AS (
			SELECT player_seat_number,
				   SUM(pot_contribution) total_pot_contribution
			FROM   pot_contribution
			GROUP BY player_seat_number
		),

		active_player_count AS (
			SELECT COUNT(*) active_player_count
			FROM   player_state
			WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		),

		hand_ranks AS (
			SELECT ps.seat_number,
				   (apc.active_player_count - (RANK() OVER (ORDER BY ps.best_hand_rank)) + 1) best_hand_rank,
				   mfv.display_value best_hand_rank_type
			FROM   player_state ps,
				   active_player_count apc,
				   master_field_value mfv
			WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
			   AND ps.best_hand_rank IS NOT NULL
			   AND mfv.field_name_code = 'HAND_RANK'
			   AND SUBSTR(ps.best_hand_rank, 1, 2) = mfv.field_value_code
		)
		
		SELECT s.seat_number,
			   ps.player_id,
			   ps.hole_card_1,
			   ps.hole_card_2,
			   ps.best_hand_combination,
			   NULLIF(hr.best_hand_rank || ' - ' || hr.best_hand_rank_type, ' - ') best_hand_rank,
			   ps.best_hand_card_1,
			   ps.best_hand_card_2,
			   ps.best_hand_card_3,
			   ps.best_hand_card_4,
			   ps.best_hand_card_5,
			   CASE WHEN ps.best_hand_card_1 IN (ps.hole_card_1, ps.hole_card_2) THEN 'Y' ELSE 'N' END best_hand_card_1_is_hole_card,
			   CASE WHEN ps.best_hand_card_2 IN (ps.hole_card_1, ps.hole_card_2) THEN 'Y' ELSE 'N' END best_hand_card_2_is_hole_card,
			   CASE WHEN ps.best_hand_card_3 IN (ps.hole_card_1, ps.hole_card_2) THEN 'Y' ELSE 'N' END best_hand_card_3_is_hole_card,
			   CASE WHEN ps.best_hand_card_4 IN (ps.hole_card_1, ps.hole_card_2) THEN 'Y' ELSE 'N' END best_hand_card_4_is_hole_card,
			   CASE WHEN ps.best_hand_card_5 IN (ps.hole_card_1, ps.hole_card_2) THEN 'Y' ELSE 'N' END best_hand_card_5_is_hole_card,
			   CASE ps.hand_showing WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END hand_showing,
			   ps.money,
			   NVL(mfv.display_value, 'No Player') state,
			   ps.game_rank,
			   ps.tournament_rank,
			   pc.total_pot_contribution,
			   pkg_poker_ai.get_can_fold(p_poker_state => v_poker_state, p_seat_number => s.seat_number) can_fold,
			   pkg_poker_ai.get_can_check(p_poker_state => v_poker_state, p_seat_number => s.seat_number) can_check,
			   pkg_poker_ai.get_can_call(p_poker_state => v_poker_state, p_seat_number => s.seat_number) can_call,
			   pkg_poker_ai.get_can_bet(p_poker_state => v_poker_state, p_seat_number => s.seat_number) can_bet,
			   pkg_poker_ai.get_min_bet_amount(p_poker_state => v_poker_state, p_seat_number => s.seat_number) min_bet_amount,
			   pkg_poker_ai.get_max_bet_amount(p_poker_state => v_poker_state, p_seat_number => s.seat_number) max_bet_amount,
			   pkg_poker_ai.get_can_raise(p_poker_state => v_poker_state, p_seat_number => s.seat_number) can_raise,
			   pkg_poker_ai.get_min_raise_amount(p_poker_state => v_poker_state, p_seat_number => s.seat_number) min_raise_amount,
			   pkg_poker_ai.get_max_raise_amount(p_poker_state => v_poker_state, p_seat_number => s.seat_number) max_raise_amount
		FROM   seats s,
			   player_state ps,
			   pot_contributions pc,
			   hand_ranks hr,
			   master_field_value mfv
		WHERE  s.seat_number = ps.seat_number (+)
		   AND s.seat_number = pc.player_seat_number (+)
		   AND s.seat_number = hr.seat_number (+)
		   AND mfv.field_name_code (+) = 'PLAYER_STATE'
		   AND ps.state = mfv.field_value_code (+)
		ORDER BY seat_number;

	OPEN p_pots FOR
		WITH pot_contributions AS (
			SELECT pot_number,
				   player_seat_number,
				   SUM(pot_contribution) pot_value,
				   SUM(CASE WHEN betting_round_number = 1 THEN pot_contribution END) betting_round_1_bet_value,
				   SUM(CASE WHEN betting_round_number = 2 THEN pot_contribution END) betting_round_2_bet_value,
				   SUM(CASE WHEN betting_round_number = 3 THEN pot_contribution END) betting_round_3_bet_value,
				   SUM(CASE WHEN betting_round_number = 4 THEN pot_contribution END) betting_round_4_bet_value
			FROM   TABLE(v_poker_state.pot_contribution)
			GROUP BY
				pot_number,
				player_seat_number
		)

		SELECT pot_number,
			   SUM(pot_value) pot_value,
			   SUM(betting_round_1_bet_value) betting_round_1_bet_value,
			   SUM(betting_round_2_bet_value) betting_round_2_bet_value,
			   SUM(betting_round_3_bet_value) betting_round_3_bet_value,
			   SUM(betting_round_4_bet_value) betting_round_4_bet_value,
			   LISTAGG(player_seat_number, ' ') WITHIN GROUP (ORDER BY player_seat_number) pot_members
		FROM   pot_contributions
		GROUP BY pot_number
		ORDER BY pot_number;

	OPEN p_status FOR
		SELECT log_record_number,
			   message
		FROM   poker_ai_log
		WHERE  state_id = v_poker_state.current_state_id
		ORDER BY log_record_number;

	EXCEPTION WHEN OTHERS THEN
		IF p_tournament_state%ISOPEN THEN
			CLOSE p_tournament_state;
		END IF;
		IF p_game_state%ISOPEN THEN
			CLOSE p_game_state;
		END IF;
		IF p_player_state%ISOPEN THEN
			CLOSE p_player_state;
		END IF;
		IF p_pots%ISOPEN THEN
			CLOSE p_pots;
		END IF;
		IF p_status%ISOPEN THEN
			CLOSE p_status;
		END IF;
		RAISE;

END select_ui_state;

FUNCTION get_previous_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE IS

	v_previous_state_id poker_ai_log.state_id%TYPE;
	
BEGIN

	SELECT MAX(state_id) previous_state_id
	INTO   v_previous_state_id
	FROM   poker_state_log
	WHERE  state_id < p_state_id;
	
	RETURN v_previous_state_id;
	
END get_previous_state_id;

FUNCTION get_next_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE IS

	v_next_state_id poker_state_log.state_id%TYPE;
	
BEGIN

	SELECT MIN(state_id) next_state_id
	INTO   v_next_state_id
	FROM   poker_state_log
	WHERE  state_id > p_state_id;
	
	RETURN v_next_state_id;
	
END get_next_state_id;

END pkg_tournament_stepper;
