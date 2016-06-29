CREATE OR REPLACE PACKAGE BODY pkg_poker_ai AS

PROCEDURE play_tournament(
	p_evolution_trial_id        evolution_trial.trial_id%TYPE,
	p_tournament_id             poker_state_log.tournament_id%TYPE,
	p_strategy_ids              t_tbl_number,
	p_buy_in_amount             poker_state_log.buy_in_amount%TYPE,
	p_initial_small_blind_value poker_state_log.small_blind_value%TYPE,
	p_double_blinds_interval    poker_state_log.current_game_number%TYPE,
	p_perform_state_logging     VARCHAR2
) IS

	v_max_games_in_tournament    poker_state_log.current_game_number%TYPE:= 10000;
	v_prev_iteration_game_number poker_state_log.current_game_number%TYPE;
	v_poker_state                t_poker_state;

BEGIN

	v_poker_state := pkg_poker_ai.initialize_tournament(
		p_tournament_id         => p_tournament_id,
		p_tournament_mode       => 'INTERNAL',
		p_evolution_trial_id    => p_evolution_trial_id,
		p_strategy_ids          => p_strategy_ids,
		p_player_count          => p_strategy_ids.COUNT,
		p_buy_in_amount         => p_buy_in_amount,
		p_perform_state_logging => p_perform_state_logging
	);

	pkg_poker_ai.log(
		p_state_id => v_poker_state.current_state_id,
		p_message  => 'automated tournament initialized'
	);

	v_poker_state.small_blind_value := p_initial_small_blind_value;
	
	LOOP
		
		EXIT WHEN v_poker_state.tournament_in_progress = 'N' OR v_poker_state.current_game_number > v_max_games_in_tournament;
		
		IF v_prev_iteration_game_number != v_poker_state.current_game_number
			AND MOD(v_poker_state.current_game_number, p_double_blinds_interval) = 0 THEN
			v_poker_state.small_blind_value := v_poker_state.small_blind_value * 2;
			IF v_poker_state.small_blind_value > p_buy_in_amount * v_poker_state.player_count THEN
				v_poker_state.small_blind_value := p_buy_in_amount * v_poker_state.player_count;
			END IF;
		END IF;
		v_prev_iteration_game_number := v_poker_state.current_game_number;

		pkg_poker_ai.step_play(
			p_poker_state           => v_poker_state,
			p_player_move           => 'AUTO',
			p_player_move_amount    => NULL,
			p_perform_state_logging => p_perform_state_logging
		);	
	END LOOP;
	
	IF v_poker_state.current_game_number > v_max_games_in_tournament THEN
		pkg_poker_ai.log(
			p_state_id => v_poker_state.current_state_id,
			p_message  => 'maximum number of games in tournament exceeded'
		);
	END IF;

	pkg_poker_ai.log(
		p_state_id => v_poker_state.current_state_id,
		p_message  => 'automated tournament complete'
	);

END play_tournament;

FUNCTION initialize_tournament(
	p_tournament_id         poker_state_log.tournament_id%TYPE,
	p_tournament_mode       poker_state_log.tournament_mode%TYPE,
	p_evolution_trial_id    evolution_trial.trial_id%TYPE,
	p_strategy_ids          t_tbl_number,
	p_player_count          poker_state_log.player_count%TYPE,
    p_buy_in_amount         poker_state_log.buy_in_amount%TYPE,
	p_perform_state_logging VARCHAR2
) RETURN t_poker_state IS

	v_poker_state  t_poker_state;
	v_player_state t_row_player_state;
	v_state_id     poker_ai_log.state_id%TYPE;
	
BEGIN

	IF p_perform_state_logging = 'Y' THEN
		v_state_id := pai_seq_sid.NEXTVAL;
	END IF;
	
	-- init tournament state
	pkg_poker_ai.log(
		p_state_id => v_state_id,
		p_message  => 'initializing ' || LOWER(p_tournament_mode) || ' tournament'
	);

	v_poker_state := t_poker_state(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		t_tbl_player_state(), t_tbl_pot(), t_tbl_pot_contribution(), NULL);
	v_player_state := t_row_player_state(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

	v_poker_state.tournament_id := p_tournament_id;
	v_poker_state.tournament_mode := p_tournament_mode;
	v_poker_state.current_state_id := v_state_id;
	v_poker_state.evolution_trial_id := p_evolution_trial_id;
	v_poker_state.player_count := p_player_count;
	v_poker_state.buy_in_amount := p_buy_in_amount;
	v_poker_state.tournament_in_progress := 'Y';
	v_poker_state.current_game_number := NULL;
	v_poker_state.game_in_progress := 'N';

	-- initialize deck
	v_poker_state.deck := pkg_poker_ai.initialize_deck;
	
	-- init players
	pkg_poker_ai.log(
		p_state_id => v_poker_state.current_state_id,
		p_message  => 'selecting ' || CASE WHEN p_strategy_ids IS NULL THEN 'random' ELSE 'specified strategies as' END || ' players'
	);
	
	FOR v_i IN 1 .. p_player_count LOOP
		v_player_state.seat_number := v_i;
		IF p_strategy_ids IS NOT NULL THEN
			v_player_state.current_strategy_id := p_strategy_ids(v_i).value;
		END IF;
		v_player_state.hand_showing := 'N';
		v_player_state.money := p_buy_in_amount;
		v_player_state.state := 'NO_MOVE';
		v_player_state.presented_bet_opportunity := 'N';
		v_player_state.games_played := 0;
		v_player_state.main_pots_won := 0;
		v_player_state.main_pots_split := 0;
		v_player_state.side_pots_won := 0;
		v_player_state.side_pots_split := 0;
		v_player_state.flops_seen := 0;
		v_player_state.turns_seen := 0;
		v_player_state.rivers_seen := 0;
		v_player_state.pre_flop_folds := 0;
		v_player_state.flop_folds := 0;
		v_player_state.turn_folds := 0;
		v_player_state.river_folds := 0;
		v_player_state.total_folds := 0;
		v_player_state.pre_flop_checks := 0;
		v_player_state.flop_checks := 0;
		v_player_state.turn_checks := 0;
		v_player_state.river_checks := 0;
		v_player_state.total_checks := 0;
		v_player_state.pre_flop_calls := 0;
		v_player_state.flop_calls := 0;
		v_player_state.turn_calls := 0;
		v_player_state.river_calls := 0;
		v_player_state.total_calls := 0;
		v_player_state.pre_flop_bets := 0;
		v_player_state.flop_bets := 0;
		v_player_state.turn_bets := 0;
		v_player_state.river_bets := 0;
		v_player_state.total_bets := 0;
		v_player_state.pre_flop_total_bet_amount := 0;
		v_player_state.flop_total_bet_amount := 0;
		v_player_state.turn_total_bet_amount := 0;
		v_player_state.river_total_bet_amount := 0;
		v_player_state.total_bet_amount := 0;
		v_player_state.pre_flop_raises := 0;
		v_player_state.flop_raises := 0;
		v_player_state.turn_raises := 0;
		v_player_state.river_raises := 0;
		v_player_state.total_raises := 0;
		v_player_state.pre_flop_total_raise_amount := 0;
		v_player_state.flop_total_raise_amount := 0;
		v_player_state.turn_total_raise_amount := 0;
		v_player_state.river_total_raise_amount := 0;
		v_player_state.total_raise_amount := 0;
		v_player_state.times_all_in := 0;
		v_player_state.total_money_played := 0;
		v_player_state.total_money_won := 0;
		v_poker_state.player_state.EXTEND(1);
		v_poker_state.player_state(v_i) := v_player_state;
	END LOOP;

	pkg_poker_ai.log(
		p_state_id => v_poker_state.current_state_id,
		p_message  => 'tournament initialized'
	);
	
	IF p_perform_state_logging = 'Y' THEN
		pkg_poker_ai.capture_state_log(p_poker_state => v_poker_state);
	END IF;
	
	RETURN v_poker_state;
		
END initialize_tournament;

FUNCTION initialize_deck RETURN t_tbl_deck IS

	v_deck t_tbl_deck := t_tbl_deck();

BEGIN

	v_deck.EXTEND(53);
	v_deck(1) := t_row_deck(0, NULL, 'N/A', NULL, 'N');
	v_deck(2) := t_row_deck(1, 'HEARTS', '2 H', 2, 'N');
	v_deck(3) := t_row_deck(2, 'HEARTS', '3 H', 3, 'N');
	v_deck(4) := t_row_deck(3, 'HEARTS', '4 H', 4, 'N');
	v_deck(5) := t_row_deck(4, 'HEARTS', '5 H', 5, 'N');
	v_deck(6) := t_row_deck(5, 'HEARTS', '6 H', 6, 'N');
	v_deck(7) := t_row_deck(6, 'HEARTS', '7 H', 7, 'N');
	v_deck(8) := t_row_deck(7, 'HEARTS', '8 H', 8, 'N');
	v_deck(9) := t_row_deck(8, 'HEARTS', '9 H', 9, 'N');
	v_deck(10) := t_row_deck(9, 'HEARTS', '10 H', 10, 'N');
	v_deck(11) := t_row_deck(10, 'HEARTS', 'J H', 11, 'N');
	v_deck(12) := t_row_deck(11, 'HEARTS', 'Q H', 12, 'N');
	v_deck(13) := t_row_deck(12, 'HEARTS', 'K H', 13, 'N');
	v_deck(14) := t_row_deck(13, 'HEARTS', 'A H', 14, 'N');
	v_deck(15) := t_row_deck(14, 'DIAMONDS', '2 D', 2, 'N');
	v_deck(16) := t_row_deck(15, 'DIAMONDS', '3 D', 3, 'N');
	v_deck(17) := t_row_deck(16, 'DIAMONDS', '4 D', 4, 'N');
	v_deck(18) := t_row_deck(17, 'DIAMONDS', '5 D', 5, 'N');
	v_deck(19) := t_row_deck(18, 'DIAMONDS', '6 D', 6, 'N');
	v_deck(20) := t_row_deck(19, 'DIAMONDS', '7 D', 7, 'N');
	v_deck(21) := t_row_deck(20, 'DIAMONDS', '8 D', 8, 'N');
	v_deck(22) := t_row_deck(21, 'DIAMONDS', '9 D', 9, 'N');
	v_deck(23) := t_row_deck(22, 'DIAMONDS', '10 D', 10, 'N');
	v_deck(24) := t_row_deck(23, 'DIAMONDS', 'J D', 11, 'N');
	v_deck(25) := t_row_deck(24, 'DIAMONDS', 'Q D', 12, 'N');
	v_deck(26) := t_row_deck(25, 'DIAMONDS', 'K D', 13, 'N');
	v_deck(27) := t_row_deck(26, 'DIAMONDS', 'A D', 14, 'N');
	v_deck(28) := t_row_deck(27, 'SPADES', '2 S', 2, 'N');
	v_deck(29) := t_row_deck(28, 'SPADES', '3 S', 3, 'N');
	v_deck(30) := t_row_deck(29, 'SPADES', '4 S', 4, 'N');
	v_deck(31) := t_row_deck(30, 'SPADES', '5 S', 5, 'N');
	v_deck(32) := t_row_deck(31, 'SPADES', '6 S', 6, 'N');
	v_deck(33) := t_row_deck(32, 'SPADES', '7 S', 7, 'N');
	v_deck(34) := t_row_deck(33, 'SPADES', '8 S', 8, 'N');
	v_deck(35) := t_row_deck(34, 'SPADES', '9 S', 9, 'N');
	v_deck(36) := t_row_deck(35, 'SPADES', '10 S', 10, 'N');
	v_deck(37) := t_row_deck(36, 'SPADES', 'J S', 11, 'N');
	v_deck(38) := t_row_deck(37, 'SPADES', 'Q S', 12, 'N');
	v_deck(39) := t_row_deck(38, 'SPADES', 'K S', 13, 'N');
	v_deck(40) := t_row_deck(39, 'SPADES', 'A S', 14, 'N');
	v_deck(41) := t_row_deck(40, 'CLUBS', '2 C', 2, 'N');
	v_deck(42) := t_row_deck(41, 'CLUBS', '3 C', 3, 'N');
	v_deck(43) := t_row_deck(42, 'CLUBS', '4 C', 4, 'N');
	v_deck(44) := t_row_deck(43, 'CLUBS', '5 C', 5, 'N');
	v_deck(45) := t_row_deck(44, 'CLUBS', '6 C', 6, 'N');
	v_deck(46) := t_row_deck(45, 'CLUBS', '7 C', 7, 'N');
	v_deck(47) := t_row_deck(46, 'CLUBS', '8 C', 8, 'N');
	v_deck(48) := t_row_deck(47, 'CLUBS', '9 C', 9, 'N');
	v_deck(49) := t_row_deck(48, 'CLUBS', '10 C', 10, 'N');
	v_deck(50) := t_row_deck(49, 'CLUBS', 'J C', 11, 'N');
	v_deck(51) := t_row_deck(50, 'CLUBS', 'Q C', 12, 'N');
	v_deck(52) := t_row_deck(51, 'CLUBS', 'K C', 13, 'N');
	v_deck(53) := t_row_deck(52, 'CLUBS', 'A C', 14, 'N');
	
	RETURN v_deck;
	
END initialize_deck;

PROCEDURE step_play(
	p_poker_state           IN OUT t_poker_state,
	p_player_move           VARCHAR2,
	p_player_move_amount    player_state_log.money%TYPE,
	p_perform_state_logging VARCHAR2
) IS

	v_remaining_player_count poker_state_log.player_count%TYPE := 0;
	v_uneven_pot             VARCHAR2(1) := 'N';
	v_bet_opp_not_presented  player_state_log.presented_bet_opportunity%TYPE := 'N';

BEGIN

	-- assumed tournament has been initialized
	IF p_perform_state_logging = 'Y' THEN
		p_poker_state.current_state_id := pai_seq_sid.NEXTVAL;
	END IF;
	
	-- determine how many active players remain
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).state != 'OUT_OF_TOURNAMENT' THEN
			v_remaining_player_count := v_remaining_player_count + 1;
		END IF;
	END LOOP;
		
	IF v_remaining_player_count > 1 THEN
		
		IF p_poker_state.game_in_progress = 'N' THEN

			-- start a new game
			IF p_poker_state.current_game_number IS NULL THEN
				p_poker_state.small_blind_seat_number := 1;
			ELSE
				pkg_poker_ai.log(
					p_state_id => p_poker_state.current_state_id,
					p_message  => 'advancing small blind seat'
				);
				p_poker_state.small_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(
					p_poker_state                => p_poker_state,
					p_current_player_seat_number => p_poker_state.small_blind_seat_number,
					p_include_folded_players     => 'Y',
					p_include_all_in_players     => 'Y'
				);
			END IF;

			pkg_poker_ai.initialize_game(p_poker_state => p_poker_state);
			p_poker_state.current_game_number := NVL(p_poker_state.current_game_number, 0) + 1;
			p_poker_state.game_in_progress := 'Y';
			
		ELSE

			-- game is currently in progress

			IF p_poker_state.betting_round_in_progress = 'N' THEN

				-- no betting round currently in progress, start new betting round or enter showdown

				IF p_poker_state.betting_round_number IS NULL THEN
					-- pre-flop betting round, post blinds
					pkg_poker_ai.post_blinds(p_poker_state => p_poker_state);

					-- deal hole cards
					pkg_poker_ai.log(p_state_id => p_poker_state.current_state_id, p_message => 'dealing hole cards');
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state != 'OUT_OF_TOURNAMENT' THEN
							IF p_poker_state.tournament_mode = 'INTERNAL' THEN
								p_poker_state.player_state(v_i).hole_card_1 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
								p_poker_state.player_state(v_i).hole_card_2 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
							ELSE
								p_poker_state.player_state(v_i).hole_card_1 := 0;
								p_poker_state.player_state(v_i).hole_card_2 := 0;
							END IF;
							p_poker_state.player_state(v_i).games_played := p_poker_state.player_state(v_i).games_played + 1;
						END IF;
					END LOOP;
					
				ELSIF p_poker_state.betting_round_number = 1 THEN
					-- reset player state
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'resetting player state'
					);
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT') THEN
							IF p_poker_state.player_state(v_i).state != 'ALL_IN' THEN
								p_poker_state.player_state(v_i).state := 'NO_MOVE';
								p_poker_state.player_state(v_i).presented_bet_opportunity := 'N';
							END IF;
							p_poker_state.player_state(v_i).flops_seen := p_poker_state.player_state(v_i).flops_seen + 1;
						END IF;
					END LOOP;
				
					-- reset player turn
					pkg_poker_ai.init_betting_round_start_seat(p_poker_state => p_poker_state);

					-- deal flop
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'dealing flop'
					);
					IF p_poker_state.tournament_mode = 'INTERNAL' THEN
						p_poker_state.community_card_1 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
						p_poker_state.community_card_2 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
						p_poker_state.community_card_3 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
					ELSE
						p_poker_state.community_card_1 := 0;
						p_poker_state.community_card_2 := 0;
						p_poker_state.community_card_3 := 0;
					END IF;

					pkg_poker_ai.calculate_best_hands(p_poker_state => p_poker_state);
					pkg_poker_ai.sort_hands(p_poker_state => p_poker_state);

				ELSIF p_poker_state.betting_round_number = 2 THEN
					-- reset player state
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'resetting player state'
					);
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT') THEN
							IF p_poker_state.player_state(v_i).state != 'ALL_IN' THEN
								p_poker_state.player_state(v_i).state := 'NO_MOVE';
								p_poker_state.player_state(v_i).presented_bet_opportunity := 'N';
							END IF;
							p_poker_state.player_state(v_i).turns_seen := p_poker_state.player_state(v_i).turns_seen + 1;
						END IF;
					END LOOP;

					-- reset player turn
					pkg_poker_ai.init_betting_round_start_seat(p_poker_state => p_poker_state);
					
					-- deal turn
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'dealing turn'
					);
					IF p_poker_state.tournament_mode = 'INTERNAL' THEN
						p_poker_state.community_card_4 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
					ELSE
						p_poker_state.community_card_4 := 0;
					END IF;

					pkg_poker_ai.calculate_best_hands(p_poker_state => p_poker_state);
					pkg_poker_ai.sort_hands(p_poker_state => p_poker_state);

				ELSIF p_poker_state.betting_round_number = 3 THEN
					-- reset player state
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'resetting player state'
					);
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT') THEN
							IF p_poker_state.player_state(v_i).state != 'ALL_IN' THEN
								p_poker_state.player_state(v_i).state := 'NO_MOVE';
								p_poker_state.player_state(v_i).presented_bet_opportunity := 'N';
							END IF;
							p_poker_state.player_state(v_i).rivers_seen := p_poker_state.player_state(v_i).rivers_seen + 1;
						END IF;
					END LOOP;

					-- reset player turn
					pkg_poker_ai.init_betting_round_start_seat(p_poker_state => p_poker_state);

					-- deal river
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'dealing river'
					);
					IF p_poker_state.tournament_mode = 'INTERNAL' THEN
						p_poker_state.community_card_5 := pkg_poker_ai.draw_deck_card(p_poker_state => p_poker_state);
					ELSE
						p_poker_state.community_card_5 := 0;
					END IF;

					pkg_poker_ai.calculate_best_hands(p_poker_state => p_poker_state);
					pkg_poker_ai.sort_hands(p_poker_state => p_poker_state);

				ELSIF p_poker_state.betting_round_number = 4 THEN
					
					-- showdown
					pkg_poker_ai.process_game_results(p_poker_state => p_poker_state);
					p_poker_state.betting_round_number := NULL;
					p_poker_state.betting_round_in_progress := 'N';
					pkg_poker_ai.sort_hands(p_poker_state => p_poker_state);

				END IF;

				-- update to indicate betting round in progress
				IF p_poker_state.betting_round_number IS NULL OR p_poker_state.betting_round_number != 4 THEN
					p_poker_state.betting_round_number := NVL(p_poker_state.betting_round_number, 0) + 1;
					p_poker_state.betting_round_in_progress := 'Y';
						   
					-- if no players can make a move, explicitly state that to the log
					IF p_poker_state.turn_seat_number IS NULL THEN
						pkg_poker_ai.log(
							p_state_id => p_poker_state.current_state_id,
							p_message  => 'no players can make move'
						);
					END IF;
					
				END IF;

			ELSE

				-- betting round is in progress, let player make move
				IF p_poker_state.turn_seat_number IS NOT NULL THEN
					p_poker_state.player_state(p_poker_state.turn_seat_number).presented_bet_opportunity := 'Y';
					pkg_poker_ai.perform_player_move(
						p_poker_state        => p_poker_state,
						p_player_move        => p_player_move,
						p_player_move_amount => p_player_move_amount
					);
				END IF;

				IF pkg_poker_ai.get_active_player_count(p_poker_state => p_poker_state) <= 1 THEN
					-- all players but one folded
					pkg_poker_ai.process_game_results(p_poker_state => p_poker_state);
				ELSE
					-- if the pots aren't even excluding all-in players, allow betting to continue
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state != 'ALL_IN'
							AND pkg_poker_ai.get_pot_deficit(
								p_poker_state => p_poker_state,
								p_seat_number => p_poker_state.player_state(v_i).seat_number
							) > 0 THEN
							v_uneven_pot := 'Y';
							EXIT;
						END IF;
					END LOOP;

					-- if anyone has not been presented the opportunity to bet, proceed with betting
					FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
						IF p_poker_state.player_state(v_i).state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN')
							AND p_poker_state.player_state(v_i).presented_bet_opportunity = 'N' THEN
							v_bet_opp_not_presented := 'Y';
							EXIT;
						END IF;
					END LOOP;
				
					IF v_uneven_pot = 'Y' OR v_bet_opp_not_presented = 'Y' THEN
						-- betting continues, advance player
						p_poker_state.turn_seat_number := pkg_poker_ai.get_next_active_seat_number(
							p_poker_state                => p_poker_state,
							p_current_player_seat_number => p_poker_state.turn_seat_number,
							p_include_folded_players     => 'N',
							p_include_all_in_players     => 'N'
						);
					ELSE
						-- betting round over
						pkg_poker_ai.log(
							p_state_id => p_poker_state.current_state_id,
							p_message  => 'betting round over'
						);
						p_poker_state.betting_round_in_progress := 'N';					
					END IF;

				END IF;

			END IF;

		END IF;

	ELSE
	
		-- only one active player remains, process tournament results
		pkg_poker_ai.process_tournament_results(p_poker_state => p_poker_state);
		
	END IF;
	
	IF p_perform_state_logging = 'Y' THEN
		pkg_poker_ai.capture_state_log(p_poker_state => p_poker_state);
	END IF;
	
