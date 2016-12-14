CREATE OR REPLACE PACKAGE pkg_poker_ai AS

TYPE t_rc_generic IS REF CURSOR;

PROCEDURE log(
	p_state_id poker_ai_log.state_id%TYPE,
	p_message  poker_ai_log.message%TYPE
);

PROCEDURE prepare_state_log(
	p_state_id poker_state_log.state_id%TYPE
);

PROCEDURE insert_poker_state_log(
	p_state_id                  poker_state_log.state_id%TYPE,
	p_tournament_id             poker_state_log.tournament_id%TYPE,
	p_tournament_mode           poker_state_log.tournament_mode%TYPE,
	p_evolution_trial_id        poker_state_log.evolution_trial_id%TYPE,
	p_player_count              poker_state_log.player_count%TYPE,
	p_buy_in_amount             poker_state_log.buy_in_amount%TYPE,
	p_tournament_in_progress    poker_state_log.tournament_in_progress%TYPE,
	p_current_game_number       poker_state_log.current_game_number%TYPE,
	p_game_in_progress          poker_state_log.game_in_progress%TYPE,
	p_small_blind_seat_number   poker_state_log.small_blind_seat_number%TYPE,
	p_big_blind_seat_number     poker_state_log.big_blind_seat_number%TYPE,
	p_turn_seat_number          poker_state_log.turn_seat_number%TYPE,
	p_small_blind_value         poker_state_log.small_blind_value%TYPE,
	p_big_blind_value           poker_state_log.big_blind_value%TYPE,
	p_betting_round_number      poker_state_log.betting_round_number%TYPE,
	p_betting_round_in_progress poker_state_log.betting_round_in_progress%TYPE,
	p_last_to_raise_seat_number poker_state_log.last_to_raise_seat_number%TYPE,
	p_min_raise_amount          poker_state_log.min_raise_amount%TYPE,
	p_community_card_1          poker_state_log.community_card_1%TYPE,
	p_community_card_2          poker_state_log.community_card_2%TYPE,
	p_community_card_3          poker_state_log.community_card_3%TYPE,
	p_community_card_4          poker_state_log.community_card_4%TYPE,
	p_community_card_5          poker_state_log.community_card_5%TYPE
);

