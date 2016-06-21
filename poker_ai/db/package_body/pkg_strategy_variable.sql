CREATE OR REPLACE PACKAGE BODY pkg_strategy_variable AS

FUNCTION get_strategy_variable_value (
	p_strategy_variable_id INTEGER,
	p_variable_qualifiers  t_strat_variable_qualifiers
) RETURN NUMBER IS

	v_strategy_variable_name VARCHAR2(100);
	v_peer_seat_number       player_state.seat_number%TYPE;
	v_return_value           NUMBER;
	
BEGIN

	v_strategy_variable_name := v_strategy_variable_ids(p_strategy_variable_id);

	IF v_strategy_variable_name LIKE 'PLAYER_STATE_PEER_%' THEN
		
		-- peer variable, determine seat number of peer player
		WITH peer_players AS (
			SELECT seat_number peer_seat_number,
				   DENSE_RANK() OVER (ORDER BY seat_number) peer_player_number
			FROM   player_state
			WHERE  seat_number != p_variable_qualifiers.seat_number
		)
		SELECT peer_seat_number
		INTO   v_peer_seat_number
		FROM   peer_players
		WHERE  peer_player_number = TO_NUMBER(SUBSTR(v_strategy_variable_name, 19, 2));

		-- get variable value
		CASE SUBSTR(v_strategy_variable_name, 22)
			WHEN 'SEAT_NUMBER' THEN
				v_return_value := v_peer_seat_number;
			WHEN 'PLAYER_ID' THEN
				SELECT MIN(player_id) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'MONEY' THEN
				SELECT MIN(money) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'STATE' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   master_field_value mfv
				WHERE  ps.seat_number = v_peer_seat_number
				   AND mfv.field_name_code = 'PLAYER_STATE'
				   AND ps.state = mfv.field_value_code;
			WHEN 'HAND_SHOWING' THEN
				SELECT MIN(CASE hand_showing WHEN 'Y' THEN 1 WHEN 'N' THEN 0 END) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRESENTED_BET_OPPORTUNITY' THEN
				SELECT MIN(CASE presented_bet_opportunity WHEN 'Y' THEN 1 WHEN 'N' THEN 0 END) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOURNAMENT_RANK' THEN
				SELECT MIN(tournament_rank) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'GAMES_PLAYED' THEN
				SELECT MIN(games_played) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'MAIN_POTS_WON' THEN
				SELECT MIN(main_pots_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'MAIN_POTS_SPLIT' THEN
				SELECT MIN(main_pots_split) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'SIDE_POTS_WON' THEN
				SELECT MIN(side_pots_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'SIDE_POTS_SPLIT' THEN
				SELECT MIN(side_pots_split) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'AVERAGE_GAME_PROFIT' THEN
				SELECT MIN(average_game_profit) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOPS_SEEN' THEN
				SELECT MIN(flops_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURNS_SEEN' THEN
				SELECT MIN(turns_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVERS_SEEN' THEN
				SELECT MIN(rivers_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_FOLDS' THEN
				SELECT MIN(pre_flop_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_FOLDS' THEN
				SELECT MIN(flop_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_FOLDS' THEN
				SELECT MIN(turn_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_FOLDS' THEN
				SELECT MIN(river_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_FOLDS' THEN
				SELECT MIN(total_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_CHECKS' THEN
				SELECT MIN(pre_flop_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_CHECKS' THEN
				SELECT MIN(flop_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_CHECKS' THEN
				SELECT MIN(turn_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_CHECKS' THEN
				SELECT MIN(river_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_CHECKS' THEN
				SELECT MIN(total_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_CALLS' THEN
				SELECT MIN(pre_flop_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_CALLS' THEN
				SELECT MIN(flop_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_CALLS' THEN
				SELECT MIN(turn_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_CALLS' THEN
				SELECT MIN(river_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_CALLS' THEN
				SELECT MIN(total_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_BETS' THEN
				SELECT MIN(pre_flop_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_BETS' THEN
				SELECT MIN(flop_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_BETS' THEN
				SELECT MIN(turn_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_BETS' THEN
				SELECT MIN(river_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_BETS' THEN
				SELECT MIN(total_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(pre_flop_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(flop_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(turn_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(river_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_BET_AMOUNT' THEN
				SELECT MIN(total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(pre_flop_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(flop_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(turn_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(river_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_RAISES' THEN
				SELECT MIN(pre_flop_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_RAISES' THEN
				SELECT MIN(flop_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_RAISES' THEN
				SELECT MIN(turn_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_RAISES' THEN
				SELECT MIN(river_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_RAISES' THEN
				SELECT MIN(total_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(pre_flop_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(flop_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(turn_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(river_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'PRE_FLOP_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(pre_flop_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'FLOP_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(flop_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TURN_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(turn_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'RIVER_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(river_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TIMES_ALL_IN' THEN
				SELECT MIN(times_all_in) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_MONEY_PLAYED' THEN
				SELECT MIN(total_money_played) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
			WHEN 'TOTAL_MONEY_WON' THEN
				SELECT MIN(total_money_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = v_peer_seat_number;
		END CASE;
		
	ELSIF v_strategy_variable_name LIKE 'PLAYER_STATE_ME%' THEN

		-- non-peer variable
		CASE SUBSTR(v_strategy_variable_name, 17)
			WHEN 'SEAT_NUMBER' THEN
				v_return_value := p_variable_qualifiers.seat_number;
			WHEN 'PLAYER_ID' THEN
				SELECT MIN(player_id) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'HOLE_CARD_1_ID' THEN
				SELECT MIN(hole_card_1) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'HOLE_CARD_1_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.hole_card_1 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'HOLE_CARD_1_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.hole_card_1 = d.card_id;
			WHEN 'HOLE_CARD_2_ID' THEN
				SELECT MIN(hole_card_2) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'HOLE_CARD_2_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.hole_card_2 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'HOLE_CARD_2_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.hole_card_2 = d.card_id;
			WHEN 'BEST_HAND_RANK' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND mfv.field_name_code = 'HAND_RANK'
				   AND ps.best_hand_rank = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_1_ID' THEN
				SELECT MIN(best_hand_card_1) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'BEST_HAND_CARD_1_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_1 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_1_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_1 = d.card_id;
			WHEN 'BEST_HAND_CARD_2_ID' THEN
				SELECT MIN(best_hand_card_2) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'BEST_HAND_CARD_2_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_2 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_2_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_2 = d.card_id;
			WHEN 'BEST_HAND_CARD_3_ID' THEN
				SELECT MIN(best_hand_card_3) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'BEST_HAND_CARD_3_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_3 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_3_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_3 = d.card_id;
			WHEN 'BEST_HAND_CARD_4_ID' THEN
				SELECT MIN(best_hand_card_4) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'BEST_HAND_CARD_4_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_4 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_4_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_4 = d.card_id;
			WHEN 'BEST_HAND_CARD_5_ID' THEN
				SELECT MIN(best_hand_card_5) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'BEST_HAND_CARD_5_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_5 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'BEST_HAND_CARD_5_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   deck d
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND ps.best_hand_card_5 = d.card_id;
			WHEN 'HAND_SHOWING' THEN
				SELECT MIN(CASE hand_showing WHEN 'Y' THEN 1 WHEN 'N' THEN 0 END) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRESENTED_BET_OPPORTUNITY' THEN
				SELECT MIN(CASE presented_bet_opportunity WHEN 'Y' THEN 1 WHEN 'N' THEN 0 END) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'MONEY' THEN
				SELECT MIN(money) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'STATE' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   player_state ps,
					   master_field_value mfv
				WHERE  ps.seat_number = p_variable_qualifiers.seat_number
				   AND mfv.field_name_code = 'PLAYER_STATE'
				   AND ps.state = mfv.field_value_code;
			WHEN 'TOURNAMENT_RANK' THEN
				SELECT MIN(tournament_rank) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'GAMES_PLAYED' THEN
				SELECT MIN(games_played) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'MAIN_POTS_WON' THEN
				SELECT MIN(main_pots_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'MAIN_POTS_SPLIT' THEN
				SELECT MIN(main_pots_split) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'SIDE_POTS_WON' THEN
				SELECT MIN(side_pots_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'SIDE_POTS_SPLIT' THEN
				SELECT MIN(side_pots_split) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'AVERAGE_GAME_PROFIT' THEN
				SELECT MIN(average_game_profit) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOPS_SEEN' THEN
				SELECT MIN(flops_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURNS_SEEN' THEN
				SELECT MIN(turns_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVERS_SEEN' THEN
				SELECT MIN(rivers_seen) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_FOLDS' THEN
				SELECT MIN(pre_flop_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_FOLDS' THEN
				SELECT MIN(flop_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_FOLDS' THEN
				SELECT MIN(turn_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_FOLDS' THEN
				SELECT MIN(river_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_FOLDS' THEN
				SELECT MIN(total_folds) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_CHECKS' THEN
				SELECT MIN(pre_flop_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_CHECKS' THEN
				SELECT MIN(flop_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_CHECKS' THEN
				SELECT MIN(turn_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_CHECKS' THEN
				SELECT MIN(river_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_CHECKS' THEN
				SELECT MIN(total_checks) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_CALLS' THEN
				SELECT MIN(pre_flop_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_CALLS' THEN
				SELECT MIN(flop_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_CALLS' THEN
				SELECT MIN(turn_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_CALLS' THEN
				SELECT MIN(river_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_CALLS' THEN
				SELECT MIN(total_calls) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_BETS' THEN
				SELECT MIN(pre_flop_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_BETS' THEN
				SELECT MIN(flop_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_BETS' THEN
				SELECT MIN(turn_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_BETS' THEN
				SELECT MIN(river_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_BETS' THEN
				SELECT MIN(total_bets) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(pre_flop_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(flop_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(turn_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_TOTAL_BET_AMOUNT' THEN
				SELECT MIN(river_total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_BET_AMOUNT' THEN
				SELECT MIN(total_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(pre_flop_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(flop_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(turn_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(river_average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'AVERAGE_BET_AMOUNT' THEN
				SELECT MIN(average_bet_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_RAISES' THEN
				SELECT MIN(pre_flop_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_RAISES' THEN
				SELECT MIN(flop_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_RAISES' THEN
				SELECT MIN(turn_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_RAISES' THEN
				SELECT MIN(river_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_RAISES' THEN
				SELECT MIN(total_raises) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(pre_flop_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(flop_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(turn_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(river_total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_RAISE_AMOUNT' THEN
				SELECT MIN(total_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'PRE_FLOP_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(pre_flop_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'FLOP_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(flop_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TURN_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(turn_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'RIVER_AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(river_average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'AVERAGE_RAISE_AMOUNT' THEN
				SELECT MIN(average_raise_amount) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TIMES_ALL_IN' THEN
				SELECT MIN(times_all_in) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_MONEY_PLAYED' THEN
				SELECT MIN(total_money_played) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
			WHEN 'TOTAL_MONEY_WON' THEN
				SELECT MIN(total_money_won) return_value
				INTO   v_return_value
				FROM   player_state
				WHERE  seat_number = p_variable_qualifiers.seat_number;
		END CASE;
		
	ELSIF v_strategy_variable_name LIKE 'TOURNAMENT_STATE%' THEN
	
		CASE SUBSTR(v_strategy_variable_name, 18)
			WHEN 'PLAYER_COUNT' THEN
				SELECT MIN(player_count) return_value
				INTO   v_return_value
				FROM   tournament_state;
			WHEN 'BUY_IN_AMOUNT' THEN
				SELECT MIN(buy_in_amount) return_value
				INTO   v_return_value
				FROM   tournament_state;
			WHEN 'CURRENT_GAME_NUMBER' THEN
				SELECT MIN(current_game_number) return_value
				INTO   v_return_value
				FROM   tournament_state;
		END CASE;
			
	ELSIF v_strategy_variable_name LIKE 'GAME_STATE%' THEN
	
		CASE SUBSTR(v_strategy_variable_name, 12)
			WHEN 'SMALL_BLIND_SEAT_NUMBER' THEN
				SELECT MIN(small_blind_seat_number) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'BIG_BLIND_SEAT_NUMBER' THEN
				SELECT MIN(big_blind_seat_number) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'TURN_SEAT_NUMBER' THEN
				SELECT MIN(turn_seat_number) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'SMALL_BLIND_VALUE' THEN
				SELECT MIN(small_blind_value) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'BIG_BLIND_VALUE' THEN
				SELECT MIN(big_blind_value) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'BETTING_ROUND_NUMBER' THEN
				SELECT MIN(betting_round_number) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'LAST_TO_RAISE_SEAT_NUMBER' THEN
				SELECT MIN(last_to_raise_seat_number) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'MIN_RAISE_AMOUNT' THEN
				SELECT MIN(min_raise_amount) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_1_ID' THEN
				SELECT MIN(community_card_1) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_1_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d,
					   master_field_value mfv
				WHERE  gs.community_card_1 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'COMMUNITY_CARD_1_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d
				WHERE  gs.community_card_1 = d.card_id;
			WHEN 'COMMUNITY_CARD_2_ID' THEN
				SELECT MIN(community_card_2) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_2_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d,
					   master_field_value mfv
				WHERE  gs.community_card_2 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'COMMUNITY_CARD_2_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d
				WHERE  gs.community_card_2 = d.card_id;
			WHEN 'COMMUNITY_CARD_3_ID' THEN
				SELECT MIN(community_card_3) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_3_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d,
					   master_field_value mfv
				WHERE  gs.community_card_3 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'COMMUNITY_CARD_3_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d
				WHERE  gs.community_card_3 = d.card_id;
			WHEN 'COMMUNITY_CARD_4_ID' THEN
				SELECT MIN(community_card_4) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_4_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d,
					   master_field_value mfv
				WHERE  gs.community_card_4 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'COMMUNITY_CARD_4_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d
				WHERE  gs.community_card_4 = d.card_id;
			WHEN 'COMMUNITY_CARD_5_ID' THEN
				SELECT MIN(community_card_5) return_value
				INTO   v_return_value
				FROM   game_state;
			WHEN 'COMMUNITY_CARD_5_SUIT' THEN
				SELECT MIN(mfv.numeric_value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d,
					   master_field_value mfv
				WHERE  gs.community_card_5 = d.card_id
				   AND mfv.field_name_code = 'CARD_SUIT'
				   AND d.suit = mfv.field_value_code;
			WHEN 'COMMUNITY_CARD_5_VALUE' THEN
				SELECT MIN(d.value) return_value
				INTO   v_return_value
				FROM   game_state gs,
					   deck d
				WHERE  gs.community_card_5 = d.card_id;
		END CASE;
		
	ELSIF v_strategy_variable_name LIKE 'DECISION_TYPE%' THEN
	
		CASE SUBSTR(v_strategy_variable_name, 15)
			WHEN 'CAN_FOLD' THEN
				v_return_value := CASE WHEN p_variable_qualifiers.can_fold = 'Y' THEN 1 ELSE 0 END;
			WHEN 'CAN_CHECK' THEN
				v_return_value := CASE WHEN p_variable_qualifiers.can_check = 'Y' THEN 1 ELSE 0 END;
			WHEN 'CAN_CALL' THEN
				v_return_value := CASE WHEN p_variable_qualifiers.can_call = 'Y' THEN 1 ELSE 0 END;
			WHEN 'CAN_BET' THEN
				v_return_value := CASE WHEN p_variable_qualifiers.can_bet = 'Y' THEN 1 ELSE 0 END;
			WHEN 'CAN_RAISE' THEN
				v_return_value := CASE WHEN p_variable_qualifiers.can_raise = 'Y' THEN 1 ELSE 0 END;
		END CASE;
		
	ELSIF v_strategy_variable_name LIKE 'CONSTANT%' THEN

		v_return_value := TO_NUMBER(SUBSTR(v_strategy_variable_name, 10));
			
	END IF;
	
	IF v_return_value IS NULL THEN
		RETURN -1;
	ELSE
		RETURN v_return_value;
	END IF;		
			
END get_strategy_variable_value;

BEGIN

	-- package variables initialization
	v_variable_index := pkg_ga_player.v_strat_chromosome_metadata.expression_slot_id_count;

	FOR v_i IN 1 .. (pkg_poker_ai.v_max_player_count - 1) LOOP
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.SEAT_NUMBER';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PLAYER_ID';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.MONEY';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.STATE';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.HAND_SHOWING';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRESENTED_BET_OPPORTUNITY';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOURNAMENT_RANK';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.GAMES_PLAYED';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.MAIN_POTS_WON';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.MAIN_POTS_SPLIT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.SIDE_POTS_WON';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.SIDE_POTS_SPLIT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.AVERAGE_GAME_PROFIT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOPS_SEEN';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURNS_SEEN';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVERS_SEEN';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_FOLDS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_FOLDS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_FOLDS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_FOLDS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_FOLDS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_CHECKS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_CHECKS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_CHECKS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_CHECKS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_CHECKS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_CALLS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_CALLS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_CALLS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_CALLS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_CALLS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_BETS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_BETS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_BETS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_BETS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_BETS';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_TOTAL_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_TOTAL_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_TOTAL_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_TOTAL_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_AVERAGE_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_AVERAGE_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_AVERAGE_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_AVERAGE_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.AVERAGE_BET_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_RAISES';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_RAISES';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_RAISES';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_RAISES';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_RAISES';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_TOTAL_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_TOTAL_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_TOTAL_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_TOTAL_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.PRE_FLOP_AVERAGE_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.FLOP_AVERAGE_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TURN_AVERAGE_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.RIVER_AVERAGE_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.AVERAGE_RAISE_AMOUNT';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TIMES_ALL_IN';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_MONEY_PLAYED';
		v_variable_index := v_variable_index + 1;
		v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_PEER_' || LPAD(v_i, 2, '0') || '.TOTAL_MONEY_WON';
		v_variable_index := v_variable_index + 1;
	END LOOP;
	
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.SEAT_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PLAYER_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_1_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_1_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_1_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_2_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_2_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HOLE_CARD_2_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_RANK';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_1_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_1_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_1_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_2_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_2_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_2_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_3_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_3_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_3_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_4_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_4_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_4_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_5_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_5_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.BEST_HAND_CARD_5_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.HAND_SHOWING';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRESENTED_BET_OPPORTUNITY';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.MONEY';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.STATE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOURNAMENT_RANK';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.GAMES_PLAYED';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.MAIN_POTS_WON';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.MAIN_POTS_SPLIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.SIDE_POTS_WON';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.SIDE_POTS_SPLIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.AVERAGE_GAME_PROFIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOPS_SEEN';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURNS_SEEN';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVERS_SEEN';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_FOLDS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_FOLDS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_FOLDS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_FOLDS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_FOLDS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_CHECKS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_CHECKS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_CHECKS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_CHECKS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_CHECKS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_CALLS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_CALLS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_CALLS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_CALLS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_CALLS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_BETS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_BETS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_BETS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_BETS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_BETS';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_TOTAL_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_TOTAL_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_TOTAL_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_TOTAL_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_AVERAGE_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_AVERAGE_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_AVERAGE_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_AVERAGE_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.AVERAGE_BET_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_RAISES';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_RAISES';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_RAISES';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_RAISES';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_RAISES';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_TOTAL_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_TOTAL_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_TOTAL_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_TOTAL_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.PRE_FLOP_AVERAGE_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.FLOP_AVERAGE_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TURN_AVERAGE_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.RIVER_AVERAGE_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.AVERAGE_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TIMES_ALL_IN';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_MONEY_PLAYED';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'PLAYER_STATE_ME.TOTAL_MONEY_WON';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'TOURNAMENT_STATE.PLAYER_COUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'TOURNAMENT_STATE.BUY_IN_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'TOURNAMENT_STATE.CURRENT_GAME_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.SMALL_BLIND_SEAT_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.BIG_BLIND_SEAT_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.TURN_SEAT_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.SMALL_BLIND_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.BIG_BLIND_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.BETTING_ROUND_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.LAST_TO_RAISE_SEAT_NUMBER';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.MIN_RAISE_AMOUNT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_1_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_1_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_1_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_2_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_2_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_2_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_3_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_3_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_3_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_4_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_4_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_4_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_5_ID';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_5_SUIT';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'GAME_STATE.COMMUNITY_CARD_5_VALUE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'DECISION_TYPE.CAN_FOLD';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'DECISION_TYPE.CAN_CHECK';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'DECISION_TYPE.CAN_CALL';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'DECISION_TYPE.CAN_BET';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'DECISION_TYPE.CAN_RAISE';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.1';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.2';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.3';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.4';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.5';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.6';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.7';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.8';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 000.9';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 001.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 002.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 003.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 004.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 005.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 006.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 007.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 008.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 009.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 010.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 020.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 030.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 040.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 050.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 060.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 070.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 080.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 090.0';
	v_variable_index := v_variable_index + 1;
	v_strategy_variable_ids(v_variable_index) := 'CONSTANT 100.0';
	v_variable_index := v_variable_index + 1;
	
	v_public_variable_count := v_variable_index - pkg_ga_player.v_strat_chromosome_metadata.expression_slot_id_count;
	
END pkg_strategy_variable;