END step_play;

PROCEDURE initialize_game(
	p_poker_state IN OUT t_poker_state
) IS
BEGIN

	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'initializing game start'
	);

	-- clear pots
	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'clearing pots'
	);
	p_poker_state.pot_contribution.DELETE;
	p_poker_state.pot.DELETE;

	-- reset deck
	pkg_poker_ai.log(p_state_id => p_poker_state.current_state_id, p_message => 'resetting deck');
	FOR v_i IN p_poker_state.deck.FIRST .. p_poker_state.deck.LAST LOOP
		p_poker_state.deck(v_i).dealt := 'N';
	END LOOP;

	-- initialize player state
	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'clearing player state cards and game rank'
	);
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		p_poker_state.player_state(v_i).hole_card_1 := NULL;
		p_poker_state.player_state(v_i).hole_card_2 := NULL;
		p_poker_state.player_state(v_i).best_hand_combination := NULL;
		p_poker_state.player_state(v_i).best_hand_rank := NULL;
		p_poker_state.player_state(v_i).best_hand_card_1 := NULL;
		p_poker_state.player_state(v_i).best_hand_card_2 := NULL;
		p_poker_state.player_state(v_i).best_hand_card_3 := NULL;
		p_poker_state.player_state(v_i).best_hand_card_4 := NULL;
		p_poker_state.player_state(v_i).best_hand_card_5 := NULL;
		p_poker_state.player_state(v_i).hand_showing := 'N';
		p_poker_state.player_state(v_i).presented_bet_opportunity := 'N';
		p_poker_state.player_state(v_i).game_rank := NULL;

		IF p_poker_state.player_state(v_i).state != 'OUT_OF_TOURNAMENT' THEN
			p_poker_state.player_state(v_i).state := 'NO_MOVE';
		END IF;
	END LOOP;

	-- determine seats
	p_poker_state.big_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_poker_state                => p_poker_state,
		p_current_player_seat_number => p_poker_state.small_blind_seat_number,
		p_include_folded_players     => 'Y',
		p_include_all_in_players     => 'Y'
	);
	p_poker_state.turn_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_poker_state                => p_poker_state,
		p_current_player_seat_number => p_poker_state.big_blind_seat_number,
		p_include_folded_players     => 'Y',
		p_include_all_in_players     => 'Y'
	);
	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'small blind = ' || p_poker_state.small_blind_seat_number
			|| ', big blind = ' || p_poker_state.big_blind_seat_number
			|| ', UTG = ' || p_poker_state.turn_seat_number
	);

	-- initialize game state
	p_poker_state.betting_round_number := NULL;
	p_poker_state.betting_round_in_progress := 'N';
	p_poker_state.big_blind_value := p_poker_state.small_blind_value * 2;
	p_poker_state.min_raise_amount := p_poker_state.big_blind_value;
	p_poker_state.last_to_raise_seat_number := NULL;
	p_poker_state.community_card_1 := NULL;
    p_poker_state.community_card_2 := NULL;
    p_poker_state.community_card_3 := NULL;
    p_poker_state.community_card_4 := NULL;
    p_poker_state.community_card_5 := NULL;

	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'game initialized'
	);
   
END initialize_game;

FUNCTION get_active_player_count(
	p_poker_state t_poker_state
) RETURN poker_state_log.player_count%TYPE IS

	v_active_players poker_state_log.player_count%TYPE := 0;

BEGIN

	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED') THEN
			v_active_players := v_active_players + 1;
		END IF;
	END LOOP;
	
	RETURN v_active_players;

END get_active_player_count;

FUNCTION get_next_active_seat_number(
	p_poker_state                t_poker_state,
	p_current_player_seat_number player_state_log.seat_number%TYPE,
	p_include_folded_players     VARCHAR2,
	p_include_all_in_players     VARCHAR2
) RETURN player_state_log.seat_number%TYPE IS

	v_next_player_seat_number player_state_log.seat_number%TYPE;

BEGIN

	-- get the seat number of the next active player clockwise of current player
	SELECT MIN(seat_number) next_player_seat_number
	INTO   v_next_player_seat_number
	FROM   TABLE(p_poker_state.player_state)
	WHERE  seat_number > p_current_player_seat_number
	   AND state != 'OUT_OF_TOURNAMENT'
	   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END
	   AND state != CASE WHEN p_include_all_in_players = 'N' THEN 'ALL_IN' ELSE '-X-' END;

	IF v_next_player_seat_number IS NULL THEN
		SELECT MIN(seat_number) next_player_seat_number
		INTO   v_next_player_seat_number
		FROM   TABLE(p_poker_state.player_state)
		WHERE  seat_number < p_current_player_seat_number
		   AND state != 'OUT_OF_TOURNAMENT'
		   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END
		   AND state != CASE WHEN p_include_all_in_players = 'N' THEN 'ALL_IN' ELSE '-X-' END;
	END IF;

	RETURN v_next_player_seat_number;
	
END get_next_active_seat_number;

PROCEDURE init_betting_round_start_seat(
	p_poker_state IN OUT t_poker_state
) IS

	v_starting_seat player_state_log.seat_number%TYPE;
	
BEGIN

	-- get the seat number of the next active player clockwise of dealer
	SELECT MIN(seat_number) starting_seat
	INTO   v_starting_seat
	FROM   TABLE(p_poker_state.player_state)
	WHERE  seat_number >= p_poker_state.small_blind_seat_number
	   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');

	IF v_starting_seat IS NULL THEN
		SELECT MIN(seat_number) starting_seat
		INTO   v_starting_seat
		FROM   TABLE(p_poker_state.player_state)
		WHERE  seat_number < p_poker_state.small_blind_seat_number
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');
	END IF;

	p_poker_state.turn_seat_number := v_starting_seat;

END init_betting_round_start_seat;

