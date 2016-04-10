CREATE OR REPLACE PACKAGE pkg_poker_ai AS

TYPE t_rc_generic IS REF CURSOR;

PROCEDURE log (
	p_message poker_ai_log.message%TYPE
);

PROCEDURE initialize_tournament
(
	p_player_count  tournament_state.player_count%TYPE,
    p_buy_in_amount tournament_state.buy_in_amount%TYPE
);

PROCEDURE play_tournament;

PROCEDURE initialize_game
(
	p_small_blind_seat_number game_state.small_blind_seat_number%TYPE,
    p_small_blind_value       game_state.small_blind_value%TYPE,
    p_big_blind_value         game_state.big_blind_value%TYPE
);

PROCEDURE play_game;

FUNCTION play_round RETURN INTEGER;

FUNCTION get_next_active_seat_number
(
	p_current_player_seat_number player_state.seat_number%TYPE
) RETURN player_state.seat_number%TYPE;

FUNCTION draw_deck_card RETURN deck.card_id%TYPE;

PROCEDURE post_blinds;

PROCEDURE perform_player_move
(
	p_seat_number player_state.seat_number%TYPE
);

FUNCTION get_player_showdown_muck(
	p_seat_number player_state.seat_number%TYPE
) RETURN BOOLEAN;

FUNCTION get_active_player_count RETURN INTEGER;

PROCEDURE process_game_results;

FUNCTION get_distance_from_small_blind (
	p_seat_number player_state.seat_number%TYPE
) RETURN INTEGER;

FUNCTION get_hand_rank(
	p_card_1 deck.card_id%TYPE,
	p_card_2 deck.card_id%TYPE,
	p_card_3 deck.card_id%TYPE,
	p_card_4 deck.card_id%TYPE,
	p_card_5 deck.card_id%TYPE
) RETURN VARCHAR2;

FUNCTION get_card_display_value(
	p_card_id deck.card_id%TYPE
) RETURN deck.display_value%TYPE RESULT_CACHE;

FUNCTION get_hand_display_value(
	p_hand_rank player_state.best_hand_rank%TYPE,
	p_card_1    deck.card_id%TYPE,
	p_card_2    deck.card_id%TYPE,
	p_card_3    deck.card_id%TYPE,
	p_card_4    deck.card_id%TYPE,
	p_card_5    deck.card_id%TYPE
) RETURN VARCHAR2;

PROCEDURE select_player_state(
	p_result_set OUT t_rc_generic
);

END pkg_poker_ai;