PROCEDURE insert_player_state_log(
	p_state_id                    player_state_log.state_id%TYPE,
	p_seat_number                 player_state_log.seat_number%TYPE,
	p_player_id                   player_state_log.player_id%TYPE,
	p_current_strategy_id         player_state_log.current_strategy_id%TYPE,
	p_assumed_strategy_id         player_state_log.assumed_strategy_id%TYPE,
	p_hole_card_1                 player_state_log.hole_card_1%TYPE,
	p_hole_card_2                 player_state_log.hole_card_2%TYPE,
	p_best_hand_classification    player_state_log.best_hand_classification%TYPE,
	p_best_hand_comparator        player_state_log.best_hand_comparator%TYPE,
	p_best_hand_card_1            player_state_log.best_hand_card_1%TYPE,
	p_best_hand_card_2            player_state_log.best_hand_card_2%TYPE,
	p_best_hand_card_3            player_state_log.best_hand_card_3%TYPE,
	p_best_hand_card_4            player_state_log.best_hand_card_4%TYPE,
	p_best_hand_card_5            player_state_log.best_hand_card_5%TYPE,
	p_best_hand_rank              player_state_log.best_hand_rank%TYPE,
	p_hand_showing                player_state_log.hand_showing%TYPE,
	p_presented_bet_opportunity   player_state_log.presented_bet_opportunity%TYPE,
	p_money                       player_state_log.money%TYPE,
	p_state                       player_state_log.state%TYPE,
	p_game_rank                   player_state_log.game_rank%TYPE,
	p_tournament_rank             player_state_log.tournament_rank%TYPE,
	p_eligible_to_win_money       player_state_log.eligible_to_win_money%TYPE,
	p_total_pot_deficit           player_state_log.total_pot_deficit%TYPE,
	p_total_pot_contribution      player_state_log.total_pot_contribution%TYPE,
	p_games_played                player_state_log.games_played%TYPE,
	p_main_pots_won               player_state_log.main_pots_won%TYPE,
	p_main_pots_split             player_state_log.main_pots_split%TYPE,
	p_side_pots_won               player_state_log.side_pots_won%TYPE,
	p_side_pots_split             player_state_log.side_pots_split%TYPE,
	p_average_game_profit         player_state_log.average_game_profit%TYPE,
	p_flops_seen                  player_state_log.flops_seen%TYPE,
	p_turns_seen                  player_state_log.turns_seen%TYPE,
	p_rivers_seen                 player_state_log.rivers_seen%TYPE,
	p_pre_flop_folds              player_state_log.pre_flop_folds%TYPE,
	p_flop_folds                  player_state_log.flop_folds%TYPE,
	p_turn_folds                  player_state_log.turn_folds%TYPE,
	p_river_folds                 player_state_log.river_folds%TYPE,
	p_total_folds                 player_state_log.total_folds%TYPE,
	p_pre_flop_checks             player_state_log.pre_flop_checks%TYPE,
	p_flop_checks                 player_state_log.flop_checks%TYPE,
	p_turn_checks                 player_state_log.turn_checks%TYPE,
	p_river_checks                player_state_log.river_checks%TYPE,
	p_total_checks                player_state_log.total_checks%TYPE,
	p_pre_flop_calls              player_state_log.pre_flop_calls%TYPE,
	p_flop_calls                  player_state_log.flop_calls%TYPE,
	p_turn_calls                  player_state_log.turn_calls%TYPE,
	p_river_calls                 player_state_log.river_calls%TYPE,
	p_total_calls                 player_state_log.total_calls%TYPE,
	p_pre_flop_bets               player_state_log.pre_flop_bets%TYPE,
	p_flop_bets                   player_state_log.flop_bets%TYPE,
	p_turn_bets                   player_state_log.turn_bets%TYPE,
	p_river_bets                  player_state_log.river_bets%TYPE,
	p_total_bets                  player_state_log.total_bets%TYPE,
	p_pre_flop_total_bet_amount   player_state_log.pre_flop_total_bet_amount%TYPE,
	p_flop_total_bet_amount       player_state_log.flop_total_bet_amount%TYPE,
	p_turn_total_bet_amount       player_state_log.turn_total_bet_amount%TYPE,
	p_river_total_bet_amount      player_state_log.river_total_bet_amount%TYPE,
	p_total_bet_amount            player_state_log.total_bet_amount%TYPE,
	p_pre_flop_average_bet_amount player_state_log.pre_flop_average_bet_amount%TYPE,
	p_flop_average_bet_amount     player_state_log.flop_average_bet_amount%TYPE,
	p_turn_average_bet_amount     player_state_log.turn_average_bet_amount%TYPE,
	p_river_average_bet_amount    player_state_log.river_average_bet_amount%TYPE,
	p_average_bet_amount          player_state_log.average_bet_amount%TYPE,
	p_pre_flop_raises             player_state_log.pre_flop_raises%TYPE,
	p_flop_raises                 player_state_log.flop_raises%TYPE,
	p_turn_raises                 player_state_log.turn_raises%TYPE,
	p_river_raises                player_state_log.river_raises%TYPE,
	p_total_raises                player_state_log.total_raises%TYPE,
	p_pre_flop_total_raise_amount player_state_log.pre_flop_total_raise_amount%TYPE,
	p_flop_total_raise_amount     player_state_log.flop_total_raise_amount%TYPE,
	p_turn_total_raise_amount     player_state_log.turn_total_raise_amount%TYPE,
	p_river_total_raise_amount    player_state_log.river_total_raise_amount%TYPE,
	p_total_raise_amount          player_state_log.total_raise_amount%TYPE,
	p_pre_flop_average_raise_amt  player_state_log.pre_flop_average_raise_amount%TYPE,
	p_flop_average_raise_amount   player_state_log.flop_average_raise_amount%TYPE,
	p_turn_average_raise_amount   player_state_log.turn_average_raise_amount%TYPE,
	p_river_average_raise_amount  player_state_log.river_average_raise_amount%TYPE,
	p_average_raise_amount        player_state_log.average_raise_amount%TYPE,
	p_times_all_in                player_state_log.times_all_in%TYPE,
	p_total_money_played          player_state_log.total_money_played%TYPE,
	p_total_money_won             player_state_log.total_money_won%TYPE
);