FUNCTION get_distance_from_small_blind(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN INTEGER IS
BEGIN

	IF p_seat_number >= p_poker_state.small_blind_seat_number THEN
		RETURN p_seat_number - p_poker_state.small_blind_seat_number;
	ELSE
		RETURN (p_seat_number + p_poker_state.player_count) - p_poker_state.small_blind_seat_number;
	END IF;
	
END get_distance_from_small_blind;

FUNCTION draw_deck_card(
	p_poker_state IN OUT t_poker_state
) RETURN poker_state_log.community_card_1%TYPE IS

	v_drawn_card_id poker_state_log.community_card_1%TYPE;

BEGIN

	-- draw a non-played card at random, mark as in play
	WITH remaining_deck AS (
		SELECT card_id
		FROM   TABLE(p_poker_state.deck)
		WHERE  card_id != 0
		   AND dealt = 'N'
		ORDER BY DBMS_RANDOM.VALUE
	)
	SELECT card_id
	INTO   v_drawn_card_id
	FROM   remaining_deck
	WHERE  ROWNUM = 1;

	FOR v_i IN p_poker_state.deck.FIRST .. p_poker_state.deck.LAST LOOP
		IF p_poker_state.deck(v_i).card_id = v_drawn_card_id THEN
			p_poker_state.deck(v_i).dealt := 'Y';
			EXIT;
		END IF;
	END LOOP;
	
	RETURN v_drawn_card_id;

END draw_deck_card;

PROCEDURE post_blinds(
	p_poker_state IN OUT t_poker_state
) IS

	v_small_blind_player_money player_state_log.money%TYPE;
	v_small_blind_post_amount  poker_state_log.small_blind_value%TYPE;
	v_big_blind_player_money   player_state_log.money%TYPE;
	v_big_blind_post_amount    poker_state_log.big_blind_value%TYPE;

BEGIN

	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'posting blinds'
	);

	-- post small blind
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).seat_number = p_poker_state.small_blind_seat_number THEN
			v_small_blind_player_money := p_poker_state.player_state(v_i).money;
			EXIT;
		END IF;
	END LOOP;

	IF v_small_blind_player_money - p_poker_state.small_blind_value < 0 THEN
		v_small_blind_post_amount := v_small_blind_player_money;
	ELSE
		v_small_blind_post_amount := p_poker_state.small_blind_value;
	END IF;

	pkg_poker_ai.contribute_to_pot(
		p_poker_state        => p_poker_state,
		p_player_seat_number => p_poker_state.small_blind_seat_number,
		p_pot_contribution   => v_small_blind_post_amount
	);
	
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).seat_number = p_poker_state.small_blind_seat_number THEN
			p_poker_state.player_state(v_i).pre_flop_bets := p_poker_state.player_state(v_i).pre_flop_bets + 1;
			p_poker_state.player_state(v_i).total_bets := p_poker_state.player_state(v_i).total_bets + 1;
			p_poker_state.player_state(v_i).pre_flop_total_bet_amount :=
				p_poker_state.player_state(v_i).pre_flop_total_bet_amount + v_small_blind_post_amount;
			p_poker_state.player_state(v_i).total_bet_amount :=
				p_poker_state.player_state(v_i).total_bet_amount + v_small_blind_post_amount;
			p_poker_state.player_state(v_i).pre_flop_average_bet_amount :=
				p_poker_state.player_state(v_i).pre_flop_total_bet_amount
				/ NULLIF(p_poker_state.player_state(v_i).pre_flop_bets, 0);
			p_poker_state.player_state(v_i).average_bet_amount :=
				p_poker_state.player_state(v_i).total_bet_amount
				/ NULLIF(p_poker_state.player_state(v_i).total_bets, 0);
			EXIT;
		END IF;
	END LOOP;

	-- post big blind
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).seat_number = p_poker_state.big_blind_seat_number THEN
			v_big_blind_player_money := p_poker_state.player_state(v_i).money;
			EXIT;
		END IF;
	END LOOP;

	IF v_big_blind_player_money - p_poker_state.big_blind_value < 0 THEN
		v_big_blind_post_amount := v_big_blind_player_money;
	ELSE
		v_big_blind_post_amount := p_poker_state.big_blind_value;
	END IF;

	pkg_poker_ai.contribute_to_pot(
		p_poker_state        => p_poker_state,
		p_player_seat_number => p_poker_state.big_blind_seat_number,
		p_pot_contribution   => v_big_blind_post_amount
	);

	IF v_big_blind_post_amount - v_small_blind_post_amount > 0 THEN
		FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
			IF p_poker_state.player_state(v_i).seat_number = p_poker_state.big_blind_seat_number THEN
				p_poker_state.player_state(v_i).pre_flop_raises := p_poker_state.player_state(v_i).pre_flop_raises + 1;
				p_poker_state.player_state(v_i).total_raises := p_poker_state.player_state(v_i).total_raises + 1;
				p_poker_state.player_state(v_i).pre_flop_total_raise_amount :=
					p_poker_state.player_state(v_i).pre_flop_total_raise_amount + (v_big_blind_post_amount - v_small_blind_post_amount);
				p_poker_state.player_state(v_i).total_raise_amount :=
					p_poker_state.player_state(v_i).total_raise_amount + (v_big_blind_post_amount - v_small_blind_post_amount);
				p_poker_state.player_state(v_i).pre_flop_average_raise_amount :=
					p_poker_state.player_state(v_i).pre_flop_total_raise_amount
					/ NULLIF(p_poker_state.player_state(v_i).pre_flop_raises, 0);
				p_poker_state.player_state(v_i).average_raise_amount :=
					p_poker_state.player_state(v_i).total_raise_amount
					/ NULLIF(p_poker_state.player_state(v_i).total_raises, 0);
				EXIT;
			END IF;
		END LOOP;
	END IF;
	
END post_blinds;

PROCEDURE perform_player_move(
	p_poker_state        IN OUT t_poker_state,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
) IS
BEGIN

	IF p_player_move = 'AUTO' THEN
		pkg_ga_player.perform_automatic_player_move(p_poker_state => p_poker_state);
	ELSE
		pkg_poker_ai.perform_explicit_player_move(
			p_poker_state        => p_poker_state,
			p_player_move        => p_player_move,
			p_player_move_amount => p_player_move_amount
		);
	END IF;
	
END perform_player_move;

PROCEDURE perform_explicit_player_move(
	p_poker_state        IN OUT t_poker_state,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state_log.money%TYPE
) IS
BEGIN

	IF p_player_move = 'FOLD' THEN
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'player at seat ' || p_poker_state.turn_seat_number || ' folds'
		);
		p_poker_state.player_state(p_poker_state.turn_seat_number).state := 'FOLDED';
		IF p_poker_state.betting_round_number = 1 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_folds :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_folds + 1;
		ELSIF p_poker_state.betting_round_number = 2 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_folds :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_folds + 1;
		ELSIF p_poker_state.betting_round_number = 3 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_folds :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_folds + 1;
		ELSIF p_poker_state.betting_round_number = 4 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_folds :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_folds + 1;
		END IF;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_folds :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_folds + 1;
		
		pkg_poker_ai.issue_applicable_pot_refunds(p_poker_state => p_poker_state);
		pkg_poker_ai.issue_default_pot_wins(p_poker_state => p_poker_state);
	
	ELSIF p_player_move = 'CHECK' THEN
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'player at seat ' || p_poker_state.turn_seat_number || ' checks'
		);
		IF p_poker_state.player_state(p_poker_state.turn_seat_number).state != 'ALL_IN' THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).state:= 'CHECKED';
		END IF;
		IF p_poker_state.betting_round_number = 1 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_checks :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_checks + 1;
		ELSIF p_poker_state.betting_round_number = 2 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_checks :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_checks + 1;
		ELSIF p_poker_state.betting_round_number = 3 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_checks :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_checks + 1;
		ELSIF p_poker_state.betting_round_number = 4 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_checks :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_checks + 1;
		END IF;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_checks :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_checks + 1;
		
	ELSIF p_player_move = 'CALL' THEN
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'player at seat ' || p_poker_state.turn_seat_number || ' calls'
		);
		pkg_poker_ai.contribute_to_pot(
			p_poker_state        => p_poker_state,
			p_player_seat_number => p_poker_state.turn_seat_number,
			p_pot_contribution   => LEAST(p_poker_state.player_state(p_poker_state.turn_seat_number).money,
				pkg_poker_ai.get_pot_deficit(
					p_poker_state => p_poker_state,
					p_seat_number => p_poker_state.turn_seat_number
				))
		);

		IF p_poker_state.player_state(p_poker_state.turn_seat_number).state != 'ALL_IN' THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).state:= 'CALLED';
		END IF;
		IF p_poker_state.betting_round_number = 1 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_calls :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_calls + 1;
		ELSIF p_poker_state.betting_round_number = 2 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_calls :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_calls + 1;
		ELSIF p_poker_state.betting_round_number = 3 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_calls :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_calls + 1;
		ELSIF p_poker_state.betting_round_number = 4 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_calls :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_calls + 1;
		END IF;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_calls :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_calls + 1;

	ELSIF p_player_move = 'BET' THEN
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'player at seat ' || p_poker_state.turn_seat_number || ' bets ' || p_player_move_amount
		);
		pkg_poker_ai.contribute_to_pot(
			p_poker_state        => p_poker_state,
			p_player_seat_number => p_poker_state.turn_seat_number,
			p_pot_contribution   => p_player_move_amount
		);

		IF p_poker_state.player_state(p_poker_state.turn_seat_number).state != 'ALL_IN' THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).state:= 'BET';
		END IF;
		IF p_poker_state.betting_round_number = 1 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_bets :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_bets + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_bet_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_average_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_bet_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_bets, 0);
		ELSIF p_poker_state.betting_round_number = 2 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_bets :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_bets + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_bet_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_average_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_bet_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).flop_bets, 0);
		ELSIF p_poker_state.betting_round_number = 3 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_bets :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_bets + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_bet_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_average_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_bet_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).turn_bets, 0);
		ELSIF p_poker_state.betting_round_number = 4 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_bets :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_bets + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_bet_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_average_bet_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_bet_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).river_bets, 0);
		END IF;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_bets :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_bets + 1;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_bet_amount :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_bet_amount + p_player_move_amount;
		p_poker_state.player_state(p_poker_state.turn_seat_number).average_bet_amount :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_bet_amount
			/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).total_bets, 0);
		
		p_poker_state.last_to_raise_seat_number := p_poker_state.turn_seat_number;
		p_poker_state.min_raise_amount := CASE
			WHEN p_player_move_amount < p_poker_state.min_raise_amount THEN p_poker_state.min_raise_amount + p_player_move_amount
			ELSE p_player_move_amount
		END;
	
	ELSIF p_player_move = 'RAISE' THEN
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'player at seat ' || p_poker_state.turn_seat_number || ' raises ' || p_player_move_amount
		);
		pkg_poker_ai.contribute_to_pot(
			p_poker_state        => p_poker_state,
			p_player_seat_number => p_poker_state.turn_seat_number,
			p_pot_contribution   => pkg_poker_ai.get_pot_deficit(
				p_poker_state => p_poker_state,
				p_seat_number => p_poker_state.turn_seat_number
			) + p_player_move_amount
		);
			
		IF p_poker_state.player_state(p_poker_state.turn_seat_number).state != 'ALL_IN' THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).state:= 'RAISED';
		END IF;
		IF p_poker_state.betting_round_number = 1 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_raises :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_raises + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_raise_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_average_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_total_raise_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).pre_flop_raises, 0);
		ELSIF p_poker_state.betting_round_number = 2 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_raises :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_raises + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_raise_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).flop_average_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).flop_total_raise_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).flop_raises, 0);
		ELSIF p_poker_state.betting_round_number = 3 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_raises :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_raises + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_raise_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).turn_average_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).turn_total_raise_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).turn_raises, 0);
		ELSIF p_poker_state.betting_round_number = 4 THEN
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_raises :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_raises + 1;
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_raise_amount + p_player_move_amount;
			p_poker_state.player_state(p_poker_state.turn_seat_number).river_average_raise_amount :=
				p_poker_state.player_state(p_poker_state.turn_seat_number).river_total_raise_amount
				/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).river_raises, 0);
		END IF;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_raises :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_raises + 1;
		p_poker_state.player_state(p_poker_state.turn_seat_number).total_raise_amount :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_raise_amount + p_player_move_amount;
		p_poker_state.player_state(p_poker_state.turn_seat_number).average_raise_amount :=
			p_poker_state.player_state(p_poker_state.turn_seat_number).total_raise_amount
			/ NULLIF(p_poker_state.player_state(p_poker_state.turn_seat_number).total_raises, 0);
				
		p_poker_state.last_to_raise_seat_number := p_poker_state.turn_seat_number;
		p_poker_state.min_raise_amount := CASE
			WHEN p_player_move_amount < p_poker_state.min_raise_amount THEN p_poker_state.min_raise_amount + p_player_move_amount
			ELSE p_player_move_amount
		END;
	
	END IF;
	
END perform_explicit_player_move;

FUNCTION get_player_showdown_muck(
	p_seat_number player_state_log.seat_number%TYPE
) RETURN BOOLEAN IS
BEGIN
	
	RETURN FALSE;
	--pkg_poker_ai.log(
	--	p_state_id => p_poker_state.current_state_id,
	--	p_message  => 'player at seat ' || p_seat_number || ' chooses not to show cards'
	--);

END get_player_showdown_muck;

PROCEDURE process_game_results(
	p_poker_state IN OUT t_poker_state
) IS

	v_active_player_count       INTEGER;
	v_winner_seat_number        player_state_log.seat_number%TYPE;
	v_winnings                  player_state_log.money%TYPE := 0;
	v_first_to_show_seat_number player_state_log.seat_number%TYPE;
	v_tournament_rank           player_state_log.tournament_rank%TYPE;

