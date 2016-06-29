CREATE OR REPLACE PACKAGE pkg_poker_ai AS

v_max_player_count INTEGER := 10;

PROCEDURE play_tournament(
	p_evolution_trial_id        evolution_trial.trial_id%TYPE,
	p_tournament_id             poker_state_log.tournament_id%TYPE,
	p_strategy_ids              t_tbl_number,
	p_buy_in_amount             poker_state_log.buy_in_amount%TYPE,
	p_initial_small_blind_value poker_state_log.small_blind_value%TYPE,
	p_double_blinds_interval    poker_state_log.current_game_number%TYPE,
	p_perform_state_logging     VARCHAR2
);

FUNCTION initialize_tournament(
	p_tournament_id         poker_state_log.tournament_id%TYPE,
	p_tournament_mode       poker_state_log.tournament_mode%TYPE,
	p_evolution_trial_id    evolution_trial.trial_id%TYPE,
	p_strategy_ids          t_tbl_number,
	p_player_count          poker_state_log.player_count%TYPE,
    p_buy_in_amount         poker_state_log.buy_in_amount%TYPE,
	p_perform_state_logging VARCHAR2
) RETURN t_poker_state;

FUNCTION initialize_deck RETURN t_tbl_deck;

PROCEDURE step_play(
	p_poker_state           IN OUT t_poker_state,
	p_player_move           VARCHAR2,
	p_player_move_amount    player_state_log.money%TYPE,
	p_perform_state_logging VARCHAR2
);

PROCEDURE initialize_game(
	p_poker_state IN OUT t_poker_state
);

FUNCTION get_active_player_count(
	p_poker_state t_poker_state
) RETURN poker_state_log.player_count%TYPE;

FUNCTION get_next_active_seat_number(
	p_poker_state                t_poker_state,
	p_current_player_seat_number player_state_log.seat_number%TYPE,
	p_include_folded_players     VARCHAR2,
	p_include_all_in_players     VARCHAR2
) RETURN player_state_log.seat_number%TYPE;

PROCEDURE init_betting_round_start_seat(
	p_poker_state IN OUT t_poker_state
);

FUNCTION get_distance_from_small_blind(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN INTEGER;

FUNCTION draw_deck_card(
	p_poker_state IN OUT t_poker_state
) RETURN poker_state_log.community_card_1%TYPE;

PROCEDURE post_blinds(
	p_poker_state IN OUT t_poker_state
);

PROCEDURE perform_player_move(
	p_poker_state        IN OUT t_poker_state,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
);

PROCEDURE perform_explicit_player_move(
	p_poker_state        IN OUT t_poker_state,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
);

FUNCTION get_player_showdown_muck(
	p_seat_number player_state_log.seat_number%TYPE
) RETURN BOOLEAN;

PROCEDURE process_game_results(
	p_poker_state IN OUT t_poker_state
);

PROCEDURE process_tournament_results(
	p_poker_state IN OUT t_poker_state
);

FUNCTION get_hand_rank(
	p_poker_state t_poker_state,
	p_card_1      poker_state_log.community_card_1%TYPE,
	p_card_2      poker_state_log.community_card_1%TYPE,
	p_card_3      poker_state_log.community_card_1%TYPE,
	p_card_4      poker_state_log.community_card_1%TYPE,
	p_card_5      poker_state_log.community_card_1%TYPE
) RETURN VARCHAR2;

PROCEDURE calculate_best_hands(
	p_poker_state IN OUT t_poker_state
);

PROCEDURE sort_hands(
	p_poker_state IN OUT t_poker_state
);

FUNCTION get_can_fold(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_check(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_call(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_bet(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_can_raise(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2;

FUNCTION get_min_bet_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE;

FUNCTION get_max_bet_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN player_state_log.money%TYPE;

FUNCTION get_min_raise_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE;

FUNCTION get_max_raise_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE;

FUNCTION get_pot_deficit(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN pot_contribution_log.pot_contribution%TYPE;

PROCEDURE contribute_to_pot(
	p_poker_state        IN OUT t_poker_state,
	p_player_seat_number pot_contribution_log.player_seat_number%TYPE,
	p_pot_contribution   pot_contribution_log.pot_contribution%TYPE
);

PROCEDURE issue_applicable_pot_refunds(
	p_poker_state IN OUT t_poker_state
);

PROCEDURE issue_default_pot_wins(
	p_poker_state IN OUT t_poker_state
);

PROCEDURE log(
	p_state_id poker_ai_log.state_id%TYPE,
	p_message  poker_ai_log.message%TYPE
);

PROCEDURE log(
	p_message poker_ai_log.message%TYPE
);

PROCEDURE capture_state_log(
	p_poker_state t_poker_state
);

FUNCTION get_poker_state(
	p_state_id poker_state_log.state_id%TYPE
) RETURN t_poker_state;

END pkg_poker_ai;
