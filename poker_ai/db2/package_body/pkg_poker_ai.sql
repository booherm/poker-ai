CREATE OR REPLACE PACKAGE BODY pkg_poker_ai AS

PROCEDURE log(
	p_state_id poker_ai_log.state_id%TYPE,
	p_message  poker_ai_log.message%TYPE
) IS

	PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

	IF p_state_id IS NOT NULL THEN
		INSERT INTO poker_ai_log (
			log_record_number,
			mod_date,
			state_id,
			message
		) VALUES (
			pai_seq_generic.NEXTVAL,
			SYSDATE,
			p_state_id,
			p_message
		);

		COMMIT;
	END IF;
	
END log;

PROCEDURE prepare_state_log(
	p_state_id poker_state_log.state_id%TYPE
) IS
BEGIN

	DELETE FROM poker_state_log WHERE state_id = p_state_id;
	DELETE FROM player_state_log WHERE state_id = p_state_id;
	DELETE FROM pot_log WHERE state_id = p_state_id;
	DELETE FROM pot_contribution_log WHERE state_id = p_state_id;
	
END prepare_state_log;

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
) IS
BEGIN

	INSERT INTO poker_state_log(
		state_id,
		tournament_id,
		tournament_mode,
		evolution_trial_id,
		player_count,
		buy_in_amount,
		tournament_in_progress,
		current_game_number,
		game_in_progress,
		small_blind_seat_number,
		big_blind_seat_number,
		turn_seat_number,
		small_blind_value,
		big_blind_value,
		betting_round_number,
		betting_round_in_progress,
		last_to_raise_seat_number,
		min_raise_amount,
		community_card_1,
		community_card_2,
		community_card_3,
		community_card_4,
		community_card_5
	) VALUES (
		p_state_id,
		p_tournament_id,
		p_tournament_mode,
		p_evolution_trial_id,
		p_player_count,
		p_buy_in_amount,
		p_tournament_in_progress,
		p_current_game_number,
		p_game_in_progress,
		p_small_blind_seat_number,
		p_big_blind_seat_number,
		p_turn_seat_number,
		p_small_blind_value,
		p_big_blind_value,
		p_betting_round_number,
		p_betting_round_in_progress,
		p_last_to_raise_seat_number,
		p_min_raise_amount,
		p_community_card_1,
		p_community_card_2,
		p_community_card_3,
		p_community_card_4,
		p_community_card_5
	);
	