BEGIN

	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'processing game results'
	);

	SELECT COUNT(*) active_player_count,
		   CASE WHEN COUNT(*) = 1 THEN MIN(seat_number) END winner_seat_number
	INTO   v_active_player_count,
		   v_winner_seat_number
	FROM   TABLE(p_poker_state.player_state)
	WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED');

	IF v_active_player_count = 1 THEN
		-- everyone but one player folded
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'all but one player folded, winning seat is ' || v_winner_seat_number
		);
		SELECT SUM(pot_contribution) winnings
		INTO   v_winnings
		FROM   TABLE(p_poker_state.pot_contribution);
		p_poker_state.player_state(v_winner_seat_number).money := p_poker_state.player_state(v_winner_seat_number).money + v_winnings;
		p_poker_state.player_state(v_winner_seat_number).game_rank := 1;
		p_poker_state.player_state(v_winner_seat_number).main_pots_won :=
			p_poker_state.player_state(v_winner_seat_number).main_pots_won + 1;
		p_poker_state.player_state(v_winner_seat_number).total_money_won :=
			p_poker_state.player_state(v_winner_seat_number).total_money_won + v_winnings;
		
	ELSE

		-- showdown
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'starting showdown'
		);

		-- for every player in the showdown, determine best possible hand
		pkg_poker_ai.calculate_best_hands(p_poker_state => p_poker_state);
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'active players best possible hand determined'
		);

		-- Best hand for each player has been determined, compare players
		-- Last player to bet or raise on the river round must show first.
		-- If everyone checked, first player left of dealer shows first.
		v_first_to_show_seat_number := NVL(p_poker_state.last_to_raise_seat_number, p_poker_state.small_blind_seat_number);

		FOR v_player_rec IN (
			WITH participating_seats AS (
				SELECT seat_number
				FROM   TABLE(p_poker_state.player_state)
				WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
			),
			
			max_seat_number AS (
				SELECT MAX(seat_number) max_seat_number
				FROM   participating_seats
			)
			
			SELECT ps.seat_number,
				   CASE WHEN ps.seat_number < v_first_to_show_seat_number THEN ps.seat_number + msn.max_seat_number
						ELSE ps.seat_number
				   END show_order
			FROM   participating_seats ps,
				   max_seat_number msn
			ORDER BY show_order
		) LOOP
			
			-- first player has to show
			IF v_player_rec.seat_number = v_first_to_show_seat_number THEN
				pkg_poker_ai.log(
					p_state_id => p_poker_state.current_state_id,
					p_message  => 'player at seat ' || v_player_rec.seat_number || ' shows hand'
				);
				p_poker_state.player_state(v_player_rec.seat_number).hand_showing := 'Y';
			ELSE
				-- other players have opportunity to muck
				IF pkg_poker_ai.get_player_showdown_muck(p_seat_number => v_player_rec.seat_number) THEN
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'player at seat ' || v_player_rec.seat_number || ' mucks hand'
					);
					p_poker_state.player_state(v_player_rec.seat_number).state := 'FOLDED';
				ELSE
					pkg_poker_ai.log(
						p_state_id => p_poker_state.current_state_id,
						p_message  => 'player at seat ' || v_player_rec.seat_number || ' shows hand'
					);
					p_poker_state.player_state(v_player_rec.seat_number).hand_showing := 'Y';
				END IF;
			END IF;

		END LOOP;

		-- for all players showing hands, determine which pots they win
		FOR v_winners_rec IN (
			WITH pot_sums AS (
				SELECT pot_number,
					   SUM(pot_contribution) pot_value
				FROM   TABLE(p_poker_state.pot_contribution)
				GROUP BY pot_number
			),

			pot_ranks AS (
				SELECT DISTINCT
					   pc.pot_number,
					   ps.seat_number,
					   pkg_poker_ai.get_distance_from_small_blind(
							p_poker_state => p_poker_state,
							p_seat_number => ps.seat_number
					   ) distance_from_small_blind,
					   ps.best_hand_rank,
					   RANK() OVER (PARTITION BY pc.pot_number ORDER BY ps.best_hand_rank DESC) pot_rank
				FROM   TABLE(p_poker_state.player_state) ps,
					   TABLE(p_poker_state.pot_contribution) pc
				WHERE  ps.hand_showing = 'Y'
				   AND ps.seat_number = pc.player_seat_number
			),

			pot_winner_counts AS (
				SELECT pr.pot_number,
					   COUNT(*) pot_winners_count,
					   FLOOR(MIN(ps.pot_value) / COUNT(*)) per_player_amount,
					   CASE WHEN FLOOR(MIN(ps.pot_value) / COUNT(*)) != (MIN(ps.pot_value) / COUNT(*)) THEN 'Y' ELSE 'N' END odd_split,
					   MIN(ps.pot_value) - (COUNT(*) * FLOOR(MIN(ps.pot_value) / COUNT(*))) odd_chip_balance
				FROM   pot_ranks pr,
					   pot_sums ps
				WHERE  pr.pot_rank = 1
				   AND pr.pot_number = ps.pot_number
				GROUP BY pr.pot_number
			),

			-- winning players closest to small blind going clockwise get any odd split chips per pot
			odd_split_positions AS (
				SELECT pwc.pot_number,
					   pwc.odd_chip_balance,
					   pr.seat_number,
					   DENSE_RANK() OVER (PARTITION BY pwc.pot_number ORDER BY pr.distance_from_small_blind) odd_chip_keeper_rank
				FROM   pot_winner_counts pwc,
					   pot_ranks pr
				WHERE  pwc.odd_split = 'Y'
				   AND pwc.pot_number = pr.pot_number
				   AND pr.pot_rank = 1
			),
			
			odd_split_chip_keepers AS (
				SELECT pot_number,
					   seat_number,
					   1 extra_chip
				FROM   odd_split_positions
				WHERE  odd_chip_keeper_rank <= odd_chip_balance
			)
			
			SELECT pr.pot_number,
				   pr.seat_number,
				   pwc.per_player_amount + NVL(osck.extra_chip, 0) player_winnings,
				   CASE WHEN pwc.pot_winners_count > 1 THEN 'Y' ELSE 'N' END split_pot
			FROM   pot_winner_counts pwc,
				   pot_ranks pr,
				   odd_split_chip_keepers osck
			WHERE  pwc.pot_number = pr.pot_number
			   AND pr.pot_rank = 1
			   AND pr.pot_number = osck.pot_number (+)
			   AND pr.seat_number = osck.seat_number (+)
			ORDER BY
				pot_number,
				seat_number
		) LOOP

			-- distribute pot money
			pkg_poker_ai.log(
				p_state_id => p_poker_state.current_state_id,
				p_message  => 'player at seat ' || v_winners_rec.seat_number || ' wins '
					|| v_winners_rec.player_winnings || ' from pot ' || v_winners_rec.pot_number
			);
			p_poker_state.player_state(v_winners_rec.seat_number).money :=
				p_poker_state.player_state(v_winners_rec.seat_number).money + v_winners_rec.player_winnings;
			p_poker_state.player_state(v_winners_rec.seat_number).total_money_won :=
				p_poker_state.player_state(v_winners_rec.seat_number).total_money_won + v_winners_rec.player_winnings;
			IF v_winners_rec.pot_number = 1 THEN
				IF v_winners_rec.split_pot = 'N' THEN
					p_poker_state.player_state(v_winners_rec.seat_number).main_pots_won :=
						p_poker_state.player_state(v_winners_rec.seat_number).main_pots_won + 1;
				ELSE
					p_poker_state.player_state(v_winners_rec.seat_number).main_pots_split :=
						p_poker_state.player_state(v_winners_rec.seat_number).main_pots_split + 1;
				END IF;
			ELSE
				IF v_winners_rec.split_pot = 'N' THEN
					p_poker_state.player_state(v_winners_rec.seat_number).side_pots_won :=
						p_poker_state.player_state(v_winners_rec.seat_number).side_pots_won + 1;
				ELSE
					p_poker_state.player_state(v_winners_rec.seat_number).side_pots_split :=
						p_poker_state.player_state(v_winners_rec.seat_number).side_pots_split + 1;
				END IF;
			END IF;

		END LOOP;

	END IF;
	
	SELECT COUNT(*) tournament_rank
	INTO   v_tournament_rank
	FROM   TABLE(p_poker_state.player_state)
	WHERE  tournament_rank IS NULL;
	
	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		-- update average game profit
		p_poker_state.player_state(v_i).average_game_profit :=
			(p_poker_state.player_state(v_i).total_money_won - p_poker_state.player_state(v_i).total_money_played)
			/ NULLIF(p_poker_state.player_state(v_i).games_played, 0);
	
		-- set tournament rank on anyone that ran out of money	
		IF p_poker_state.player_state(v_i).tournament_rank IS NULL AND p_poker_state.player_state(v_i).money = 0 THEN
			p_poker_state.player_state(v_i).tournament_rank := v_tournament_rank;
			p_poker_state.player_state(v_i).state := 'OUT_OF_TOURNAMENT';
			p_poker_state.player_state(v_i).presented_bet_opportunity := NULL;
		END IF;
	END LOOP;
	
	p_poker_state.game_in_progress := 'N';
	p_poker_state.betting_round_in_progress := 'N';
	
	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'game over'
	);
	
END process_game_results;

PROCEDURE process_tournament_results(
	p_poker_state IN OUT t_poker_state
) IS
BEGIN

	FOR v_i IN p_poker_state.player_state.FIRST .. p_poker_state.player_state.LAST LOOP
		IF p_poker_state.player_state(v_i).state != 'OUT_OF_TOURNAMENT' THEN
			p_poker_state.player_state(v_i).tournament_rank := 1;
			p_poker_state.player_state(v_i).state := 'OUT_OF_TOURNAMENT';
		END IF;
	END LOOP;

	p_poker_state.tournament_in_progress := 'N';
	pkg_ga_player.capture_tournament_results(p_poker_state => p_poker_state);
	pkg_ga_player.update_strategy_fitness(p_poker_state => p_poker_state);
	
	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'tournament over'
	);

END process_tournament_results;

FUNCTION get_hand_rank(
	p_poker_state t_poker_state,
	p_card_1      poker_state_log.community_card_1%TYPE,
	p_card_2      poker_state_log.community_card_1%TYPE,
	p_card_3      poker_state_log.community_card_1%TYPE,
	p_card_4      poker_state_log.community_card_1%TYPE,
	p_card_5      poker_state_log.community_card_1%TYPE
) RETURN VARCHAR2 IS

	v_hand_rank  VARCHAR2(17);
	v_card_order VARCHAR2(14);
	v_row_hand   t_row_hand := t_row_hand(NULL, NULL, NULL, NULL);
	v_tbl_hand   t_tbl_hand := t_tbl_hand();

BEGIN

	IF p_card_1 IS NULL OR p_card_2 IS NULL OR p_card_3 IS NULL OR p_card_4 IS NULL OR p_card_5 IS NULL
		OR p_card_1 = 0 OR p_card_2 = 0 OR p_card_3 = 0 OR p_card_4 = 0 OR p_card_5 = 0 THEN
		-- incomplete hand
		RETURN '00';
	END IF;

	-- store hand for read back
	v_tbl_hand.EXTEND(5);
	FOR v_rec IN (
		SELECT ROWNUM card_index,
			   card_id,
			   suit,
			   value,
			   COUNT(*) OVER (PARTITION BY value) value_occurences
		FROM   TABLE(p_poker_state.deck)
		WHERE  card_id IN (p_card_1, p_card_2, p_card_3, p_card_4, p_card_5)
	) LOOP
		v_row_hand.card_id := v_rec.card_id;
		v_row_hand.suit := v_rec.suit;
		v_row_hand.value := v_rec.value;
		v_row_hand.value_occurences := v_rec.value_occurences;
		v_tbl_hand(v_rec.card_index) := v_row_hand;
	END LOOP;

	-- determine hand classification
	WITH straight_raw AS (
		SELECT CASE WHEN (
					   LEAD(value, 1) OVER (ORDER BY value) = value + 1
				   AND LEAD(value, 2) OVER (ORDER BY value) = value + 2
				   AND LEAD(value, 3) OVER (ORDER BY value) = value + 3
				   AND LEAD(value, 4) OVER (ORDER BY value) = value + 4
					) OR (
					   value = 2
				   AND LEAD(value, 1) OVER (ORDER BY value) = 3
				   AND LEAD(value, 2) OVER (ORDER BY value) = 4
				   AND LEAD(value, 3) OVER (ORDER BY value) = 5
				   AND LEAD(value, 4) OVER (ORDER BY value) = 14
				) THEN 'Y'
				ELSE 'N'
			  END straight
		FROM  TABLE(v_tbl_hand)
	),

	straight AS (
		SELECT MAX(straight) straight
		FROM   straight_raw
	)
	
	SELECT CASE WHEN COUNT(DISTINCT hc.suit) = 1 AND MAX(s.straight) = 'Y' AND MAX(hc.value) = 14 THEN '10' -- royal flush
				WHEN COUNT(DISTINCT hc.suit) = 1 AND MAX(s.straight) = 'Y'                        THEN '09' -- straight flush
				WHEN MAX(hc.value_occurences) = 4                                                 THEN '08' -- four of a kind
			    WHEN MAX(hc.value_occurences) = 3 AND COUNT(DISTINCT hc.value) = 2                THEN '07' -- full house
				WHEN COUNT(DISTINCT hc.suit) = 1                                                  THEN '06' -- flush
				WHEN MAX(s.straight) = 'Y'                                                        THEN '05' -- straight
			    WHEN MAX(hc.value_occurences) = 3                                                 THEN '04' -- three of a kind
			    WHEN MAX(hc.value_occurences) = 2 AND COUNT(DISTINCT hc.value) = 3                THEN '03' -- two pair
			    WHEN MAX(hc.value_occurences) = 2                                                 THEN '02' -- one pair
				                                                                                  ELSE '01' -- high card
		   END hand_rank
	INTO   v_hand_rank
	FROM   TABLE(v_tbl_hand) hc,
		   straight s;

	-- append on the order of cards for tie breaking
	IF v_hand_rank IN ('08', '07', '04', '03', '02', '01') THEN -- four of a kind, full house, three of a kind, two pair, one pair, or high card
		SELECT LISTAGG(LPAD(value, 2, '0'), '_') WITHIN GROUP (ORDER BY value_occurences DESC, value DESC) card_order
		INTO   v_card_order
		FROM   TABLE(v_tbl_hand);

	ELSIF v_hand_rank IN ('05', '09') THEN -- straight or straight flush
		-- determine if the staight uses ace as a low card
		WITH hand_low_straight AS (
			SELECT CASE WHEN MIN(value) = 2 AND MAX(value) = 14 THEN 'Y' ELSE 'N' END ace_as_one
			FROM   TABLE(v_tbl_hand)
		),

		card_values AS (
			SELECT CASE WHEN hls.ace_as_one = 'Y' AND hc.value = 14 THEN 1 ELSE hc.value END value
			FROM   TABLE(v_tbl_hand) hc,
				   hand_low_straight hls
		)

		SELECT LISTAGG(LPAD(value, 2, '0'), '_') WITHIN GROUP (ORDER BY value DESC) card_order
		INTO   v_card_order
		FROM   card_values;

	ELSIF v_hand_rank = '06' THEN -- flush
		SELECT LISTAGG(LPAD(value, 2, '0'), '_') WITHIN GROUP (ORDER BY value DESC) card_order
		INTO   v_card_order
		FROM   TABLE(v_tbl_hand);

	END IF;

	v_hand_rank := v_hand_rank || '_' || v_card_order;

	RETURN v_hand_rank;

END get_hand_rank;