PROCEDURE insert_pot_log(
	p_state_id             pot_log.state_id%TYPE,
	p_pot_number           pot_log.pot_number%TYPE,
	p_betting_round_number pot_log.betting_round_number%TYPE,
	p_bet_value            pot_log.bet_value%TYPE
);

PROCEDURE insert_pot_contribution_log(
	p_state_id             pot_contribution_log.state_id%TYPE,
	p_pot_number           pot_contribution_log.pot_number%TYPE,
	p_betting_round_number pot_contribution_log.betting_round_number%TYPE,
	p_player_seat_number   pot_contribution_log.player_seat_number%TYPE,
	p_pot_contribution     pot_contribution_log.pot_contribution%TYPE
);

PROCEDURE insert_tournament_result(
	p_trial_id                    tournament_result.trial_id%TYPE,
	p_generation                  tournament_result.generation%TYPE,
	p_strategy_id                 tournament_result.strategy_id%TYPE,
	p_tournament_id               tournament_result.tournament_id%TYPE,
	p_tournament_rank             tournament_result.tournament_rank%TYPE,
	p_games_played                tournament_result.games_played%TYPE,
	p_main_pots_won               tournament_result.main_pots_won%TYPE,
	p_main_pots_split             tournament_result.main_pots_split%TYPE,
	p_side_pots_won               tournament_result.side_pots_won%TYPE,
	p_side_pots_split             tournament_result.side_pots_split%TYPE,
	p_average_game_profit         tournament_result.average_game_profit%TYPE,
	p_flops_seen                  tournament_result.flops_seen%TYPE,
	p_turns_seen                  tournament_result.turns_seen%TYPE,
	p_rivers_seen                 tournament_result.rivers_seen%TYPE,
	p_pre_flop_folds              tournament_result.pre_flop_folds%TYPE,
	p_flop_folds                  tournament_result.flop_folds%TYPE,
	p_turn_folds                  tournament_result.turn_folds%TYPE,
	p_river_folds                 tournament_result.river_folds%TYPE,
	p_total_folds                 tournament_result.total_folds%TYPE,
	p_pre_flop_checks             tournament_result.pre_flop_checks%TYPE,
	p_flop_checks                 tournament_result.flop_checks%TYPE,
	p_turn_checks                 tournament_result.turn_checks%TYPE,
	p_river_checks                tournament_result.river_checks%TYPE,
	p_total_checks                tournament_result.total_checks%TYPE,
	p_pre_flop_calls              tournament_result.pre_flop_calls%TYPE,
	p_flop_calls                  tournament_result.flop_calls%TYPE,
	p_turn_calls                  tournament_result.turn_calls%TYPE,
	p_river_calls                 tournament_result.river_calls%TYPE,
	p_total_calls                 tournament_result.total_calls%TYPE,
	p_pre_flop_bets               tournament_result.pre_flop_bets%TYPE,
	p_flop_bets                   tournament_result.flop_bets%TYPE,
	p_turn_bets                   tournament_result.turn_bets%TYPE,
	p_river_bets                  tournament_result.river_bets%TYPE,
	p_total_bets                  tournament_result.total_bets%TYPE,
	p_pre_flop_total_bet_amount   tournament_result.pre_flop_total_bet_amount%TYPE,
	p_flop_total_bet_amount       tournament_result.flop_total_bet_amount%TYPE,
	p_turn_total_bet_amount       tournament_result.turn_total_bet_amount%TYPE,
	p_river_total_bet_amount      tournament_result.river_total_bet_amount%TYPE,
	p_total_bet_amount            tournament_result.total_bet_amount%TYPE,
	p_pre_flop_average_bet_amount tournament_result.pre_flop_average_bet_amount%TYPE,
	p_flop_average_bet_amount     tournament_result.flop_average_bet_amount%TYPE,
	p_turn_average_bet_amount     tournament_result.turn_average_bet_amount%TYPE,
	p_river_average_bet_amount    tournament_result.river_average_bet_amount%TYPE,
	p_average_bet_amount          tournament_result.average_bet_amount%TYPE,
	p_pre_flop_raises             tournament_result.pre_flop_raises%TYPE,
	p_flop_raises                 tournament_result.flop_raises%TYPE,
	p_turn_raises                 tournament_result.turn_raises%TYPE,
	p_river_raises                tournament_result.river_raises%TYPE,
	p_total_raises                tournament_result.total_raises%TYPE,
	p_pre_flop_total_raise_amount tournament_result.pre_flop_total_raise_amount%TYPE,
	p_flop_total_raise_amount     tournament_result.flop_total_raise_amount%TYPE,
	p_turn_total_raise_amount     tournament_result.turn_total_raise_amount%TYPE,
	p_river_total_raise_amount    tournament_result.river_total_raise_amount%TYPE,
	p_total_raise_amount          tournament_result.total_raise_amount%TYPE,
	p_pre_flop_average_raise_amt  tournament_result.pre_flop_average_raise_amount%TYPE,
	p_flop_average_raise_amount   tournament_result.flop_average_raise_amount%TYPE,
	p_turn_average_raise_amount   tournament_result.turn_average_raise_amount%TYPE,
	p_river_average_raise_amount  tournament_result.river_average_raise_amount%TYPE,
	p_average_raise_amount        tournament_result.average_raise_amount%TYPE,
	p_times_all_in                tournament_result.times_all_in%TYPE,
	p_total_money_played          tournament_result.total_money_played%TYPE,
	p_total_money_won             tournament_result.total_money_won%TYPE
);