END insert_poker_state_log;

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
) IS
BEGIN

	INSERT INTO player_state_log(
		state_id,
		seat_number,
		player_id,
		current_strategy_id,
		assumed_strategy_id,
		hole_card_1,
		hole_card_2,
		best_hand_classification,
		best_hand_comparator,
		best_hand_card_1,
		best_hand_card_2,
		best_hand_card_3,
		best_hand_card_4,
		best_hand_card_5,
		best_hand_rank,
		hand_showing,
		presented_bet_opportunity,
		money,
		state,
		game_rank,
		tournament_rank,
		games_played,
		main_pots_won,
		main_pots_split,
		side_pots_won,
		side_pots_split,
		average_game_profit,
		flops_seen,
		turns_seen,
		rivers_seen,
		pre_flop_folds,
		flop_folds,
		turn_folds,
		river_folds,
		total_folds,
		pre_flop_checks,
		flop_checks,
		turn_checks,
		river_checks,
		total_checks,
		pre_flop_calls,
		flop_calls,
		turn_calls,
		river_calls,
		total_calls,
		pre_flop_bets,
		flop_bets,
		turn_bets,
		river_bets,
		total_bets,
		pre_flop_total_bet_amount,
		flop_total_bet_amount,
		turn_total_bet_amount,
		river_total_bet_amount,
		total_bet_amount,
		pre_flop_average_bet_amount,
		flop_average_bet_amount,
		turn_average_bet_amount,
		river_average_bet_amount,
		average_bet_amount,
		pre_flop_raises,
		flop_raises,
		turn_raises,
		river_raises,
		total_raises,
		pre_flop_total_raise_amount,
		flop_total_raise_amount,
		turn_total_raise_amount,
		river_total_raise_amount,
		total_raise_amount,
		pre_flop_average_raise_amount,
		flop_average_raise_amount,
		turn_average_raise_amount,
		river_average_raise_amount,
		average_raise_amount,
		times_all_in,
		total_money_played,
		total_money_won
	) VALUES (
		p_state_id,
		p_seat_number,
		p_player_id,
		p_current_strategy_id,
		p_assumed_strategy_id,
		p_hole_card_1,
		p_hole_card_2,
		p_best_hand_classification,
		p_best_hand_comparator,
		p_best_hand_card_1,
		p_best_hand_card_2,
		p_best_hand_card_3,
		p_best_hand_card_4,
		p_best_hand_card_5,
		p_best_hand_rank,
		p_hand_showing,
		p_presented_bet_opportunity,
		p_money,
		p_state,
		p_game_rank,
		p_tournament_rank,
		p_games_played,
		p_main_pots_won,
		p_main_pots_split,
		p_side_pots_won,
		p_side_pots_split,
		p_average_game_profit,
		p_flops_seen,
		p_turns_seen,
		p_rivers_seen,
		p_pre_flop_folds,
		p_flop_folds,
		p_turn_folds,
		p_river_folds,
		p_total_folds,
		p_pre_flop_checks,
		p_flop_checks,
		p_turn_checks,
		p_river_checks,
		p_total_checks,
		p_pre_flop_calls,
		p_flop_calls,
		p_turn_calls,
		p_river_calls,
		p_total_calls,
		p_pre_flop_bets,
		p_flop_bets,
		p_turn_bets,
		p_river_bets,
		p_total_bets,
		p_pre_flop_total_bet_amount,
		p_flop_total_bet_amount,
		p_turn_total_bet_amount,
		p_river_total_bet_amount,
		p_total_bet_amount,
		p_pre_flop_average_bet_amount,
		p_flop_average_bet_amount,
		p_turn_average_bet_amount,
		p_river_average_bet_amount,
		p_average_bet_amount,
		p_pre_flop_raises,
		p_flop_raises,
		p_turn_raises,
		p_river_raises,
		p_total_raises,
		p_pre_flop_total_raise_amount,
		p_flop_total_raise_amount,
		p_turn_total_raise_amount,
		p_river_total_raise_amount,
		p_total_raise_amount,
		p_pre_flop_average_raise_amt,
		p_flop_average_raise_amount,
		p_turn_average_raise_amount,
		p_river_average_raise_amount,
		p_average_raise_amount,
		p_times_all_in,
		p_total_money_played,
		p_total_money_won
	);
	
END insert_player_state_log;

PROCEDURE insert_pot_log(
	p_state_id             pot_log.state_id%TYPE,
	p_pot_number           pot_log.pot_number%TYPE,
	p_betting_round_number pot_log.betting_round_number%TYPE,
	p_bet_value            pot_log.bet_value%TYPE
) IS
BEGIN
	
	INSERT INTO pot_log(
		state_id,
		pot_number,
		betting_round_number,
		bet_value
	) VALUES (
		p_state_id,
		p_pot_number,
		p_betting_round_number,
		p_bet_value
	);

END insert_pot_log;

PROCEDURE insert_pot_contribution_log(
	p_state_id             pot_contribution_log.state_id%TYPE,
	p_pot_number           pot_contribution_log.pot_number%TYPE,
	p_betting_round_number pot_contribution_log.betting_round_number%TYPE,
	p_player_seat_number   pot_contribution_log.player_seat_number%TYPE,
	p_pot_contribution     pot_contribution_log.pot_contribution%TYPE
) IS
BEGIN

	INSERT INTO pot_contribution_log(
		state_id,
		pot_number,
		betting_round_number,
		player_seat_number,
		pot_contribution
	) VALUES (
		p_state_id,
		p_pot_number,
		p_betting_round_number,
		p_player_seat_number,
		p_pot_contribution
	);
	
END insert_pot_contribution_log;