PROCEDURE calculate_best_hands(
	p_poker_state IN OUT t_poker_state
) IS
BEGIN

	FOR v_player_rec IN (
		WITH players AS (
			SELECT seat_number,
				   p_poker_state.community_card_1 c1,
				   p_poker_state.community_card_2 c2,
				   p_poker_state.community_card_3 c3,
				   p_poker_state.community_card_4 c4,
				   p_poker_state.community_card_5 c5,
				   hole_card_1 c6,
				   hole_card_2 c7
			FROM   TABLE(p_poker_state.player_state)
			WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		),

		combination_ids AS (
			SELECT ROWNUM combination_id
			FROM   DUAL
			CONNECT BY ROWNUM <= 21
		),

		possible_hands AS (
			-- 7 choose 5 = 21 possible combinations per player
			SELECT CASE cid.combination_id
						WHEN 1 THEN '1,2,3,4,5'
						WHEN 2 THEN '1,2,3,4,6'
						WHEN 3 THEN '1,2,3,4,7'
						WHEN 4 THEN '1,2,3,5,6'
						WHEN 5 THEN '1,2,3,5,7'
						WHEN 6 THEN '1,2,3,6,7'
						WHEN 7 THEN '1,2,4,5,6'
						WHEN 8 THEN '1,2,4,5,7'
						WHEN 9 THEN '1,2,4,6,7'
						WHEN 10 THEN '1,2,5,6,7'
						WHEN 11 THEN '1,3,4,5,6'
						WHEN 12 THEN '1,3,4,5,7'
						WHEN 13 THEN '1,3,4,6,7'
						WHEN 14 THEN '1,3,5,6,7'
						WHEN 15 THEN '1,4,5,6,7'
						WHEN 16 THEN '2,3,4,5,6'
						WHEN 17 THEN '2,3,4,5,7'
						WHEN 18 THEN '2,3,4,6,7'
						WHEN 19 THEN '2,3,5,6,7'
						WHEN 20 THEN '2,4,5,6,7'
						WHEN 21 THEN '3,4,5,6,7'
				   END combination,
				   p.seat_number,
				   CASE cid.combination_id
						WHEN 1 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c4, p.c5)
						WHEN 2 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c4, p.c6)
						WHEN 3 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c4, p.c7)
						WHEN 4 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c5, p.c6)
						WHEN 5 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c5, p.c7)
						WHEN 6 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c3, p.c6, p.c7)
						WHEN 7 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c4, p.c5, p.c6)
						WHEN 8 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c4, p.c5, p.c7)
						WHEN 9 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c4, p.c6, p.c7)
						WHEN 10 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c2, p.c5, p.c6, p.c7)
						WHEN 11 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c3, p.c4, p.c5, p.c6)
						WHEN 12 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c3, p.c4, p.c5, p.c7)
						WHEN 13 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c3, p.c4, p.c6, p.c7)
						WHEN 14 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c3, p.c5, p.c6, p.c7)
						WHEN 15 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c1, p.c4, p.c5, p.c6, p.c7)
						WHEN 16 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c2, p.c3, p.c4, p.c5, p.c6)
						WHEN 17 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c2, p.c3, p.c4, p.c5, p.c7)
						WHEN 18 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c2, p.c3, p.c4, p.c6, p.c7)
						WHEN 19 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c2, p.c3, p.c5, p.c6, p.c7)
						WHEN 20 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c2, p.c4, p.c5, p.c6, p.c7)
						WHEN 21 THEN pkg_poker_ai.get_hand_rank(p_poker_state, p.c3, p.c4, p.c5, p.c6, p.c7)
				   END hand_rank,
				   CASE cid.combination_id
						WHEN 1 THEN p.c1
						WHEN 2 THEN p.c1
						WHEN 3 THEN p.c1
						WHEN 4 THEN p.c1
						WHEN 5 THEN p.c1
						WHEN 6 THEN p.c1
						WHEN 7 THEN p.c1
						WHEN 8 THEN p.c1
						WHEN 9 THEN p.c1
						WHEN 10 THEN p.c1
						WHEN 11 THEN p.c1
						WHEN 12 THEN p.c1
						WHEN 13 THEN p.c1
						WHEN 14 THEN p.c1
						WHEN 15 THEN p.c1
						WHEN 16 THEN p.c2
						WHEN 17 THEN p.c2
						WHEN 18 THEN p.c2
						WHEN 19 THEN p.c2
						WHEN 20 THEN p.c2
						WHEN 21 THEN p.c3
				   END card_1,
				   CASE cid.combination_id
						WHEN 1 THEN p.c2
						WHEN 2 THEN p.c2
						WHEN 3 THEN p.c2
						WHEN 4 THEN p.c2
						WHEN 5 THEN p.c2
						WHEN 6 THEN p.c2
						WHEN 7 THEN p.c2
						WHEN 8 THEN p.c2
						WHEN 9 THEN p.c2
						WHEN 10 THEN p.c2
						WHEN 11 THEN p.c3
						WHEN 12 THEN p.c3
						WHEN 13 THEN p.c3
						WHEN 14 THEN p.c3
						WHEN 15 THEN p.c4
						WHEN 16 THEN p.c3
						WHEN 17 THEN p.c3
						WHEN 18 THEN p.c3
						WHEN 19 THEN p.c3
						WHEN 20 THEN p.c4
						WHEN 21 THEN p.c4
				   END card_2,
				   CASE cid.combination_id
						WHEN 1 THEN p.c3
						WHEN 2 THEN p.c3
						WHEN 3 THEN p.c3
						WHEN 4 THEN p.c3
						WHEN 5 THEN p.c3
						WHEN 6 THEN p.c3
						WHEN 7 THEN p.c4
						WHEN 8 THEN p.c4
						WHEN 9 THEN p.c4
						WHEN 10 THEN p.c5
						WHEN 11 THEN p.c4
						WHEN 12 THEN p.c4
						WHEN 13 THEN p.c4
						WHEN 14 THEN p.c5
						WHEN 15 THEN p.c5
						WHEN 16 THEN p.c4
						WHEN 17 THEN p.c4
						WHEN 18 THEN p.c4
						WHEN 19 THEN p.c5
						WHEN 20 THEN p.c5
						WHEN 21 THEN p.c5
				   END card_3,
   				   CASE cid.combination_id
						WHEN 1 THEN p.c4
						WHEN 2 THEN p.c4
						WHEN 3 THEN p.c4
						WHEN 4 THEN p.c5
						WHEN 5 THEN p.c5
						WHEN 6 THEN p.c6
						WHEN 7 THEN p.c5
						WHEN 8 THEN p.c5
						WHEN 9 THEN p.c6
						WHEN 10 THEN p.c6
						WHEN 11 THEN p.c5
						WHEN 12 THEN p.c5
						WHEN 13 THEN p.c6
						WHEN 14 THEN p.c6
						WHEN 15 THEN p.c6
						WHEN 16 THEN p.c5
						WHEN 17 THEN p.c5
						WHEN 18 THEN p.c6
						WHEN 19 THEN p.c6
						WHEN 20 THEN p.c6
						WHEN 21 THEN p.c6
				   END card_4,
   				   CASE cid.combination_id
						WHEN 1 THEN p.c5
						WHEN 2 THEN p.c6
						WHEN 3 THEN p.c7
						WHEN 4 THEN p.c6
						WHEN 5 THEN p.c7
						WHEN 6 THEN p.c7
						WHEN 7 THEN p.c6
						WHEN 8 THEN p.c7
						WHEN 9 THEN p.c7
						WHEN 10 THEN p.c7
						WHEN 11 THEN p.c6
						WHEN 12 THEN p.c7
						WHEN 13 THEN p.c7
						WHEN 14 THEN p.c7
						WHEN 15 THEN p.c7
						WHEN 16 THEN p.c6
						WHEN 17 THEN p.c7
						WHEN 18 THEN p.c7
						WHEN 19 THEN p.c7
						WHEN 20 THEN p.c7
						WHEN 21 THEN p.c7
				   END card_5
			FROM   players p,
				   combination_ids cid
		)
		
		SELECT DISTINCT
			   seat_number,
			   MIN(combination) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_combination,
			   MIN(hand_rank) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_rank,
			   MIN(card_1) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_card_1,
			   MIN(card_2) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_card_2,
			   MIN(card_3) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_card_3,
			   MIN(card_4) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_card_4,
			   MIN(card_5) KEEP (DENSE_RANK FIRST ORDER BY hand_rank DESC, combination) OVER (PARTITION BY seat_number) best_hand_card_5
		FROM   possible_hands
		WHERE  hand_rank != '00'
	) LOOP

		-- set the player's best possible hand in on the player's state record
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_combination := v_player_rec.best_hand_combination;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_rank := v_player_rec.best_hand_rank;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_1 := v_player_rec.best_hand_card_1;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_2 := v_player_rec.best_hand_card_2;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_3 := v_player_rec.best_hand_card_3;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_4 := v_player_rec.best_hand_card_4;
		p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_5 := v_player_rec.best_hand_card_5;

	END LOOP;

END calculate_best_hands;

PROCEDURE sort_hands(
	p_poker_state IN OUT t_poker_state
) IS

	v_row_hand t_row_hand := t_row_hand(NULL, NULL, NULL, NULL);
	v_tbl_hand t_tbl_hand := t_tbl_hand();

BEGIN

	v_tbl_hand.EXTEND(5);

	FOR v_player_rec IN (
		SELECT seat_number,
			   SUBSTR(best_hand_rank, 1, 2) hand_rank,
			   best_hand_card_1 c1,
			   best_hand_card_2 c2,
			   best_hand_card_3 c3,
			   best_hand_card_4 c4,
			   best_hand_card_5 c5
		FROM   TABLE(p_poker_state.player_state)
		WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		   AND best_hand_card_1 IS NOT NULL
		   AND best_hand_card_2 IS NOT NULL
		   AND best_hand_card_3 IS NOT NULL
		   AND best_hand_card_4 IS NOT NULL
		   AND best_hand_card_5 IS NOT NULL
	) LOOP

		-- store hand for read back
		FOR v_card_rec IN (
			WITH cards AS (
				SELECT card_id,
					   suit,
					   value
				FROM   TABLE(p_poker_state.deck)
				WHERE  card_id IN (v_player_rec.c1, v_player_rec.c2, v_player_rec.c3, v_player_rec.c4, v_player_rec.c5)
			),

			value_occurences AS (
				SELECT value,
					   COUNT(*) value_occurences
				FROM   cards
				GROUP BY value
			)

			SELECT ROWNUM card_index,
				   c.card_id,
				   c.suit,
				   c.value,
				   vo.value_occurences
			FROM   cards c,
				   value_occurences vo
			WHERE  c.value = vo.value
		) LOOP
			v_row_hand.card_id := v_card_rec.card_id;
			v_row_hand.suit := v_card_rec.suit;
			v_row_hand.value := v_card_rec.value;
			v_row_hand.value_occurences := v_card_rec.value_occurences;
			v_tbl_hand(v_card_rec.card_index) := v_row_hand;
		END LOOP;

		IF v_player_rec.hand_rank IN ('10', '09') THEN

			-- royal flush, straight flush
			FOR v_hand_rec IN (
				WITH sorted_raw AS (
					SELECT card_id
					FROM   TABLE(v_tbl_hand)
					ORDER BY value
				),
				sorted AS (
					SELECT ROWNUM row_num,
						   card_id
					FROM   sorted_raw
				)
				SELECT MIN(CASE WHEN row_num = 1 THEN card_id END) card_1,
					   MIN(CASE WHEN row_num = 2 THEN card_id END) card_2,
					   MIN(CASE WHEN row_num = 3 THEN card_id END) card_3,
					   MIN(CASE WHEN row_num = 4 THEN card_id END) card_4,
					   MIN(CASE WHEN row_num = 5 THEN card_id END) card_5
				FROM   sorted
			) LOOP
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_1 := v_hand_rec.card_1;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_2 := v_hand_rec.card_2;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_3 := v_hand_rec.card_3;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_4 := v_hand_rec.card_4;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_5 := v_hand_rec.card_5;
			END LOOP;

		ELSIF v_player_rec.hand_rank = '05' THEN

			-- straight
			FOR v_hand_rec IN (
				WITH ace_high AS (
					SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END ace_high
					FROM   TABLE(v_tbl_hand)
					WHERE  value = 13 -- has king, ace must be high
				),
				sorted_raw AS (
					SELECT h.card_id
					FROM   TABLE(v_tbl_hand) h,
						   ace_high ah
					ORDER BY CASE WHEN ah.ace_high = 'N' AND h.value = 14 THEN 0 ELSE value END
				),
				sorted AS (
					SELECT ROWNUM row_num,
						   card_id
					FROM   sorted_raw
				)
				SELECT MIN(CASE WHEN row_num = 1 THEN card_id END) card_1,
					   MIN(CASE WHEN row_num = 2 THEN card_id END) card_2,
					   MIN(CASE WHEN row_num = 3 THEN card_id END) card_3,
					   MIN(CASE WHEN row_num = 4 THEN card_id END) card_4,
					   MIN(CASE WHEN row_num = 5 THEN card_id END) card_5
				FROM   sorted
			) LOOP
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_1 := v_hand_rec.card_1;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_2 := v_hand_rec.card_2;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_3 := v_hand_rec.card_3;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_4 := v_hand_rec.card_4;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_5 := v_hand_rec.card_5;
			END LOOP;

		ELSE

			-- four of a kind, full house, flush, three of a kind, two pair, one pair, high card
			FOR v_hand_rec IN (
				WITH sorted_raw AS (
					SELECT card_id
					FROM   TABLE(v_tbl_hand)
					ORDER BY
						value_occurences DESC,
						value DESC,
						suit
				),
				sorted AS (
					SELECT ROWNUM row_num,
						   card_id
					FROM   sorted_raw
				)
				SELECT MIN(CASE WHEN row_num = 1 THEN card_id END) card_1,
					   MIN(CASE WHEN row_num = 2 THEN card_id END) card_2,
					   MIN(CASE WHEN row_num = 3 THEN card_id END) card_3,
					   MIN(CASE WHEN row_num = 4 THEN card_id END) card_4,
					   MIN(CASE WHEN row_num = 5 THEN card_id END) card_5
				FROM   sorted
			) LOOP
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_1 := v_hand_rec.card_1;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_2 := v_hand_rec.card_2;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_3 := v_hand_rec.card_3;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_4 := v_hand_rec.card_4;
				p_poker_state.player_state(v_player_rec.seat_number).best_hand_card_5 := v_hand_rec.card_5;
			END LOOP;

		END IF;

	END LOOP;

END sort_hands;