PROCEDURE select_state(
	p_state_id                   poker_state_log.state_id%TYPE,
	p_poker_state            OUT t_rc_generic,
	p_player_state           OUT t_rc_generic,
	p_pot_state              OUT t_rc_generic,
	p_pot_contribution_state OUT t_rc_generic,
	p_poker_ai_log           OUT t_rc_generic
);

FUNCTION get_previous_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE;

FUNCTION get_next_state_id(
	p_state_id poker_state_log.state_id%TYPE
) RETURN poker_state_log.state_id%TYPE;

FUNCTION get_new_state_id RETURN poker_state_log.state_id%TYPE;

FUNCTION get_new_strategy_id RETURN strategy.strategy_id%TYPE;

PROCEDURE upsert_strategy (
	p_trial_id              strategy.trial_id%TYPE,
	p_generation            strategy.generation%TYPE,
	p_strategy_id           strategy.strategy_id%TYPE,
	p_strategy_chromosome_1 strategy.strategy_chromosome_1%TYPE,
	p_strategy_procedure_1  strategy.strategy_procedure_1%TYPE,
	p_strategy_chromosome_2 strategy.strategy_chromosome_2%TYPE,
	p_strategy_procedure_2  strategy.strategy_procedure_2%TYPE,
	p_strategy_chromosome_3 strategy.strategy_chromosome_3%TYPE,
	p_strategy_procedure_3  strategy.strategy_procedure_3%TYPE,
	p_strategy_chromosome_4 strategy.strategy_chromosome_4%TYPE,
	p_strategy_procedure_4  strategy.strategy_procedure_4%TYPE
);

PROCEDURE select_strategy (
	p_strategy_id strategy.strategy_id%TYPE,
	p_result      OUT t_rc_generic
);

END pkg_poker_ai;
