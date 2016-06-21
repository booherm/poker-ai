CREATE OR REPLACE PACKAGE pkg_poker_ai AS

v_state_id poker_ai_log.state_id%TYPE;
v_max_player_count INTEGER := 10;

TYPE t_rc_generic IS REF CURSOR;

PROCEDURE play_tournament(
	p_strategy_ids              t_tbl_number,
	p_buy_in_amount             tournament_state.buy_in_amount%TYPE,
	p_initial_small_blind_value game_state.small_blind_value%TYPE,
	p_double_blinds_interval    tournament_state.current_game_number%TYPE,
	p_perform_state_logging     VARCHAR2
);

PROCEDURE initialize_tournament
(
	p_tournament_mode       tournament_state.tournament_mode%TYPE,
	p_strategy_ids          t_tbl_number,
	p_player_count          tournament_state.player_count%TYPE,
    p_buy_in_amount         tournament_state.buy_in_amount%TYPE,
	p_perform_state_logging VARCHAR2
);

PROCEDURE initialize_deck;

PROCEDURE step_play( 
	p_small_blind_value     game_state.small_blind_value%TYPE,
	p_player_move           VARCHAR2,
	p_player_move_amount    player_state.money%TYPE,
	p_perform_state_logging VARCHAR2
);

PROCEDURE clear_game_state;

PROCEDURE initialize_game
(
	p_small_blind_seat_number game_state.small_blind_seat_number%TYPE,
    p_small_blind_value       game_state.small_blind_value%TYPE
);

FUNCTION get_active_player_count RETURN INTEGER;

FUNCTION get_next_active_seat_number
(
	p_current_player_seat_number player_state.seat_number%TYPE,
	p_include_folded_players     VARCHAR2,
	p_include_all_in_players     VARCHAR2
) RETURN player_state.seat_number%TYPE;

FUNCTION init_betting_round_start_seat RETURN player_state.seat_number%TYPE;

FUNCTION get_distance_from_small_blind (
	p_seat_number player_state.seat_number%TYPE
) RETURN INTEGER;

FUNCTION draw_deck_card RETURN deck.card_id%TYPE;

PROCEDURE post_blinds;

PROCEDURE perform_player_move
(
	p_seat_number        player_state.seat_number%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state.money%TYPE
);

PROCEDURE perform_explicit_player_move (
	p_seat_number        player_state.seat_number%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state.money%TYPE
);

FUNCTION get_player_showdown_muck(
	p_seat_number player_state.seat_number%TYPE
) RETURN BOOLEAN;

PROCEDURE process_game_results;

PROCEDURE process_tournament_results;

FUNCTION get_hand_rank(
	p_card_1 deck.card_id%TYPE,
	p_card_2 deck.card_id%TYPE,
	p_card_3 deck.card_id%TYPE,
	p_card_4 deck.card_id%TYPE,
	p_card_5 deck.card_id%TYPE
) RETURN VARCHAR2 RESULT_CACHE;

PROCEDURE calculate_best_hands;

PROCEDURE sort_hands;

FUNCTION get_can_fold (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_check (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_call (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_bet (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_raise (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_min_bet_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE;

FUNCTION get_max_bet_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN player_state.money%TYPE;

FUNCTION get_min_raise_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE;

FUNCTION get_max_raise_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE;

FUNCTION get_pot_deficit (
	p_seat_number player_state.seat_number%TYPE
) RETURN pot_contribution.pot_contribution%TYPE;

PROCEDURE contribute_to_pot (
	p_player_seat_number pot_contribution.player_seat_number%TYPE,
	p_pot_contribution   pot_contribution.pot_contribution%TYPE
);

PROCEDURE issue_applicable_pot_refunds;

PROCEDURE issue_default_pot_wins;

PROCEDURE edit_card(
	p_card_type   VARCHAR2,
	p_seat_number player_state.seat_number%TYPE,
	p_card_slot   NUMBER,
	p_card_id     deck.card_id%TYPE
);

PROCEDURE select_ui_state (
	p_tournament_state OUT t_rc_generic,
	p_game_state       OUT t_rc_generic,
	p_player_state     OUT t_rc_generic,
	p_pots             OUT t_rc_generic,
	p_status           OUT t_rc_generic
);

PROCEDURE log (
	p_message poker_ai_log.message%TYPE
);

PROCEDURE capture_state_log;

FUNCTION get_state_id RETURN poker_ai_log.state_id%TYPE;

PROCEDURE load_state (
	p_state_id poker_ai_log.state_id%TYPE
);

PROCEDURE load_previous_state (
	p_state_id poker_ai_log.state_id%TYPE
);

PROCEDURE load_next_state (
	p_state_id poker_ai_log.state_id%TYPE
);

END pkg_poker_ai;