FUNCTION get_can_fold(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_fold
	INTO   v_result
	FROM   TABLE(p_poker_state.player_state)
	WHERE  seat_number = p_seat_number
	   AND p_poker_state.turn_seat_number = p_seat_number
	   AND p_poker_state.betting_round_in_progress = 'Y' 
	   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');
	   
	RETURN v_result;
	
END get_can_fold;

FUNCTION get_can_check(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_check
	INTO   v_result
	FROM   TABLE(p_poker_state.player_state)
	WHERE  seat_number = p_seat_number
	   AND p_poker_state.turn_seat_number = p_seat_number
	   AND p_poker_state.betting_round_in_progress = 'Y' 
	   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	   AND pkg_poker_ai.get_pot_deficit(
			p_poker_state => p_poker_state,
			p_seat_number => p_seat_number) = 0;
	   
	RETURN v_result;
	
END get_can_check;

FUNCTION get_can_call(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_call
	INTO   v_result
	FROM   TABLE(p_poker_state.player_state)
	WHERE  seat_number = p_seat_number
	   AND p_poker_state.turn_seat_number = p_seat_number
	   AND p_poker_state.betting_round_in_progress = 'Y'
	   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	   AND pkg_poker_ai.get_pot_deficit(
			p_poker_state => p_poker_state,
			p_seat_number => p_seat_number) > 0;
			   
	RETURN v_result;
	
END get_can_call;

FUNCTION get_can_bet(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	WITH bet_exists AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_exists
		FROM   TABLE(p_poker_state.pot)
		WHERE  p_poker_state.betting_round_number = betting_round_number
	),
	
	player_bet_state AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_bet
		FROM   TABLE(p_poker_state.player_state) this_player_state,
			   TABLE(p_poker_state.player_state) peer_player_state
		WHERE  this_player_state.seat_number = p_seat_number
		   AND p_poker_state.turn_seat_number = p_seat_number
		   AND p_poker_state.betting_round_in_progress = 'Y'
		   AND this_player_state.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
		   AND pkg_poker_ai.get_pot_deficit(
				p_poker_state => p_poker_state,
				p_seat_number => p_seat_number) = 0
		   AND peer_player_state.seat_number != p_seat_number
		   AND peer_player_state.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	)
	
	SELECT CASE WHEN be.bet_exists = 'N' AND pbs.can_bet = 'Y' THEN 'Y' ELSE 'N' END can_bet
	INTO   v_result
	FROM   bet_exists be,
		   player_bet_state pbs;

	RETURN v_result;
	
END get_can_bet;

FUNCTION get_can_raise(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	WITH bet_exists AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_exists
		FROM   TABLE(p_poker_state.pot)
		WHERE  p_poker_state.betting_round_number = betting_round_number
	),

	other_players_to_raise AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END other_players_to_raise_exist
		FROM   TABLE(p_poker_state.player_state)
		WHERE  seat_number != p_seat_number
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	),
	
	player_raise_state AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_raise
		FROM   TABLE(p_poker_state.player_state)
		WHERE  seat_number = p_seat_number
		   AND p_poker_state.turn_seat_number = p_seat_number
		   AND p_poker_state.betting_round_in_progress = 'Y'
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
		   AND (money - pkg_poker_ai.get_pot_deficit(
					p_poker_state => p_poker_state,
					p_seat_number => seat_number)) > 0
	)

	SELECT CASE WHEN be.bet_exists = 'Y'
					AND optr.other_players_to_raise_exist = 'Y'
					AND prs.can_raise = 'Y'
					THEN 'Y'
				ELSE 'N'
		   END can_raise
	INTO   v_result
	FROM   bet_exists be,
		   other_players_to_raise optr,
		   player_raise_state prs;
	   
	RETURN v_result;
	
END get_can_raise;

FUNCTION get_min_bet_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE IS
BEGIN

	IF p_poker_state.player_state.EXISTS(p_seat_number) THEN
		IF p_poker_state.player_state(p_seat_number).money < p_poker_state.min_raise_amount THEN
			RETURN p_poker_state.player_state(p_seat_number).money;
		ELSE
			RETURN p_poker_state.min_raise_amount;
		END IF;
	ELSE
		RETURN NULL;
	END IF;
	
END get_min_bet_amount;

FUNCTION get_max_bet_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN player_state_log.money%TYPE IS

	v_max_bet player_state_log.money%TYPE;
	
BEGIN

	IF p_poker_state.player_state.EXISTS(p_seat_number) THEN
		WITH peer_max_money AS (
			SELECT MAX(money) peer_max_money
			FROM   TABLE(p_poker_state.player_state)
			WHERE  seat_number != p_seat_number
			   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		)
		
		SELECT LEAST(peer_max_money, p_poker_state.player_state(p_seat_number).money) max_bet
		INTO   v_max_bet
		FROM   peer_max_money;
		
		RETURN v_max_bet;
	ELSE
		RETURN NULL;
	END IF;
	
END get_max_bet_amount;

FUNCTION get_min_raise_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE IS

	v_remaining_money player_state_log.money%TYPE;
	
BEGIN

	IF p_poker_state.player_state.EXISTS(p_seat_number) THEN
		v_remaining_money := p_poker_state.player_state(p_seat_number).money - pkg_poker_ai.get_pot_deficit(
			p_poker_state => p_poker_state,
			p_seat_number => p_seat_number
		);
		
		IF v_remaining_money >= p_poker_state.min_raise_amount THEN
			RETURN p_poker_state.min_raise_amount;
		ELSE
			RETURN v_remaining_money;
		END IF;
	ELSE
		RETURN NULL;
	END IF;
	
END get_min_raise_amount;