PROCEDURE select_state(
	p_state_id                   poker_state_log.state_id%TYPE,
	p_poker_state            OUT t_rc_generic,
	p_player_state           OUT t_rc_generic,
	p_pot_state              OUT t_rc_generic,
	p_pot_contribution_state OUT t_rc_generic,
	p_poker_ai_log           OUT t_rc_generic
) IS
BEGIN

	OPEN p_poker_state FOR
		SELECT state_id,
			   tournament_id,
			   tournament_mode,
			   evolution_trial_id,
			   player_count,
			   buy_in_amount,
			   tournament_in_progress,
			   current_game_number,
			   game_in_progress,
			   small_blind_seat_number,
			   big_blind_seat_number,
			   turn_seat_number,
			   small_blind_value,
			   big_blind_value,
			   betting_round_number,
			   betting_round_in_progress,
			   last_to_raise_seat_number,
			   min_raise_amount,
			   community_card_1,
			   community_card_2,
			   community_card_3,
			   community_card_4,
			   community_card_5
		FROM   poker_state_log
		WHERE  state_id = p_state_id;
		
	OPEN p_player_state FOR
		SELECT state_id,
			   seat_number,
			   player_id,
			   current_strategy_id,
			   assumed_strategy_id,
			   hole_card_1,
			   hole_card_2,
			   best_hand_classification,
			   best_hand_comparator,
			   best_hand_card_1,
			   best_hand_card_2,
			   best_hand_card_3,
			   best_hand_card_4,
			   best_hand_card_5,
			   best_hand_rank,
			   hand_showing,
			   presented_bet_opportunity,
			   money,
			   state,
			   game_rank,
			   tournament_rank,
			   games_played,
			   main_pots_won,
			   main_pots_split,
			   side_pots_won,
			   side_pots_split,
			   average_game_profit,
			   flops_seen,
			   turns_seen,
			   rivers_seen,
			   pre_flop_folds,
			   flop_folds,
			   turn_folds,
			   river_folds,
			   total_folds,
			   pre_flop_checks,
			   flop_checks,
			   turn_checks,
			   river_checks,
			   total_checks,
			   pre_flop_calls,
			   flop_calls,
			   turn_calls,
			   river_calls,
			   total_calls,
			   pre_flop_bets,
			   flop_bets,
			   turn_bets,
			   river_bets,
			   total_bets,
			   pre_flop_total_bet_amount,
			   flop_total_bet_amount,
			   turn_total_bet_amount,
			   river_total_bet_amount,
			   total_bet_amount,
			   pre_flop_average_bet_amount,
			   flop_average_bet_amount,
			   turn_average_bet_amount,
			   river_average_bet_amount,
			   average_bet_amount,
			   pre_flop_raises,
			   flop_raises,
			   turn_raises,
			   river_raises,
			   total_raises,
			   pre_flop_total_raise_amount,
			   flop_total_raise_amount,
			   turn_total_raise_amount,
			   river_total_raise_amount,
			   total_raise_amount,
			   pre_flop_average_raise_amount,
			   flop_average_raise_amount,
			   turn_average_raise_amount,
			   river_average_raise_amount,
			   average_raise_amount,
			   times_all_in,
			   total_money_played,
			   total_money_won
		FROM   player_state_log
		WHERE  state_id = p_state_id
		ORDER BY seat_number;
	
	OPEN p_pot_state FOR
		SELECT state_id,
			   pot_number,
			   betting_round_number,
			   bet_value
		FROM   pot_log
		WHERE  state_id = p_state_id
		ORDER BY pot_number;
	
	OPEN p_pot_contribution_state FOR
		SELECT state_id,
			   pot_number,
			   betting_round_number,
			   player_seat_number,
			   pot_contribution
		FROM   pot_contribution_log
		WHERE  state_id = p_state_id
		ORDER BY
			pot_number,
			betting_round_number,
			player_seat_number;
			
	OPEN p_poker_ai_log FOR
		SELECT log_record_number,
			   message
		FROM   poker_ai_log
		WHERE  state_id = p_state_id
		ORDER BY log_record_number DESC;
			
	EXCEPTION WHEN OTHERS THEN
		IF p_poker_state%ISOPEN THEN
			CLOSE p_poker_state;
		END IF;
		IF p_player_state%ISOPEN THEN
			CLOSE p_player_state;
		END IF;
		IF p_pot_state%ISOPEN THEN
			CLOSE p_pot_state;
		END IF;
		IF p_pot_contribution_state%ISOPEN THEN
			CLOSE p_pot_contribution_state;
		END IF;
		IF p_poker_ai_log%ISOPEN THEN
			CLOSE p_poker_ai_log;
		END IF;
		RAISE;
	
END select_state;

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

FUNCTION get_new_state_id RETURN poker_state_log.state_id%TYPE IS
BEGIN

	RETURN pai_seq_sid.NEXTVAL;
	
END get_new_state_id;

END pkg_poker_ai;