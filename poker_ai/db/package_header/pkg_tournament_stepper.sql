CREATE OR REPLACE PACKAGE pkg_tournament_stepper AS

TYPE t_rc_generic IS REF CURSOR;

FUNCTION initialize_tournament(
	p_tournament_mode poker_state_log.tournament_mode%TYPE,
	p_player_count    poker_state_log.player_count%TYPE,
	p_buy_in_amount   poker_state_log.buy_in_amount%TYPE
) RETURN poker_state_log.state_id%TYPE;

FUNCTION step_play(
	p_state_id           poker_state_log.state_id%TYPE,
	p_small_blind_value  poker_state_log.small_blind_value%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
) RETURN poker_state_log.state_id%TYPE;

FUNCTION edit_card(
	p_state_id    poker_state_log.state_id%TYPE,
	p_card_type   VARCHAR2,
	p_seat_number player_state_log.seat_number%TYPE,
	p_card_slot   NUMBER,
	p_card_id     poker_state_log.community_card_1%TYPE
) RETURN poker_state_log.state_id%TYPE;

PROCEDURE select_ui_state(
	p_state_id         poker_state_log.state_id%TYPE,
	p_tournament_state OUT t_rc_generic,
	p_game_state       OUT t_rc_generic,
	p_player_state     OUT t_rc_generic,
	p_pots             OUT t_rc_generic,
	p_status           OUT t_rc_generic
);

FUNCTION get_previous_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE;

FUNCTION get_next_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE;

END pkg_tournament_stepper;