FUNCTION get_max_raise_amount(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN poker_state_log.min_raise_amount%TYPE IS

	v_max_raise poker_state_log.min_raise_amount%TYPE;
	
BEGIN

	IF p_poker_state.player_state.EXISTS(p_seat_number) THEN
		WITH pot_players AS (
			SELECT p.pot_number,
				   p.betting_round_number,
				   p.bet_value,
				   ps.seat_number,
				   ps.money
			FROM   TABLE(p_poker_state.pot) p,
				   TABLE(p_poker_state.player_state) ps
			WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		),

		pot_deficits AS (
			SELECT pp.seat_number,
				   pp.bet_value deficit
			FROM   pot_players pp,
				   TABLE(p_poker_state.pot_contribution) pc
			WHERE  pp.pot_number = pc.pot_number (+)
			   AND pp.betting_round_number = pc.betting_round_number (+)
			   AND pp.seat_number = pc.player_seat_number (+)
			   AND pc.player_seat_number IS NULL
			 
			UNION ALL
			 
			SELECT pc.player_seat_number seat_number,
				   (p.bet_value - pc.pot_contribution) deficit
			FROM   TABLE(p_poker_state.pot) p,
				   TABLE(p_poker_state.pot_contribution) pc
			WHERE  p.pot_number = pc.pot_number
			   AND p.betting_round_number = pc.betting_round_number
		),
		
		total_deficits AS (
			SELECT seat_number,
				   NVL(SUM(deficit), 0) total_deficit
			FROM   pot_deficits
			GROUP BY seat_number
		),
		
		remaining_money AS (
			SELECT DISTINCT
				   pp.seat_number,
				   (pp.money - td.total_deficit) remaining_money
			FROM   pot_players pp,
				   total_deficits td
			WHERE  pp.seat_number = td.seat_number
		),
		
		peer_max_money AS (
			SELECT MAX(remaining_money) peer_max_money
			FROM   remaining_money
			WHERE  seat_number != p_seat_number
		)
		
		SELECT LEAST(rm.remaining_money, pmm.peer_max_money) max_raise
		INTO   v_max_raise
		FROM   remaining_money rm,
			   peer_max_money pmm
		WHERE  rm.seat_number = p_seat_number;

		RETURN v_max_raise;
	ELSE
		RETURN NULL;
	END IF;
	
END get_max_raise_amount;

FUNCTION get_pot_deficit(
	p_poker_state t_poker_state,
	p_seat_number player_state_log.seat_number%TYPE
) RETURN pot_contribution_log.pot_contribution%TYPE IS

	v_result pot_contribution_log.pot_contribution%TYPE;
	
BEGIN

	WITH pot_players AS (
		SELECT ps.seat_number,
			   p.pot_number,
			   p.betting_round_number,
			   p.bet_value,
			   ps.money
		FROM   TABLE(p_poker_state.pot) p,
			   TABLE(p_poker_state.player_state) ps
		WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		   AND ps.seat_number = p_seat_number
	),
	
	pot_deficits AS (
		SELECT pp.bet_value deficit
		FROM   pot_players pp,
			   TABLE(p_poker_state.pot_contribution) pc
		WHERE  pp.pot_number = pc.pot_number (+)
		   AND pp.betting_round_number = pc.betting_round_number (+)
		   AND pp.seat_number = pc.player_seat_number (+)
		   AND pc.player_seat_number IS NULL
		 
		UNION ALL
		 
		SELECT (p.bet_value - pc.pot_contribution) deficit
		FROM   pot_players pp,
			   TABLE(p_poker_state.pot) p,
			   TABLE(p_poker_state.pot_contribution) pc
		WHERE  pp.pot_number = p.pot_number
		   AND pp.betting_round_number = p.betting_round_number
		   AND p.pot_number = pc.pot_number
		   AND p.betting_round_number = pc.betting_round_number
		   AND pp.seat_number = pc.player_seat_number
	)
	
	SELECT NVL(SUM(deficit), 0) total_deficit
	INTO   v_result
	FROM   pot_deficits;
	
	RETURN v_result;

END get_pot_deficit;

PROCEDURE contribute_to_pot(
	p_poker_state        IN OUT t_poker_state,
	p_player_seat_number pot_contribution_log.player_seat_number%TYPE,
	p_pot_contribution   pot_contribution_log.pot_contribution%TYPE
) IS

	v_round_highest_pot_number   pot_log.pot_number%TYPE;
	v_highest_pot_number         pot_log.pot_number%TYPE;
	v_highest_pot_bet_value      pot_log.bet_value%TYPE;
	v_total_pot_contribution     pot_contribution_log.pot_contribution%TYPE;
	v_this_pot_contribution      pot_contribution_log.pot_contribution%TYPE;
	v_highest_pot_total_contr    pot_contribution_log.pot_contribution%TYPE;
	v_pot_rec                    t_row_pot := t_row_pot(NULL, NULL, NULL);
	v_pot_contribution_rec       t_row_pot_contribution := t_row_pot_contribution(NULL, NULL, NULL, NULL);
	v_pot_contribution_rec_found BOOLEAN;
	v_need_side_pot              VARCHAR2(1);
	
BEGIN

	pkg_poker_ai.log(
		p_state_id => p_poker_state.current_state_id,
		p_message  => 'player at seat ' || p_player_seat_number || ' contributes ' || p_pot_contribution || ' to the pot'
	);
	
	-- determine highest pot number for the current betting round
	SELECT MAX(pot_number) round_highest_pot_number
	INTO   v_round_highest_pot_number
	FROM   TABLE(p_poker_state.pot)
	WHERE  betting_round_number = NVL(p_poker_state.betting_round_number, 1);
	
	IF v_round_highest_pot_number IS NULL THEN
	
		-- determine highest overall pot number
		SELECT NVL(MAX(pot_number), 1) highest_pot_number
		INTO   v_highest_pot_number
		FROM   TABLE(p_poker_state.pot);

		-- create initial pot for round
		v_pot_rec.pot_number := v_highest_pot_number;
		v_pot_rec.betting_round_number := NVL(p_poker_state.betting_round_number, 1);
		v_pot_rec.bet_value := p_pot_contribution;
		p_poker_state.pot.EXTEND(1);
		p_poker_state.pot(p_poker_state.pot.LAST) := v_pot_rec;
		
		v_pot_contribution_rec.pot_number := v_highest_pot_number;
		v_pot_contribution_rec.betting_round_number := NVL(p_poker_state.betting_round_number, 1);
		v_pot_contribution_rec.player_seat_number := p_player_seat_number;
		v_pot_contribution_rec.pot_contribution := p_pot_contribution;
		p_poker_state.pot_contribution.EXTEND(1);
		p_poker_state.pot_contribution(p_poker_state.pot_contribution.LAST) := v_pot_contribution_rec;
		
	ELSE
	
		-- starting from the lowest pot number, put in money to cover any deficits
		v_total_pot_contribution := p_pot_contribution;
		FOR v_rec IN (
			SELECT p.pot_number,
				   p.betting_round_number,
				   p.bet_value,
				   p.bet_value deficit
			FROM   TABLE(p_poker_state.pot) p,
				   TABLE(p_poker_state.pot_contribution) pc
			WHERE  p.pot_number = pc.pot_number (+)
			   AND p.betting_round_number = pc.betting_round_number (+)
			   AND p.betting_round_number = NVL(p_poker_state.betting_round_number, 1)
			   AND pc.player_seat_number (+) = p_player_seat_number
			   AND pc.player_seat_number IS NULL
			 
			UNION ALL
			 
			SELECT p.pot_number,
				   p.betting_round_number,
				   p.bet_value,
				   (p.bet_value - pc.pot_contribution) deficit
			FROM   TABLE(p_poker_state.pot) p,
				   TABLE(p_poker_state.pot_contribution) pc
			WHERE  p.pot_number = pc.pot_number
			   AND p.betting_round_number = pc.betting_round_number
			   AND p.betting_round_number = NVL(p_poker_state.betting_round_number, 1)
			   AND pc.player_seat_number = p_player_seat_number
			   AND ((p.bet_value - pc.pot_contribution) != 0 OR p.pot_number = v_round_highest_pot_number)
			   
			ORDER BY pot_number
		) LOOP
		
			IF v_rec.pot_number != v_round_highest_pot_number THEN
				-- the player is contributing either the total pot deficit or as much remaining money as they have
				v_this_pot_contribution := LEAST(v_total_pot_contribution, v_rec.deficit);
			ELSE
				-- on the highest pot number, contribute all of remaining money from the total contribution
				v_this_pot_contribution := v_total_pot_contribution;
			END IF;
			
			-- contribute to the pot
			v_pot_contribution_rec_found := FALSE;
			FOR v_i IN p_poker_state.pot_contribution.FIRST .. p_poker_state.pot_contribution.LAST LOOP
				IF p_poker_state.pot_contribution(v_i).pot_number = v_rec.pot_number
				   AND p_poker_state.pot_contribution(v_i).betting_round_number = v_rec.betting_round_number
				   AND p_poker_state.pot_contribution(v_i).player_seat_number = p_player_seat_number THEN
					p_poker_state.pot_contribution(v_i).pot_contribution :=
						p_poker_state.pot_contribution(v_i).pot_contribution + v_this_pot_contribution;
					v_pot_contribution_rec_found := TRUE;
					EXIT;
				END IF;
			END LOOP;
			IF NOT v_pot_contribution_rec_found THEN
				v_pot_contribution_rec.pot_number := v_rec.pot_number;
				v_pot_contribution_rec.betting_round_number := v_rec.betting_round_number;
				v_pot_contribution_rec.player_seat_number := p_player_seat_number;
				v_pot_contribution_rec.pot_contribution := v_this_pot_contribution;
				p_poker_state.pot_contribution.EXTEND(1);
				p_poker_state.pot_contribution(p_poker_state.pot_contribution.LAST) := v_pot_contribution_rec;
			END IF;
			
			-- take this pot contribution away from total amount being contributed
			v_total_pot_contribution := v_total_pot_contribution - v_this_pot_contribution;
			
			-- on the highest pot, need to possibly split pots or increase pot bet
			IF v_rec.pot_number = v_round_highest_pot_number THEN
			
				v_highest_pot_bet_value := v_rec.bet_value;
				SELECT NVL(MIN(pot_contribution), 0) highest_pot_total_contr
				INTO   v_highest_pot_total_contr
				FROM   TABLE(p_poker_state.pot_contribution)
				WHERE  pot_number = v_round_highest_pot_number
				   AND betting_round_number = NVL(p_poker_state.betting_round_number, 1)
				   AND player_seat_number = p_player_seat_number;
				
				IF v_highest_pot_total_contr < v_highest_pot_bet_value THEN
				
					-- player is going all in and cannot cover the current bet, need to split pot
					v_pot_rec.pot_number := v_round_highest_pot_number + 1;
					v_pot_rec.betting_round_number := NVL(p_poker_state.betting_round_number, 1);
					v_pot_rec.bet_value := v_highest_pot_bet_value - v_highest_pot_total_contr;
					p_poker_state.pot.EXTEND(1);
					p_poker_state.pot(p_poker_state.pot.LAST) := v_pot_rec;

					-- move balance of all other players in pot to new pot
					FOR v_balance_rec IN (
						SELECT (v_round_highest_pot_number + 1) pot_number,
							   betting_round_number,
							   player_seat_number,
							   (pot_contribution - v_highest_pot_total_contr) pot_contribution
						FROM   TABLE(p_poker_state.pot_contribution)
						WHERE  pot_number = v_round_highest_pot_number
						   AND betting_round_number = NVL(p_poker_state.betting_round_number, 1)
						   AND player_seat_number != p_player_seat_number
						   AND pot_contribution > v_highest_pot_total_contr
					) LOOP
						v_pot_contribution_rec.pot_number := v_balance_rec.pot_number;
						v_pot_contribution_rec.betting_round_number := v_balance_rec.betting_round_number;
						v_pot_contribution_rec.player_seat_number := v_balance_rec.player_seat_number;
						v_pot_contribution_rec.pot_contribution := v_balance_rec.pot_contribution;
						p_poker_state.pot_contribution.EXTEND(1);
						p_poker_state.pot_contribution(p_poker_state.pot_contribution.LAST) := v_pot_contribution_rec;
					END LOOP;

					-- update the bet value on the old highest pot number to the contribution of the player going all in
					FOR v_i IN p_poker_state.pot.FIRST .. p_poker_state.pot.LAST LOOP
						IF p_poker_state.pot(v_i).pot_number = v_round_highest_pot_number
						   AND p_poker_state.pot(v_i).betting_round_number = NVL(p_poker_state.betting_round_number, 1) THEN
							p_poker_state.pot(v_i).bet_value := v_highest_pot_total_contr;
							EXIT;
						END IF;
					END LOOP;

					-- update the player contributions on the old highest pot number to the contribution of the
					-- player going all in for all players who's contributions rolled into the next pot
					FOR v_i IN p_poker_state.pot_contribution.FIRST .. p_poker_state.pot_contribution.LAST LOOP
						IF p_poker_state.pot_contribution(v_i).pot_number = v_round_highest_pot_number
						   AND p_poker_state.pot_contribution(v_i).betting_round_number = NVL(p_poker_state.betting_round_number, 1)
						   AND p_poker_state.pot_contribution(v_i).player_seat_number != p_player_seat_number
						   AND p_poker_state.pot_contribution(v_i).pot_contribution > v_highest_pot_total_contr THEN
							p_poker_state.pot_contribution(v_i).pot_contribution := v_highest_pot_total_contr;
						END IF;
					END LOOP;
					
				ELSIF v_highest_pot_total_contr > v_highest_pot_bet_value THEN
				
					-- player is increasing the bet value.  If any other contributors to this pot are all in, need to split pot
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END need_side_pot
					INTO   v_need_side_pot
					FROM   TABLE(p_poker_state.pot_contribution) pc,
						   TABLE(p_poker_state.player_state) ps
					WHERE  pc.pot_number = v_round_highest_pot_number
					   AND pc.betting_round_number = NVL(p_poker_state.betting_round_number, 1)
					   AND pc.player_seat_number != p_player_seat_number
					   AND pc.player_seat_number = ps.seat_number
					   AND ps.state = 'ALL_IN';
					   
					IF v_need_side_pot = 'Y' THEN
			
						-- create new pot
						v_pot_rec.pot_number := v_round_highest_pot_number + 1;
						v_pot_rec.betting_round_number := NVL(p_poker_state.betting_round_number, 1);
						v_pot_rec.bet_value := v_highest_pot_total_contr - v_highest_pot_bet_value;
						p_poker_state.pot.EXTEND(1);
						p_poker_state.pot(p_poker_state.pot.LAST) := v_pot_rec;

						-- move balance of player's contribution into new pot
						v_pot_contribution_rec.pot_number := v_round_highest_pot_number + 1;
						v_pot_contribution_rec.betting_round_number := NVL(p_poker_state.betting_round_number, 1);
						v_pot_contribution_rec.player_seat_number := p_player_seat_number;
						v_pot_contribution_rec.pot_contribution := v_highest_pot_total_contr - v_highest_pot_bet_value;
						p_poker_state.pot_contribution.EXTEND(1);
						p_poker_state.pot_contribution(p_poker_state.pot_contribution.LAST) := v_pot_contribution_rec;

						-- update the player contribution on the old highest pot number to the contribution of the player going all in
						FOR v_i IN p_poker_state.pot_contribution.FIRST .. p_poker_state.pot_contribution.LAST LOOP
							IF p_poker_state.pot_contribution(v_i).pot_number = v_round_highest_pot_number
							   AND p_poker_state.pot_contribution(v_i).betting_round_number = NVL(p_poker_state.betting_round_number, 1)
							   AND p_poker_state.pot_contribution(v_i).player_seat_number = p_player_seat_number THEN
								p_poker_state.pot_contribution(v_i).pot_contribution := v_highest_pot_bet_value;
								EXIT;
							END IF;
						END LOOP;
						
					ELSE
					
						-- new pot not needed, just increase bet value of highest pot
						FOR v_i IN p_poker_state.pot.FIRST .. p_poker_state.pot.LAST LOOP
							IF p_poker_state.pot(v_i).pot_number = v_round_highest_pot_number
							   AND p_poker_state.pot(v_i).betting_round_number = NVL(p_poker_state.betting_round_number, 1) THEN
								p_poker_state.pot(v_i).bet_value := v_highest_pot_total_contr;
								EXIT;
							END IF;
						END LOOP;
						
					END IF;
					
				END IF;
				
			END IF;
			
			-- abort loop if the player has no more money to contribute to further pots
			EXIT WHEN v_total_pot_contribution = 0;
			
		END LOOP;
	
	END IF;
	
	-- remove money from player's stack and flag all in state when needed
	IF p_poker_state.player_state(p_player_seat_number).money - p_pot_contribution = 0 THEN
		p_poker_state.player_state(p_player_seat_number).state := 'ALL_IN';
		p_poker_state.player_state(p_player_seat_number).times_all_in := p_poker_state.player_state(p_player_seat_number).times_all_in + 1;
	END IF;
	p_poker_state.player_state(p_player_seat_number).money :=
		p_poker_state.player_state(p_player_seat_number).money - p_pot_contribution;
	p_poker_state.player_state(p_player_seat_number).total_money_played :=
		p_poker_state.player_state(p_player_seat_number).total_money_played + p_pot_contribution;

	pkg_poker_ai.issue_applicable_pot_refunds(p_poker_state => p_poker_state);
	
END contribute_to_pot;

PROCEDURE issue_applicable_pot_refunds(
	p_poker_state IN OUT t_poker_state
) IS

	v_index                INTEGER;
	v_new_pot_contribution t_tbl_pot_contribution := t_tbl_pot_contribution();
	v_new_pot              t_tbl_pot := t_tbl_pot();
	
BEGIN

	-- if there are any pots that only have one contributor and all the other active players are all in,
	-- refund to the pot contributor and delete the pot
	FOR v_rec IN (
		WITH sole_contributor_pots AS (
			SELECT pot_number,
				   MIN(player_seat_number) sole_contributor,
				   SUM(pot_contribution) pot_contribution
			FROM   TABLE(p_poker_state.pot_contribution)
			GROUP BY pot_number
			HAVING COUNT(DISTINCT player_seat_number) = 1
		)

		SELECT scp.pot_number,
			   scp.sole_contributor,
			   scp.pot_contribution
		FROM   sole_contributor_pots scp,
			   TABLE(p_poker_state.player_state) ps
		WHERE  scp.sole_contributor != ps.seat_number
		   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		GROUP BY
			scp.pot_number,
			scp.sole_contributor,
			scp.pot_contribution
		HAVING SUM(CASE WHEN ps.state = 'ALL_IN' THEN 1 ELSE 0 END) = COUNT(*)
	) LOOP
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'refunding ' || v_rec.pot_contribution || ' back to player at seat '
				|| v_rec.sole_contributor || ' from pot ' || v_rec.pot_number
		);
		
		IF p_poker_state.player_state(v_rec.sole_contributor).state = 'ALL_IN' THEN
			p_poker_state.player_state(v_rec.sole_contributor).state := 'RAISED';
		END IF;
		p_poker_state.player_state(v_rec.sole_contributor).money :=
			p_poker_state.player_state(v_rec.sole_contributor).money + v_rec.pot_contribution;
		p_poker_state.player_state(v_rec.sole_contributor).total_money_played :=
			p_poker_state.player_state(v_rec.sole_contributor).total_money_played - v_rec.pot_contribution;
		
		-- condense pot contribution collection, culling out this pot being removed
		v_index := p_poker_state.pot_contribution.FIRST;
		WHILE v_index IS NOT NULL LOOP
			IF p_poker_state.pot_contribution(v_index).pot_number != v_rec.pot_number THEN
				v_new_pot_contribution.EXTEND(1);
				v_new_pot_contribution(v_new_pot_contribution.LAST) := p_poker_state.pot_contribution(v_index);
			END IF;
			v_index := p_poker_state.pot_contribution.NEXT(v_index);
		END LOOP;
		p_poker_state.pot_contribution := v_new_pot_contribution;
		
		-- condense pot contribution collection, culling out this pot being removed
		v_index := p_poker_state.pot.FIRST;
		WHILE v_index IS NOT NULL LOOP
			IF p_poker_state.pot(v_index).pot_number != v_rec.pot_number THEN
				v_new_pot.EXTEND(1);
				v_new_pot(v_new_pot.LAST) := p_poker_state.pot(v_index);
			END IF;
			v_index := p_poker_state.pot.NEXT(v_index);
		END LOOP;
		p_poker_state.pot := v_new_pot;
		
	END LOOP;
	
END issue_applicable_pot_refunds;

PROCEDURE issue_default_pot_wins(
	p_poker_state IN OUT t_poker_state
) IS

	v_index                INTEGER;
	v_new_pot_contribution t_tbl_pot_contribution := t_tbl_pot_contribution();
	v_new_pot              t_tbl_pot := t_tbl_pot();
	
BEGIN

	-- if all non-all in players but one player fold on a given pot, by default the non-folded
	-- contributor wins the pot
	FOR v_rec IN (
		WITH pot_contributions AS (
			SELECT ps.seat_number,
				   ps.state,
				   pc.pot_number,
				   SUM(pc.pot_contribution) pot_contribution
			FROM   TABLE(p_poker_state.player_state) ps,
				   TABLE(p_poker_state.pot_contribution) pc
			WHERE  ps.seat_number = pc.player_seat_number (+)
			GROUP BY
				ps.seat_number,
				ps.state,
				pc.pot_number
		),       

		pots_w_1_non_folded_contrib AS (
			SELECT pot_number,
				   MIN(CASE WHEN state != 'FOLDED' THEN seat_number END) pot_winner,
				   SUM(pot_contribution) win_amount
			FROM   pot_contributions
			GROUP BY pot_number
			HAVING SUM(CASE WHEN state = 'FOLDED' THEN 1 ELSE 0 END) = COUNT(*) - 1
		)

		SELECT w.pot_number,
			   w.pot_winner,
			   w.win_amount
		FROM   pot_contributions pc,
			   pots_w_1_non_folded_contrib w
		WHERE  pc.pot_number != w.pot_number
		   AND pc.seat_number != w.pot_winner
		GROUP BY
			w.pot_number,
			w.pot_winner,
			w.win_amount
		HAVING SUM(CASE WHEN pc.state NOT IN ('FOLDED', 'ALL_IN') THEN 1 ELSE 0 END) = 0
	) LOOP
	
		pkg_poker_ai.log(
			p_state_id => p_poker_state.current_state_id,
			p_message  => 'by default, player at seat ' || v_rec.pot_winner || ' wins '
				|| v_rec.win_amount || ' from pot ' || v_rec.pot_number
		);

		IF p_poker_state.player_state(v_rec.pot_winner).state = 'ALL_IN' THEN
			p_poker_state.player_state(v_rec.pot_winner).state := 'RAISED';
		END IF;
		p_poker_state.player_state(v_rec.pot_winner).money :=
			p_poker_state.player_state(v_rec.pot_winner).money + v_rec.win_amount;
		p_poker_state.player_state(v_rec.pot_winner).total_money_won :=
			p_poker_state.player_state(v_rec.pot_winner).total_money_won + v_rec.win_amount;

		-- condense pot contribution collection, culling out this pot being removed
		v_index := p_poker_state.pot_contribution.FIRST;
		WHILE v_index IS NOT NULL LOOP
			IF p_poker_state.pot_contribution(v_index).pot_number != v_rec.pot_number THEN
				v_new_pot_contribution.EXTEND(1);
				v_new_pot_contribution(v_new_pot_contribution.LAST) := p_poker_state.pot_contribution(v_index);
			END IF;
			v_index := p_poker_state.pot_contribution.NEXT(v_index);
		END LOOP;
		p_poker_state.pot_contribution := v_new_pot_contribution;
		
		-- condense pot contribution collection, culling out this pot being removed
		v_index := p_poker_state.pot.FIRST;
		WHILE v_index IS NOT NULL LOOP
			IF p_poker_state.pot(v_index).pot_number != v_rec.pot_number THEN
				v_new_pot.EXTEND(1);
				v_new_pot(v_new_pot.LAST) := p_poker_state.pot(v_index);
			END IF;
			v_index := p_poker_state.pot.NEXT(v_index);
		END LOOP;
		p_poker_state.pot := v_new_pot;

	END LOOP;
	
END issue_default_pot_wins;

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

PROCEDURE log(
	p_message poker_ai_log.message%TYPE
) IS
BEGIN

	pkg_poker_ai.log(
		p_state_id => 0,
		p_message  => p_message
	);
	
END log;

PROCEDURE capture_state_log(
	p_poker_state t_poker_state
) IS
BEGIN

	DELETE FROM poker_state_log WHERE state_id = p_poker_state.current_state_id;
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
		p_poker_state.current_state_id,
		p_poker_state.tournament_id,
		p_poker_state.tournament_mode,
		p_poker_state.evolution_trial_id,
		p_poker_state.player_count,
		p_poker_state.buy_in_amount,
		p_poker_state.tournament_in_progress,
		p_poker_state.current_game_number,
		p_poker_state.game_in_progress,
		p_poker_state.small_blind_seat_number,
		p_poker_state.big_blind_seat_number,
		p_poker_state.turn_seat_number,
		p_poker_state.small_blind_value,
		p_poker_state.big_blind_value,
		p_poker_state.betting_round_number,
		p_poker_state.betting_round_in_progress,
		p_poker_state.last_to_raise_seat_number,
		p_poker_state.min_raise_amount,
		p_poker_state.community_card_1,
		p_poker_state.community_card_2,
		p_poker_state.community_card_3,
		p_poker_state.community_card_4,
		p_poker_state.community_card_5
	);
	
	DELETE FROM player_state_log WHERE state_id = p_poker_state.current_state_id;
	INSERT INTO player_state_log(
		state_id,
		seat_number,
		player_id,
		current_strategy_id,
		assumed_strategy_id,
		hole_card_1,
		hole_card_2,
		best_hand_combination,
		best_hand_rank,
		best_hand_card_1,
		best_hand_card_2,
		best_hand_card_3,
		best_hand_card_4,
		best_hand_card_5,
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
	)
	SELECT p_poker_state.current_state_id state_id,
		   seat_number,
		   player_id,
		   current_strategy_id,
		   assumed_strategy_id,
		   hole_card_1,
		   hole_card_2,
		   best_hand_combination,
		   best_hand_rank,
		   best_hand_card_1,
		   best_hand_card_2,
		   best_hand_card_3,
		   best_hand_card_4,
		   best_hand_card_5,
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
	FROM   TABLE(p_poker_state.player_state);
	
	DELETE FROM pot_log WHERE state_id = p_poker_state.current_state_id;
	INSERT INTO pot_log(
		state_id,
		pot_number,
		betting_round_number,
		bet_value
	)
	SELECT p_poker_state.current_state_id state_id,
		   pot_number,
		   betting_round_number,
		   bet_value
	FROM   TABLE(p_poker_state.pot);

	DELETE FROM pot_contribution_log WHERE state_id = p_poker_state.current_state_id;
	INSERT INTO pot_contribution_log(
		state_id,
		pot_number,
		betting_round_number,
		player_seat_number,
		pot_contribution
	)
	SELECT p_poker_state.current_state_id state_id,
		   pot_number,
		   betting_round_number,
		   player_seat_number,
		   pot_contribution
	FROM   TABLE(p_poker_state.pot_contribution);

	COMMIT;
	
END capture_state_log;

FUNCTION get_poker_state(
	p_state_id poker_state_log.state_id%TYPE
) RETURN t_poker_state IS

	v_poker_state      t_poker_state;
	v_player_state     t_row_player_state;
	v_pot              t_row_pot;
	v_pot_contribution t_row_pot_contribution;
	
BEGIN

	v_poker_state := t_poker_state(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		t_tbl_player_state(), t_tbl_pot(), t_tbl_pot_contribution(), NULL);
	v_player_state := t_row_player_state(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
	v_pot := t_row_pot(NULL, NULL, NULL);
	v_pot_contribution := t_row_pot_contribution(NULL, NULL, NULL, NULL);
		
	FOR v_rec IN (
		SELECT *
		FROM   poker_state_log
		WHERE  state_id = p_state_id
	) LOOP
		v_poker_state.tournament_id := v_rec.tournament_id;
		v_poker_state.tournament_mode := v_rec.tournament_mode;
		v_poker_state.current_state_id := p_state_id;
		v_poker_state.evolution_trial_id := v_rec.evolution_trial_id;
		v_poker_state.player_count := v_rec.player_count;
		v_poker_state.buy_in_amount := v_rec.buy_in_amount;
		v_poker_state.tournament_in_progress := v_rec.tournament_in_progress;
		v_poker_state.current_game_number := v_rec.current_game_number;
		v_poker_state.game_in_progress := v_rec.game_in_progress;
		v_poker_state.small_blind_seat_number := v_rec.small_blind_seat_number;
		v_poker_state.big_blind_seat_number := v_rec.big_blind_seat_number;
		v_poker_state.turn_seat_number := v_rec.turn_seat_number;
		v_poker_state.small_blind_value := v_rec.small_blind_value;
		v_poker_state.big_blind_value := v_rec.big_blind_value;
		v_poker_state.betting_round_number := v_rec.betting_round_number;
		v_poker_state.betting_round_in_progress := v_rec.betting_round_in_progress;
		v_poker_state.last_to_raise_seat_number := v_rec.last_to_raise_seat_number;
		v_poker_state.min_raise_amount := v_rec.min_raise_amount;
		v_poker_state.community_card_1 := v_rec.community_card_1;
		v_poker_state.community_card_2 := v_rec.community_card_2;
		v_poker_state.community_card_3 := v_rec.community_card_3;
		v_poker_state.community_card_4 := v_rec.community_card_4;
		v_poker_state.community_card_5 := v_rec.community_card_5;
	END LOOP;
	
	FOR v_rec IN (
		SELECT *
		FROM   player_state_log
		WHERE  state_id = p_state_id
		ORDER BY seat_number
	) LOOP
		v_player_state.seat_number := v_rec.seat_number;
		v_player_state.player_id := v_rec.player_id;
		v_player_state.current_strategy_id := v_rec.current_strategy_id;
		v_player_state.assumed_strategy_id := v_rec.assumed_strategy_id;
		v_player_state.hole_card_1 := v_rec.hole_card_1;
		v_player_state.hole_card_2 := v_rec.hole_card_2;
		v_player_state.best_hand_combination := v_rec.best_hand_combination;
		v_player_state.best_hand_rank := v_rec.best_hand_rank;
		v_player_state.best_hand_card_1 := v_rec.best_hand_card_1;
		v_player_state.best_hand_card_2 := v_rec.best_hand_card_2;
		v_player_state.best_hand_card_3 := v_rec.best_hand_card_3;
		v_player_state.best_hand_card_4 := v_rec.best_hand_card_4;
		v_player_state.best_hand_card_5 := v_rec.best_hand_card_5;
		v_player_state.hand_showing := v_rec.hand_showing;
		v_player_state.presented_bet_opportunity := v_rec.presented_bet_opportunity;
		v_player_state.money := v_rec.money;
		v_player_state.state := v_rec.state;
		v_player_state.game_rank := v_rec.game_rank;
		v_player_state.tournament_rank := v_rec.tournament_rank;
		v_player_state.games_played := v_rec.games_played;
		v_player_state.main_pots_won := v_rec.main_pots_won;
		v_player_state.main_pots_split := v_rec.main_pots_split;
		v_player_state.side_pots_won := v_rec.side_pots_won;
		v_player_state.side_pots_split := v_rec.side_pots_split;
		v_player_state.average_game_profit := v_rec.average_game_profit;
		v_player_state.flops_seen := v_rec.flops_seen;
		v_player_state.turns_seen := v_rec.turns_seen;
		v_player_state.rivers_seen := v_rec.rivers_seen;
		v_player_state.pre_flop_folds := v_rec.pre_flop_folds;
		v_player_state.flop_folds := v_rec.flop_folds;
		v_player_state.turn_folds := v_rec.turn_folds;
		v_player_state.river_folds := v_rec.river_folds;
		v_player_state.total_folds := v_rec.total_folds;
		v_player_state.pre_flop_checks := v_rec.pre_flop_checks;
		v_player_state.flop_checks := v_rec.flop_checks;
		v_player_state.turn_checks := v_rec.turn_checks;
		v_player_state.river_checks := v_rec.river_checks;
		v_player_state.total_checks := v_rec.total_checks;
		v_player_state.pre_flop_calls := v_rec.pre_flop_calls;
		v_player_state.flop_calls := v_rec.flop_calls;
		v_player_state.turn_calls := v_rec.turn_calls;
		v_player_state.river_calls := v_rec.river_calls;
		v_player_state.total_calls := v_rec.total_calls;
		v_player_state.pre_flop_bets := v_rec.pre_flop_bets;
		v_player_state.flop_bets := v_rec.flop_bets;
		v_player_state.turn_bets := v_rec.turn_bets;
		v_player_state.river_bets := v_rec.river_bets;
		v_player_state.total_bets := v_rec.total_bets;
		v_player_state.pre_flop_total_bet_amount := v_rec.pre_flop_total_bet_amount;
		v_player_state.flop_total_bet_amount := v_rec.flop_total_bet_amount;
		v_player_state.turn_total_bet_amount := v_rec.turn_total_bet_amount;
		v_player_state.river_total_bet_amount := v_rec.river_total_bet_amount;
		v_player_state.total_bet_amount := v_rec.total_bet_amount;
		v_player_state.pre_flop_average_bet_amount := v_rec.pre_flop_average_bet_amount;
		v_player_state.flop_average_bet_amount := v_rec.flop_average_bet_amount;
		v_player_state.turn_average_bet_amount := v_rec.turn_average_bet_amount;
		v_player_state.river_average_bet_amount := v_rec.river_average_bet_amount;
		v_player_state.average_bet_amount := v_rec.average_bet_amount;
		v_player_state.pre_flop_raises := v_rec.pre_flop_raises;
		v_player_state.flop_raises := v_rec.flop_raises;
		v_player_state.turn_raises := v_rec.turn_raises;
		v_player_state.river_raises := v_rec.river_raises;
		v_player_state.total_raises := v_rec.total_raises;
		v_player_state.pre_flop_total_raise_amount := v_rec.pre_flop_total_raise_amount;
		v_player_state.flop_total_raise_amount := v_rec.flop_total_raise_amount;
		v_player_state.turn_total_raise_amount := v_rec.turn_total_raise_amount;
		v_player_state.river_total_raise_amount := v_rec.river_total_raise_amount;
		v_player_state.total_raise_amount := v_rec.total_raise_amount;
		v_player_state.pre_flop_average_raise_amount := v_rec.pre_flop_average_raise_amount;
		v_player_state.flop_average_raise_amount := v_rec.flop_average_raise_amount;
		v_player_state.turn_average_raise_amount := v_rec.turn_average_raise_amount;
		v_player_state.river_average_raise_amount := v_rec.river_average_raise_amount;
		v_player_state.average_raise_amount := v_rec.average_raise_amount;
		v_player_state.times_all_in := v_rec.times_all_in;
		v_player_state.total_money_played := v_rec.total_money_played;
		v_player_state.total_money_won := v_rec.total_money_won;
		v_poker_state.player_state.EXTEND(1);
		v_poker_state.player_state(v_player_state.seat_number) := v_player_state;
	END LOOP;

	FOR v_rec IN (
		SELECT *
		FROM   pot_log
		WHERE  state_id = p_state_id
		ORDER BY
			pot_number,
			betting_round_number
	) LOOP
		v_pot.pot_number := v_rec.pot_number;
		v_pot.betting_round_number := v_rec.betting_round_number;
		v_pot.bet_value := v_rec.bet_value;
		v_poker_state.pot.EXTEND(1);
		v_poker_state.pot(v_poker_state.pot.LAST) := v_pot;
	END LOOP;
		
	FOR v_rec IN (
		SELECT *
		FROM   pot_contribution_log
		WHERE  state_id = p_state_id
		ORDER BY
			pot_number,
			betting_round_number,
			player_seat_number
	) LOOP
		v_pot_contribution.pot_number := v_rec.pot_number;
		v_pot_contribution.betting_round_number := v_rec.betting_round_number;
		v_pot_contribution.player_seat_number := v_rec.player_seat_number;
		v_pot_contribution.pot_contribution := v_rec.pot_contribution;
		v_poker_state.pot_contribution.EXTEND(1);
		v_poker_state.pot_contribution(v_poker_state.pot_contribution.LAST) := v_pot_contribution;
	END LOOP;
	
	v_poker_state.deck := pkg_poker_ai.initialize_deck;
	FOR v_rec IN (
		SELECT hole_card_1 card_id FROM TABLE(v_poker_state.player_state) UNION ALL 
		SELECT hole_card_2 card_id FROM TABLE(v_poker_state.player_state) UNION ALL
		SELECT v_poker_state.community_card_1 card_id FROM DUAL UNION ALL
		SELECT v_poker_state.community_card_2 card_id FROM DUAL UNION ALL
		SELECT v_poker_state.community_card_3 card_id FROM DUAL UNION ALL
		SELECT v_poker_state.community_card_4 card_id FROM DUAL UNION ALL
		SELECT v_poker_state.community_card_5 card_id FROM DUAL
	) LOOP
	
		FOR v_i IN v_poker_state.deck.FIRST .. v_poker_state.deck.LAST LOOP
			IF v_rec.card_id IS NOT NULL AND v_rec.card_id != 0 AND v_poker_state.deck(v_i).card_id = v_rec.card_id THEN
				v_poker_state.deck(v_i).dealt := 'Y';
				EXIT;
			END IF;
		END LOOP;
		
	END LOOP;

	RETURN v_poker_state;
	
END get_poker_state;

END pkg_poker_ai;