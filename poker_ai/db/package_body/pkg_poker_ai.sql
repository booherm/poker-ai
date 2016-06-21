CREATE OR REPLACE PACKAGE BODY pkg_poker_ai AS

PROCEDURE play_tournament(
	p_strategy_ids              t_tbl_number,
	p_buy_in_amount             tournament_state.buy_in_amount%TYPE,
	p_initial_small_blind_value game_state.small_blind_value%TYPE,
	p_double_blinds_interval    tournament_state.current_game_number%TYPE,
	p_perform_state_logging     VARCHAR2
) IS

	v_max_games_in_tournament    tournament_state.current_game_number%TYPE:= 500;
	
	v_player_count               tournament_state.player_count%TYPE;
	v_tournament_in_progress     tournament_state.tournament_in_progress%TYPE;
	v_prev_iteration_game_number tournament_state.current_game_number%TYPE;
	v_current_game_number        tournament_state.current_game_number%TYPE;
	v_small_blind_value          game_state.small_blind_value%TYPE := p_initial_small_blind_value;

BEGIN

	pkg_poker_ai.log(p_message => 'playing automated tournament');
	
	SELECT COUNT(*) player_count
	INTO   v_player_count
	FROM   TABLE(p_strategy_ids);
	
	pkg_poker_ai.initialize_tournament(
		p_tournament_mode       => 'INTERNAL',
		p_strategy_ids          => p_strategy_ids,
		p_player_count          => v_player_count,
		p_buy_in_amount         => p_buy_in_amount,
		p_perform_state_logging => p_perform_state_logging
	);
	
	LOOP
		SELECT tournament_in_progress,
			   current_game_number
		INTO   v_tournament_in_progress,
			   v_current_game_number
		FROM   tournament_state;
		
		EXIT WHEN v_tournament_in_progress = 'N' OR v_current_game_number > v_max_games_in_tournament;
		
		IF v_prev_iteration_game_number != v_current_game_number AND MOD(v_current_game_number, p_double_blinds_interval) = 0 THEN
			v_small_blind_value := v_small_blind_value * 2;
			IF v_small_blind_value > p_buy_in_amount * v_player_count THEN
				v_small_blind_value := p_buy_in_amount * v_player_count;
			END IF;
		END IF;
		v_prev_iteration_game_number := v_current_game_number;
		
		pkg_poker_ai.step_play( 
			p_small_blind_value     => v_small_blind_value,
			p_player_move           => 'AUTO',
			p_player_move_amount    => NULL,
			p_perform_state_logging => p_perform_state_logging
		);
		
	END LOOP;
	
	IF v_current_game_number > v_max_games_in_tournament THEN
		pkg_poker_ai.log(p_message => 'maximum number of games in tournament exceeded');
	END IF;

	pkg_poker_ai.log(p_message => 'automated tournament complete');

END play_tournament;

PROCEDURE initialize_tournament
(
	p_tournament_mode       tournament_state.tournament_mode%TYPE,
	p_strategy_ids          t_tbl_number,
	p_player_count          tournament_state.player_count%TYPE,
    p_buy_in_amount         tournament_state.buy_in_amount%TYPE,
	p_perform_state_logging VARCHAR2
) IS
BEGIN

	IF p_perform_state_logging = 'Y' THEN
		v_state_id := pkg_poker_ai.get_state_id;
	END IF;
	
	-- init tournament state
	pkg_poker_ai.log(p_message => 'initializing ' || LOWER(p_tournament_mode) || ' tournament');
	DELETE FROM tournament_state;
	INSERT INTO tournament_state(
		tournament_mode,
		fitness_test_id,
		player_count,
		buy_in_amount,
		tournament_in_progress,
		current_game_number,
		game_in_progress,
		current_state_id
	) VALUES (
		p_tournament_mode,
		p_player_count || '_PLAYER_' || p_buy_in_amount || '_BUYIN',
		p_player_count,
		p_buy_in_amount,
		'Y',
		NULL,
		'N',
		v_state_id
	);

	-- clear game state
	pkg_poker_ai.clear_game_state;

	-- initialize deck
	pkg_poker_ai.initialize_deck;
	
	-- init players
	pkg_poker_ai.log(p_message => 'selecting ' || CASE WHEN p_strategy_ids IS NULL THEN 'random' ELSE 'specified strategies as' END || ' players');
	
	DELETE FROM player_state;
	INSERT INTO player_state(
		seat_number,
		current_strategy_id,
		hand_showing,
		money,
		state,
		presented_bet_opportunity,
		games_played,
		main_pots_won,
		main_pots_split,
		side_pots_won,
		side_pots_split,
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
		times_all_in,
		total_money_played,
		total_money_won
	)
	
	WITH seats AS (
		SELECT ROWNUM seat_number
		FROM   DUAL
		CONNECT BY ROWNUM <= p_player_count
	),
	
	strategies AS (
		SELECT ROWNUM seat_number,
			   value strategy_id
		FROM   TABLE(p_strategy_ids)
	),
	
	players AS (
		SELECT s.seat_number,
			   st.strategy_id
		FROM   seats s,
			   strategies st
		WHERE  s.seat_number = st.seat_number (+)
	)
	
	SELECT seat_number,
		   strategy_id current_strategy_id,
		   'N' hand_showing,
		   p_buy_in_amount money,
		   'NO_MOVE' state,
		   'N' presented_bet_opportunity,
		   0 games_played,
		   0 main_pots_won,
		   0 main_pots_split,
		   0 side_pots_won,
		   0 side_pots_split,
		   0 flops_seen,
		   0 turns_seen,
		   0 rivers_seen,
		   0 pre_flop_folds,
		   0 flop_folds,
		   0 turn_folds,
		   0 river_folds,
		   0 total_folds,
		   0 pre_flop_checks,
		   0 flop_checks,
		   0 turn_checks,
		   0 river_checks,
		   0 total_checks,
		   0 pre_flop_calls,
		   0 flop_calls,
		   0 turn_calls,
		   0 river_calls,
		   0 total_calls,
		   0 pre_flop_bets,
		   0 flop_bets,
		   0 turn_bets,
		   0 river_bets,
		   0 total_bets,
		   0 pre_flop_total_bet_amount,
		   0 flop_total_bet_amount,
		   0 turn_total_bet_amount,
		   0 river_total_bet_amount,
		   0 total_bet_amount,
		   0 pre_flop_raises,
		   0 flop_raises,
		   0 turn_raises,
		   0 river_raises,
		   0 total_raises,
		   0 pre_flop_total_raise_amount,
		   0 flop_total_raise_amount,
		   0 turn_total_raise_amount,
		   0 river_total_raise_amount,
		   0 total_raise_amount,
		   0 times_all_in,
		   0 total_money_played,
		   0 total_money_won
	FROM   players;

	pkg_poker_ai.log(p_message => 'tournament initialized');
	
	IF p_perform_state_logging = 'Y' THEN
		pkg_poker_ai.capture_state_log;
	END IF;
	
	COMMIT;
	
END initialize_tournament;

PROCEDURE initialize_deck IS
BEGIN

	DELETE FROM deck;
	INSERT INTO deck(
		card_id,
		suit,
		display_value,
		value,
		dealt
	)

	SELECT 0  card_id,  NULL      suit, 'N/A'  display_value, NULL value, 'N' dealt FROM DUAL UNION ALL
	SELECT 1  card_id, 'HEARTS'   suit, '2 H'  display_value,    2 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 2  card_id, 'HEARTS'   suit, '3 H'  display_value,    3 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 3  card_id, 'HEARTS'   suit, '4 H'  display_value,    4 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 4  card_id, 'HEARTS'   suit, '5 H'  display_value,    5 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 5  card_id, 'HEARTS'   suit, '6 H'  display_value,    6 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 6  card_id, 'HEARTS'   suit, '7 H'  display_value,    7 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 7  card_id, 'HEARTS'   suit, '8 H'  display_value,    8 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 8  card_id, 'HEARTS'   suit, '9 H'  display_value,    9 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 9  card_id, 'HEARTS'   suit, '10 H' display_value,   10 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 10 card_id, 'HEARTS'   suit, 'J H'  display_value,   11 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 11 card_id, 'HEARTS'   suit, 'Q H'  display_value,   12 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 12 card_id, 'HEARTS'   suit, 'K H'  display_value,   13 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 13 card_id, 'HEARTS'   suit, 'A H'  display_value,   14 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 14 card_id, 'DIAMONDS' suit, '2 D'  display_value,    2 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 15 card_id, 'DIAMONDS' suit, '3 D'  display_value,    3 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 16 card_id, 'DIAMONDS' suit, '4 D'  display_value,    4 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 17 card_id, 'DIAMONDS' suit, '5 D'  display_value,    5 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 18 card_id, 'DIAMONDS' suit, '6 D'  display_value,    6 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 19 card_id, 'DIAMONDS' suit, '7 D'  display_value,    7 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 20 card_id, 'DIAMONDS' suit, '8 D'  display_value,    8 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 21 card_id, 'DIAMONDS' suit, '9 D'  display_value,    9 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 22 card_id, 'DIAMONDS' suit, '10 D' display_value,   10 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 23 card_id, 'DIAMONDS' suit, 'J D'  display_value,   11 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 24 card_id, 'DIAMONDS' suit, 'Q D'  display_value,   12 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 25 card_id, 'DIAMONDS' suit, 'K D'  display_value,   13 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 26 card_id, 'DIAMONDS' suit, 'A D'  display_value,   14 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 27 card_id, 'SPADES'   suit, '2 S'  display_value,    2 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 28 card_id, 'SPADES'   suit, '3 S'  display_value,    3 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 29 card_id, 'SPADES'   suit, '4 S'  display_value,    4 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 30 card_id, 'SPADES'   suit, '5 S'  display_value,    5 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 31 card_id, 'SPADES'   suit, '6 S'  display_value,    6 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 32 card_id, 'SPADES'   suit, '7 S'  display_value,    7 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 33 card_id, 'SPADES'   suit, '8 S'  display_value,    8 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 34 card_id, 'SPADES'   suit, '9 S'  display_value,    9 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 35 card_id, 'SPADES'   suit, '10 S' display_value,   10 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 36 card_id, 'SPADES'   suit, 'J S'  display_value,   11 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 37 card_id, 'SPADES'   suit, 'Q S'  display_value,   12 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 38 card_id, 'SPADES'   suit, 'K S'  display_value,   13 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 39 card_id, 'SPADES'   suit, 'A S'  display_value,   14 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 40 card_id, 'CLUBS'    suit, '2 C'  display_value,    2 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 41 card_id, 'CLUBS'    suit, '3 C'  display_value,    3 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 42 card_id, 'CLUBS'    suit, '4 C'  display_value,    4 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 43 card_id, 'CLUBS'    suit, '5 C'  display_value,    5 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 44 card_id, 'CLUBS'    suit, '6 C'  display_value,    6 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 45 card_id, 'CLUBS'    suit, '7 C'  display_value,    7 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 46 card_id, 'CLUBS'    suit, '8 C'  display_value,    8 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 47 card_id, 'CLUBS'    suit, '9 C'  display_value,    9 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 48 card_id, 'CLUBS'    suit, '10 C' display_value,   10 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 49 card_id, 'CLUBS'    suit, 'J C'  display_value,   11 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 50 card_id, 'CLUBS'    suit, 'Q C'  display_value,   12 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 51 card_id, 'CLUBS'    suit, 'K C'  display_value,   13 value, 'N' dealt FROM DUAL UNION ALL
	SELECT 52 card_id, 'CLUBS'    suit, 'A C'  display_value,   14 value, 'N' dealt FROM DUAL;
	
END initialize_deck;

PROCEDURE step_play( 
	p_small_blind_value     game_state.small_blind_value%TYPE,
	p_player_move           VARCHAR2,
	p_player_move_amount    player_state.money%TYPE,
	p_perform_state_logging VARCHAR2
) IS

	v_tournament_mode           tournament_state.tournament_mode%TYPE;
	v_remaining_player_count    tournament_state.player_count%TYPE;
	v_game_in_progress          tournament_state.game_in_progress%TYPE;
	v_current_game_number       tournament_state.current_game_number%TYPE;
	v_small_blind_seat_number   game_state.small_blind_seat_number%TYPE;
	v_betting_round_number      game_state.betting_round_number%TYPE;
	v_betting_round_in_progress game_state.betting_round_in_progress%TYPE;
	v_turn_seat_number          game_state.turn_seat_number%TYPE;
	v_uneven_pot                VARCHAR2(1);
	v_next_player               game_state.small_blind_seat_number%TYPE;
	v_bet_opp_not_presented     player_state.presented_bet_opportunity%TYPE;

BEGIN

	-- assumed tournament has been initialized
	IF p_perform_state_logging = 'Y' THEN
		v_state_id := pkg_poker_ai.get_state_id;
		UPDATE tournament_state
		SET    current_state_id = v_state_id;
	END IF;
	
	-- determine how many active players remain
	SELECT COUNT(*) remaining_player_count
	INTO   v_remaining_player_count
	FROM   player_state
	WHERE  state != 'OUT_OF_TOURNAMENT';

	IF v_remaining_player_count > 1 THEN
		
		SELECT tournament_mode,
			   game_in_progress,
			   current_game_number
		INTO   v_tournament_mode,
			   v_game_in_progress,
			   v_current_game_number
		FROM   tournament_state;

		IF v_game_in_progress = 'N' THEN

			-- start a new game
			IF v_current_game_number IS NULL THEN
				v_small_blind_seat_number := 1;
			ELSE
				-- determine next small blind seat
				SELECT small_blind_seat_number
				INTO   v_small_blind_seat_number
				FROM   game_state;

				pkg_poker_ai.log(p_message => 'advancing small blind seat');
				v_small_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(
					p_current_player_seat_number => v_small_blind_seat_number,
					p_include_folded_players     => 'Y',
					p_include_all_in_players     => 'Y'
				);
			END IF;

			pkg_poker_ai.initialize_game(
				p_small_blind_seat_number => v_small_blind_seat_number,
				p_small_blind_value       => p_small_blind_value
			);

			UPDATE tournament_state
			SET    current_game_number = NVL(current_game_number, 0) + 1,
				   game_in_progress = 'Y';
			
		ELSE

			-- game is currently in progress

			-- determine round
			SELECT betting_round_in_progress,
				   betting_round_number,
				   turn_seat_number
			INTO   v_betting_round_in_progress,
				   v_betting_round_number,
				   v_turn_seat_number
			FROM   game_state;

			IF v_betting_round_in_progress = 'N' THEN

				-- no betting round currently in progress, start new betting round or enter showdown

				IF v_betting_round_number IS NULL THEN
					-- pre-flop betting round, post blinds
					pkg_poker_ai.post_blinds;

					-- deal hole cards
					pkg_poker_ai.log(p_message => 'dealing hole cards');
					UPDATE player_state
					SET    hole_card_1 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END,
						   hole_card_2 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END,
						   games_played = games_played + 1
					WHERE  state != 'OUT_OF_TOURNAMENT';
					
				ELSIF v_betting_round_number = 1 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- update flops seen stat
					UPDATE player_state
					SET    flops_seen = flops_seen + 1
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT');
					
					-- reset player turn
					v_turn_seat_number := pkg_poker_ai.init_betting_round_start_seat;

					-- deal flop
					pkg_poker_ai.log(p_message => 'dealing flop');
					UPDATE game_state
					SET    community_card_1 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END,
						   community_card_2 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END,
						   community_card_3 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END;

					pkg_poker_ai.calculate_best_hands;
					pkg_poker_ai.sort_hands;

				ELSIF v_betting_round_number = 2 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- update turns seen stat
					UPDATE player_state
					SET    turns_seen = turns_seen + 1
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT');

					-- reset player turn
					v_turn_seat_number := pkg_poker_ai.init_betting_round_start_seat;
					
					-- deal turn
					pkg_poker_ai.log(p_message => 'dealing turn');
					UPDATE game_state
					SET    community_card_4 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END;

					pkg_poker_ai.calculate_best_hands;
					pkg_poker_ai.sort_hands;

				ELSIF v_betting_round_number = 3 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- update rivers seen stat
					UPDATE player_state
					SET    rivers_seen = rivers_seen + 1
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT');
					
					-- reset player turn
					v_turn_seat_number := pkg_poker_ai.init_betting_round_start_seat;

					-- deal river
					pkg_poker_ai.log(p_message => 'dealing river');
					UPDATE game_state
					SET    community_card_5 = CASE WHEN v_tournament_mode = 'INTERNAL' THEN pkg_poker_ai.draw_deck_card ELSE 0 END;

					pkg_poker_ai.calculate_best_hands;
					pkg_poker_ai.sort_hands;

				ELSIF v_betting_round_number = 4 THEN
					
					-- showdown
					pkg_poker_ai.process_game_results;
					UPDATE game_state
					SET    betting_round_number = NULL,
						   betting_round_in_progress = 'N';
					pkg_poker_ai.sort_hands;

				END IF;

				-- update to indicate betting round in progress
				IF v_betting_round_number IS NULL OR v_betting_round_number != 4 THEN
					UPDATE game_state
					SET    betting_round_number = NVL(betting_round_number, 0) + 1,
						   betting_round_in_progress = 'Y';
						   
					-- if no players can make a move, explicitly state that to the log
					IF v_turn_seat_number IS NULL THEN
						pkg_poker_ai.log(p_message => 'no players can make move');
					END IF;
					
				END IF;

			ELSE

				-- betting round is in progress, let player make move
				UPDATE player_state
				SET    presented_bet_opportunity = 'Y'
				WHERE  seat_number = v_turn_seat_number;
				
				pkg_poker_ai.perform_player_move(
					p_seat_number        => v_turn_seat_number,
					p_player_move        => p_player_move,
					p_player_move_amount => p_player_move_amount
				);

				IF pkg_poker_ai.get_active_player_count <= 1 THEN
					-- all players but one folded
					pkg_poker_ai.process_game_results;
				ELSE
					-- if the pots aren't even excluding all-in players, allow betting to continue
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END uneven_pot
					INTO   v_uneven_pot
					FROM   player_state
					WHERE  state != 'ALL_IN'
					   AND pkg_poker_ai.get_pot_deficit(p_seat_number => seat_number) > 0;

					-- if anyone has not been presented the opportunity to bet, proceed with betting
					v_next_player := pkg_poker_ai.get_next_active_seat_number(
						p_current_player_seat_number => v_turn_seat_number,
						p_include_folded_players     => 'N',
						p_include_all_in_players     => 'N'
					);
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_opportunity_not_presented
					INTO   v_bet_opp_not_presented
					FROM   player_state
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN')
					   AND presented_bet_opportunity = 'N';
				
					IF v_uneven_pot = 'Y' OR v_bet_opp_not_presented = 'Y' THEN
						-- betting continues, advance player
						UPDATE game_state
						SET    turn_seat_number = v_next_player;
					ELSE
						-- betting round over
						pkg_poker_ai.log(p_message => 'betting round over');
						
						UPDATE game_state
						SET    betting_round_in_progress = 'N';
						
					END IF;

				END IF;

			END IF;

		END IF;

	ELSE
	
		-- only one active player remains, process tournament results
		pkg_poker_ai.process_tournament_results;
		
	END IF;
	
	IF p_perform_state_logging = 'Y' THEN
		pkg_poker_ai.capture_state_log;
	END IF;
	
	COMMIT;
	
END step_play;

PROCEDURE clear_game_state IS
BEGIN

	-- clear pots
	pkg_poker_ai.log(p_message => 'clearing pots');
	DELETE FROM pot_contribution;
	DELETE FROM pot;

	-- reset deck
	pkg_poker_ai.log(p_message => 'resetting deck');
	UPDATE deck
	SET    dealt = 'N';

	DELETE FROM game_state;

END clear_game_state;

PROCEDURE initialize_game
(
	p_small_blind_seat_number game_state.small_blind_seat_number%TYPE,
    p_small_blind_value       game_state.small_blind_value%TYPE
) IS

	v_big_blind_seat_number game_state.big_blind_seat_number%TYPE;
	v_big_blind_value       game_state.big_blind_value%TYPE := p_small_blind_value * 2;
	v_turn_seat_number      game_state.turn_seat_number%TYPE;

BEGIN

	pkg_poker_ai.log(p_message => 'initializing game start');

	pkg_poker_ai.clear_game_state;

	-- initialize player state
	pkg_poker_ai.log(p_message => 'clearing player state cards and game rank');
	UPDATE player_state
	SET    hole_card_1 = NULL,
		   hole_card_2 = NULL,
		   best_hand_combination = NULL,
		   best_hand_rank = NULL,
		   best_hand_card_1 = NULL,
		   best_hand_card_2 = NULL,
		   best_hand_card_3 = NULL,
		   best_hand_card_4 = NULL,
		   best_hand_card_5 = NULL,
		   hand_showing = 'N',
		   presented_bet_opportunity = 'N',
		   state = CASE WHEN state = 'OUT_OF_TOURNAMENT' THEN 'OUT_OF_TOURNAMENT' ELSE 'NO_MOVE' END,
		   game_rank = NULL;

	-- determine seats
	v_big_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_current_player_seat_number => p_small_blind_seat_number,
		p_include_folded_players     => 'Y',
		p_include_all_in_players     => 'Y'
	);
	v_turn_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_current_player_seat_number => v_big_blind_seat_number,
		p_include_folded_players     => 'Y',
		p_include_all_in_players     => 'Y'
	);
	pkg_poker_ai.log(p_message => 'small blind = ' || p_small_blind_seat_number || ', big blind = ' || v_big_blind_seat_number
		|| ', UTG = ' || v_turn_seat_number);

	-- initialize game state
	INSERT INTO game_state(
        small_blind_seat_number,
		big_blind_seat_number,
		turn_seat_number,
        small_blind_value,
        big_blind_value,
        betting_round_number,
		betting_round_in_progress,
		min_raise_amount
    ) VALUES (
		p_small_blind_seat_number,
		v_big_blind_seat_number,
		v_turn_seat_number,
		p_small_blind_value,
		v_big_blind_value,
		NULL,
		'N',
		v_big_blind_value
	);
   
   pkg_poker_ai.log(p_message => 'game initialized');
   
END initialize_game;

FUNCTION get_active_player_count RETURN INTEGER IS

	v_active_players INTEGER;

BEGIN

	SELECT COUNT(*) active_players
	INTO   v_active_players
	FROM   player_state
	WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED');

	RETURN v_active_players;

END get_active_player_count;

FUNCTION get_next_active_seat_number
(
	p_current_player_seat_number player_state.seat_number%TYPE,
	p_include_folded_players     VARCHAR2,
	p_include_all_in_players     VARCHAR2
) RETURN player_state.seat_number%TYPE IS

	v_next_player_seat_number player_state.seat_number%TYPE;

BEGIN

	-- get the seat number of the next active player clockwise of current player
	SELECT MIN(seat_number) next_player_seat_number
	INTO   v_next_player_seat_number
	FROM   player_state
	WHERE  seat_number > p_current_player_seat_number
	   AND state != 'OUT_OF_TOURNAMENT'
	   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END
	   AND state != CASE WHEN p_include_all_in_players = 'N' THEN 'ALL_IN' ELSE '-X-' END;

	IF v_next_player_seat_number IS NULL THEN
		SELECT MIN(seat_number) next_player_seat_number
		INTO   v_next_player_seat_number
		FROM   player_state
		WHERE  seat_number < p_current_player_seat_number
		   AND state != 'OUT_OF_TOURNAMENT'
		   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END
		   AND state != CASE WHEN p_include_all_in_players = 'N' THEN 'ALL_IN' ELSE '-X-' END;
	END IF;

	RETURN v_next_player_seat_number;
	
END get_next_active_seat_number;

FUNCTION init_betting_round_start_seat RETURN player_state.seat_number%TYPE IS

	v_starting_seat player_state.seat_number%TYPE;
	
BEGIN

	-- get the seat number of the next active player clockwise of dealer
	SELECT MIN(ps.seat_number) starting_seat
	INTO   v_starting_seat
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number >= gs.small_blind_seat_number
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');

	IF v_starting_seat IS NULL THEN
		SELECT MIN(ps.seat_number) starting_seat
		INTO   v_starting_seat
		FROM   game_state gs,
			   player_state ps
		WHERE  ps.seat_number < gs.small_blind_seat_number
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');
	END IF;

	UPDATE game_state
	SET    turn_seat_number = v_starting_seat;
	
	RETURN v_starting_seat;

END init_betting_round_start_seat;

FUNCTION get_distance_from_small_blind (
	p_seat_number player_state.seat_number%TYPE
) RETURN INTEGER IS

	v_small_blind_seat_number player_state.seat_number%TYPE;
	v_distance                INTEGER;

BEGIN

	SELECT small_blind_seat_number
	INTO   v_small_blind_seat_number
	FROM   game_state;

	IF p_seat_number >= v_small_blind_seat_number THEN
		v_distance := p_seat_number - v_small_blind_seat_number;
	ELSE
		SELECT ((p_seat_number + player_count) - v_small_blind_seat_number) distance
		INTO   v_distance
		FROM   tournament_state;
	END IF;

	RETURN v_distance;
	
END get_distance_from_small_blind;

FUNCTION draw_deck_card RETURN deck.card_id%TYPE IS

	v_drawn_card_id deck.card_id%TYPE;

BEGIN

	-- draw a non-played card at random, mark as in play
	WITH remaining_deck AS (
		SELECT card_id
		FROM   deck
		WHERE  card_id != 0
		   AND dealt = 'N'
		ORDER BY DBMS_RANDOM.VALUE
	)
	SELECT card_id
	INTO   v_drawn_card_id
	FROM   remaining_deck
	WHERE  ROWNUM = 1;

	UPDATE deck
	SET    dealt = 'Y'
	WHERE  card_id = v_drawn_card_id;

	RETURN v_drawn_card_id;

END draw_deck_card;

PROCEDURE post_blinds IS

	v_small_blind_seat_number  game_state.small_blind_seat_number%TYPE;
	v_small_blind_player_money player_state.money%TYPE;
	v_small_blind_value        game_state.small_blind_value%TYPE;
	v_small_blind_post_amount  game_state.small_blind_value%TYPE;
	v_big_blind_seat_number    game_state.big_blind_seat_number%TYPE;
	v_big_blind_player_money   player_state.money%TYPE;
	v_big_blind_value          game_state.big_blind_value%TYPE;
	v_big_blind_post_amount    game_state.big_blind_value%TYPE;

BEGIN

	pkg_poker_ai.log(p_message => 'posting blinds');

	-- post small blind
	SELECT gs.small_blind_seat_number,
		   ps.money small_blind_player_money,
		   gs.small_blind_value
	INTO   v_small_blind_seat_number,
		   v_small_blind_player_money,
		   v_small_blind_value
	FROM   game_state gs,
		   player_state ps
	WHERE  gs.small_blind_seat_number = ps.seat_number;

	IF v_small_blind_player_money - v_small_blind_value < 0 THEN
		v_small_blind_post_amount := v_small_blind_player_money;
	ELSE
		v_small_blind_post_amount := v_small_blind_value;
	END IF;

	pkg_poker_ai.contribute_to_pot(
		p_player_seat_number => v_small_blind_seat_number,
		p_pot_contribution   => v_small_blind_post_amount
	);
	
	UPDATE player_state
	SET    pre_flop_bets = pre_flop_bets + 1,
		   total_bets = total_bets + 1,
		   pre_flop_total_bet_amount = pre_flop_total_bet_amount + v_small_blind_post_amount,
		   total_bet_amount = total_bet_amount + v_small_blind_post_amount		   
	WHERE  seat_number = v_small_blind_seat_number;

	UPDATE player_state
	SET    pre_flop_average_bet_amount = pre_flop_total_bet_amount / NULLIF(pre_flop_bets, 0),
		   average_bet_amount = total_bet_amount / NULLIF(total_bets, 0)
	WHERE  seat_number = v_small_blind_seat_number;

	-- post big blind
	SELECT gs.big_blind_seat_number,
		   ps.money big_blind_player_money,
		   gs.big_blind_value
	INTO   v_big_blind_seat_number,
		   v_big_blind_player_money,
		   v_big_blind_value
	FROM   game_state gs,
		   player_state ps
	WHERE  gs.big_blind_seat_number = ps.seat_number;

	IF v_big_blind_player_money - v_big_blind_value < 0 THEN
		v_big_blind_post_amount := v_big_blind_player_money;
	ELSE
		v_big_blind_post_amount := v_big_blind_value;
	END IF;

	pkg_poker_ai.contribute_to_pot(
		p_player_seat_number => v_big_blind_seat_number,
		p_pot_contribution   => v_big_blind_post_amount
	);

	IF v_big_blind_post_amount - v_small_blind_post_amount > 0 THEN
		UPDATE player_state
		SET    pre_flop_raises = pre_flop_raises + 1,
			   total_raises = total_raises + 1,
			   pre_flop_total_raise_amount = pre_flop_total_raise_amount + (v_big_blind_post_amount - v_small_blind_post_amount),
			   total_raise_amount = total_raise_amount + (v_big_blind_post_amount - v_small_blind_post_amount)	   
		WHERE  seat_number = v_big_blind_seat_number;
		
		UPDATE player_state
		SET    pre_flop_average_raise_amount = pre_flop_total_raise_amount / NULLIF(pre_flop_raises, 0),
			   average_raise_amount = total_raise_amount / NULLIF(total_raises, 0)
		WHERE  seat_number = v_big_blind_seat_number;
	END IF;
	
END post_blinds;

PROCEDURE perform_player_move
(
	p_seat_number        player_state.seat_number%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state.money%TYPE
) IS
BEGIN

	IF p_player_move = 'AUTO' THEN
		pkg_ga_player.perform_automatic_player_move(p_seat_number => p_seat_number);
	ELSE
		pkg_poker_ai.perform_explicit_player_move(
			p_seat_number        => p_seat_number,
			p_player_move        => p_player_move,
			p_player_move_amount => p_player_move_amount
		);
	END IF;
	
END perform_player_move;

PROCEDURE perform_explicit_player_move (
	p_seat_number        player_state.seat_number%TYPE,
	p_player_move        VARCHAR2,
	p_player_move_amount player_state.money%TYPE
) IS

	v_player_money          player_state.money%TYPE;
	v_current_betting_round game_state.betting_round_number%TYPE;

BEGIN

	SELECT betting_round_number current_betting_round
	INTO   v_current_betting_round
	FROM   game_state;

	IF p_player_move = 'FOLD' THEN
	
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' folds');
		UPDATE player_state
		SET    state = 'FOLDED',
			   pre_flop_folds = CASE WHEN v_current_betting_round = 1 THEN pre_flop_folds + 1 ELSE pre_flop_folds END,
			   flop_folds = CASE WHEN v_current_betting_round = 2 THEN flop_folds + 1 ELSE flop_folds END,
			   turn_folds = CASE WHEN v_current_betting_round = 3 THEN turn_folds + 1 ELSE turn_folds END,
			   river_folds = CASE WHEN v_current_betting_round = 4 THEN river_folds + 1 ELSE river_folds END,
			   total_folds = total_folds + 1
		WHERE  seat_number = p_seat_number;
		
		pkg_poker_ai.issue_applicable_pot_refunds;
		pkg_poker_ai.issue_default_pot_wins;
	
	ELSIF p_player_move = 'CHECK' THEN
	
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' checks');
		UPDATE player_state
		SET    state = CASE WHEN state != 'ALL_IN' THEN 'CHECKED' ELSE 'ALL_IN' END,
			   pre_flop_checks = CASE WHEN v_current_betting_round = 1 THEN pre_flop_checks + 1 ELSE pre_flop_checks END,
			   flop_checks = CASE WHEN v_current_betting_round = 2 THEN flop_checks + 1 ELSE flop_checks END,
			   turn_checks = CASE WHEN v_current_betting_round = 3 THEN turn_checks + 1 ELSE turn_checks END,
			   river_checks = CASE WHEN v_current_betting_round = 4 THEN river_checks + 1 ELSE river_checks END,
			   total_checks = total_checks + 1
		WHERE  seat_number = p_seat_number;
		
	ELSIF p_player_move = 'CALL' THEN
	
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' calls');
		
		-- determine player's money
		SELECT money
		INTO   v_player_money
		FROM   player_state
		WHERE  seat_number = p_seat_number;
		
		pkg_poker_ai.contribute_to_pot(
			p_player_seat_number => p_seat_number,
			p_pot_contribution   => LEAST(v_player_money, pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number))
		);

		UPDATE player_state
		SET    state = CASE WHEN state != 'ALL_IN' THEN 'CALLED' ELSE 'ALL_IN' END,
			   pre_flop_calls = CASE WHEN v_current_betting_round = 1 THEN pre_flop_calls + 1 ELSE pre_flop_calls END,
			   flop_calls = CASE WHEN v_current_betting_round = 2 THEN flop_calls + 1 ELSE flop_calls END,
			   turn_calls = CASE WHEN v_current_betting_round = 3 THEN turn_calls + 1 ELSE turn_calls END,
			   river_calls = CASE WHEN v_current_betting_round = 4 THEN river_calls + 1 ELSE river_calls END,
			   total_calls = total_calls + 1
		WHERE  seat_number = p_seat_number;

	ELSIF p_player_move = 'BET' THEN
	
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' bets ' || p_player_move_amount);
		pkg_poker_ai.contribute_to_pot(
			p_player_seat_number => p_seat_number,
			p_pot_contribution   => p_player_move_amount
		);

		UPDATE player_state
		SET    state = CASE WHEN state != 'ALL_IN' THEN 'BET' ELSE 'ALL_IN' END,
			   pre_flop_bets = CASE WHEN v_current_betting_round = 1 THEN pre_flop_bets + 1 ELSE pre_flop_bets END,
			   flop_bets = CASE WHEN v_current_betting_round = 2 THEN flop_bets + 1 ELSE flop_bets END,
			   turn_bets = CASE WHEN v_current_betting_round = 3 THEN turn_bets + 1 ELSE turn_bets END,
			   river_bets = CASE WHEN v_current_betting_round = 4 THEN river_bets + 1 ELSE river_bets END,
			   total_bets = total_bets + 1,
			   pre_flop_total_bet_amount = CASE WHEN v_current_betting_round = 1 THEN pre_flop_total_bet_amount + p_player_move_amount ELSE pre_flop_total_bet_amount END,
			   flop_total_bet_amount = CASE WHEN v_current_betting_round = 2 THEN flop_total_bet_amount + p_player_move_amount ELSE flop_total_bet_amount END,
			   turn_total_bet_amount = CASE WHEN v_current_betting_round = 3 THEN turn_total_bet_amount + p_player_move_amount ELSE turn_total_bet_amount END,
			   river_total_bet_amount = CASE WHEN v_current_betting_round = 4 THEN river_total_bet_amount + p_player_move_amount ELSE river_total_bet_amount END,
			   total_bet_amount = total_bet_amount + p_player_move_amount		   
		WHERE  seat_number = p_seat_number;

		UPDATE player_state
		SET    pre_flop_average_bet_amount = CASE WHEN v_current_betting_round = 1 THEN pre_flop_total_bet_amount / NULLIF(pre_flop_bets, 0) ELSE pre_flop_average_bet_amount END,
			   flop_average_bet_amount = CASE WHEN v_current_betting_round = 2 THEN flop_total_bet_amount / NULLIF(flop_bets, 0) ELSE flop_average_bet_amount END,
			   turn_average_bet_amount = CASE WHEN v_current_betting_round = 3 THEN turn_total_bet_amount / NULLIF(turn_bets, 0) ELSE turn_average_bet_amount END,
			   river_average_bet_amount = CASE WHEN v_current_betting_round = 4 THEN river_total_bet_amount / NULLIF(river_bets, 0) ELSE river_average_bet_amount END,
			   average_bet_amount = total_bet_amount / NULLIF(total_bets, 0)
		WHERE  seat_number = p_seat_number;
		
		UPDATE game_state
		SET    last_to_raise_seat_number = p_seat_number,
			   min_raise_amount = CASE WHEN p_player_move_amount < min_raise_amount THEN min_raise_amount + p_player_move_amount
									   ELSE p_player_move_amount
								  END;
	
	ELSIF p_player_move = 'RAISE' THEN
	
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' raises ' || p_player_move_amount);
		pkg_poker_ai.contribute_to_pot(
			p_player_seat_number => p_seat_number,
			p_pot_contribution   => pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number) + p_player_move_amount
		);

		UPDATE player_state
		SET    state = CASE WHEN state != 'ALL_IN' THEN 'RAISED' ELSE 'ALL_IN' END,
			   pre_flop_raises = CASE WHEN v_current_betting_round = 1 THEN pre_flop_raises + 1 ELSE pre_flop_raises END,
			   flop_raises = CASE WHEN v_current_betting_round = 2 THEN flop_raises + 1 ELSE flop_raises END,
			   turn_raises = CASE WHEN v_current_betting_round = 3 THEN turn_raises + 1 ELSE turn_raises END,
			   river_raises = CASE WHEN v_current_betting_round = 4 THEN river_raises + 1 ELSE river_raises END,
			   total_raises = total_raises + 1,
			   pre_flop_total_raise_amount = CASE WHEN v_current_betting_round = 1 THEN pre_flop_total_raise_amount + p_player_move_amount ELSE pre_flop_total_raise_amount END,
			   flop_total_raise_amount = CASE WHEN v_current_betting_round = 2 THEN flop_total_raise_amount + p_player_move_amount ELSE flop_total_raise_amount END,
			   turn_total_raise_amount = CASE WHEN v_current_betting_round = 3 THEN turn_total_raise_amount + p_player_move_amount ELSE turn_total_raise_amount END,
			   river_total_raise_amount = CASE WHEN v_current_betting_round = 4 THEN river_total_raise_amount + p_player_move_amount ELSE river_total_raise_amount END,
			   total_raise_amount = total_raise_amount + p_player_move_amount		   
		WHERE  seat_number = p_seat_number;
		
		UPDATE player_state
		SET    pre_flop_average_raise_amount = CASE WHEN v_current_betting_round = 1 THEN pre_flop_total_raise_amount / NULLIF(pre_flop_raises, 0) ELSE pre_flop_average_raise_amount END,
			   flop_average_raise_amount = CASE WHEN v_current_betting_round = 2 THEN flop_total_raise_amount / NULLIF(flop_raises, 0) ELSE flop_average_raise_amount END,
			   turn_average_raise_amount = CASE WHEN v_current_betting_round = 3 THEN turn_total_raise_amount / NULLIF(turn_raises, 0) ELSE turn_average_raise_amount END,
			   river_average_raise_amount = CASE WHEN v_current_betting_round = 4 THEN river_total_raise_amount / NULLIF(river_raises, 0) ELSE river_average_raise_amount END,
			   average_raise_amount = total_raise_amount / NULLIF(total_raises, 0)
		WHERE  seat_number = p_seat_number;
	
		UPDATE game_state
		SET    last_to_raise_seat_number = p_seat_number,
			   min_raise_amount = CASE WHEN p_player_move_amount < min_raise_amount THEN min_raise_amount + p_player_move_amount
									   ELSE p_player_move_amount
								  END;
	
	END IF;
	
END perform_explicit_player_move;

FUNCTION get_player_showdown_muck(
	p_seat_number player_state.seat_number%TYPE
) RETURN BOOLEAN IS
BEGIN
	
	RETURN FALSE;
	--pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' chooses not to show cards');

END get_player_showdown_muck;

PROCEDURE process_game_results IS

	v_active_player_count       INTEGER;
	v_winner_seat_number        player_state.seat_number%TYPE;
	v_first_to_show_seat_number player_state.seat_number%TYPE;

BEGIN

	pkg_poker_ai.log(p_message => 'processing game results');

	SELECT COUNT(*) active_player_count,
		   CASE WHEN COUNT(*) = 1 THEN MIN(seat_number) END winner_seat_number
	INTO   v_active_player_count,
		   v_winner_seat_number
	FROM   player_state
	WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED');

	IF v_active_player_count = 1 THEN
		-- everyone but one player folded
		pkg_poker_ai.log(p_message => 'all but one player folded, winning seat is ' || v_winner_seat_number);

		UPDATE player_state
		SET    money = money + (SELECT SUM(pot_contribution) FROM pot_contribution),
			   game_rank = 1,
			   main_pots_won = main_pots_won + 1,
			   total_money_won = total_money_won + (SELECT SUM(pot_contribution) FROM pot_contribution)
		WHERE  seat_number = v_winner_seat_number;
	ELSE

		-- showdown
		pkg_poker_ai.log(p_message => 'starting showdown');

		-- for every player in the showdown, determine best possible hand
		pkg_poker_ai.calculate_best_hands;
		pkg_poker_ai.log(p_message => 'active players best possible hand determined');

		-- Best hand for each player has been determined, compare players
		-- Last player to bet or raise on the river round must show first.
		-- If everyone checked, first player left of dealer shows first.
		SELECT NVL(last_to_raise_seat_number, small_blind_seat_number) first_to_show_seat_number
		INTO   v_first_to_show_seat_number
		FROM   game_state;

		FOR v_player_rec IN (
			WITH participating_seats AS (
				SELECT seat_number
				FROM   player_state
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
				pkg_poker_ai.log(p_message => 'player at seat ' || v_player_rec.seat_number || ' shows hand');
				UPDATE player_state
				SET    hand_showing = 'Y'
				WHERE  seat_number = v_player_rec.seat_number;
			ELSE
				-- other players have opportunity to muck
				IF pkg_poker_ai.get_player_showdown_muck(p_seat_number => v_player_rec.seat_number) THEN
					pkg_poker_ai.log(p_message => 'player at seat ' || v_player_rec.seat_number || ' mucks hand');
					UPDATE player_state
					SET    state = 'FOLDED'
					WHERE  seat_number = v_player_rec.seat_number;
				ELSE
					pkg_poker_ai.log(p_message => 'player at seat ' || v_player_rec.seat_number || ' shows hand');
					UPDATE player_state
					SET    hand_showing = 'Y'
					WHERE  seat_number = v_player_rec.seat_number;
				END IF;
			END IF;

		END LOOP;

		-- for all players showing hands, determine which pots they win
		FOR v_winners_rec IN (
			WITH pot_sums AS (
				SELECT pot_number,
					   SUM(pot_contribution) pot_value
				FROM   pot_contribution
				GROUP BY pot_number
			),

			pot_ranks AS (
				SELECT DISTINCT
					   pc.pot_number,
					   ps.seat_number,
					   pkg_poker_ai.get_distance_from_small_blind(p_seat_number => ps.seat_number) distance_from_small_blind,
					   ps.best_hand_rank,
					   RANK() OVER (PARTITION BY pc.pot_number ORDER BY ps.best_hand_rank DESC) pot_rank
				FROM   player_state ps,
					   pot_contribution pc
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
			pkg_poker_ai.log(p_message => 'player at seat ' || v_winners_rec.seat_number || ' wins ' || v_winners_rec.player_winnings || ' from pot ' || v_winners_rec.pot_number);
			UPDATE player_state
			SET    money = money + v_winners_rec.player_winnings,
				   main_pots_won = CASE WHEN v_winners_rec.split_pot = 'N' AND v_winners_rec.pot_number = 1 THEN main_pots_won + 1 ELSE main_pots_won END,
				   main_pots_split = CASE WHEN v_winners_rec.split_pot = 'Y' AND v_winners_rec.pot_number = 1 THEN main_pots_split + 1 ELSE main_pots_split END,
				   side_pots_won = CASE WHEN v_winners_rec.split_pot = 'N' AND v_winners_rec.pot_number != 1 THEN side_pots_won + 1 ELSE side_pots_won END,
				   side_pots_split = CASE WHEN v_winners_rec.split_pot = 'Y' AND v_winners_rec.pot_number != 1 THEN side_pots_split + 1 ELSE side_pots_split END,
				   total_money_won = total_money_won + v_winners_rec.player_winnings
			WHERE  seat_number = v_winners_rec.seat_number;

		END LOOP;

	END IF;

	UPDATE player_state
	SET    average_game_profit = (total_money_won - total_money_played) / NULLIF(games_played, 0);
	
	-- set tournament rank on anyone that ran out of money
	UPDATE player_state
	SET    tournament_rank = (SELECT COUNT(*) FROM player_state WHERE tournament_rank IS NULL),
		   state = 'OUT_OF_TOURNAMENT',
		   presented_bet_opportunity = NULL
	WHERE  money = 0
	   AND tournament_rank IS NULL;

	UPDATE tournament_state
	SET    game_in_progress = 'N';

	UPDATE game_state
	SET    betting_round_in_progress = 'N';
	
	pkg_poker_ai.log(p_message => 'game over');
	
END process_game_results;

PROCEDURE process_tournament_results IS

	v_fitness_test_id tournament_state.fitness_test_id%TYPE;
	
BEGIN

	UPDATE player_state
	SET    tournament_rank = 1,
		   state = 'OUT_OF_TOURNAMENT'
	WHERE  state != 'OUT_OF_TOURNAMENT';

	UPDATE tournament_state
	SET    tournament_in_progress = 'N';
	
	SELECT fitness_test_id
	INTO   v_fitness_test_id
	FROM   tournament_state;

	pkg_ga_player.update_strategy_fitness(p_fitness_test_id => v_fitness_test_id);
	
	pkg_poker_ai.log(p_message => 'tournament over');

END process_tournament_results;

FUNCTION get_hand_rank(
	p_card_1 deck.card_id%TYPE,
	p_card_2 deck.card_id%TYPE,
	p_card_3 deck.card_id%TYPE,
	p_card_4 deck.card_id%TYPE,
	p_card_5 deck.card_id%TYPE
) RETURN VARCHAR2 RESULT_CACHE IS

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
		FROM   deck
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

PROCEDURE calculate_best_hands IS
BEGIN

	FOR v_player_rec IN (
		WITH players AS (
			SELECT ps.seat_number,
				   gs.community_card_1 c1,
				   gs.community_card_2 c2,
				   gs.community_card_3 c3,
				   gs.community_card_4 c4,
				   gs.community_card_5 c5,
				   ps.hole_card_1 c6,
				   ps.hole_card_2 c7
			FROM   player_state ps,
				   game_state gs
			WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
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
						WHEN 1 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c4, p.c5)
						WHEN 2 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c4, p.c6)
						WHEN 3 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c4, p.c7)
						WHEN 4 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c5, p.c6)
						WHEN 5 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c5, p.c7)
						WHEN 6 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c3, p.c6, p.c7)
						WHEN 7 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c4, p.c5, p.c6)
						WHEN 8 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c4, p.c5, p.c7)
						WHEN 9 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c4, p.c6, p.c7)
						WHEN 10 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c2, p.c5, p.c6, p.c7)
						WHEN 11 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c3, p.c4, p.c5, p.c6)
						WHEN 12 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c3, p.c4, p.c5, p.c7)
						WHEN 13 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c3, p.c4, p.c6, p.c7)
						WHEN 14 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c3, p.c5, p.c6, p.c7)
						WHEN 15 THEN pkg_poker_ai.get_hand_rank(p.c1, p.c4, p.c5, p.c6, p.c7)
						WHEN 16 THEN pkg_poker_ai.get_hand_rank(p.c2, p.c3, p.c4, p.c5, p.c6)
						WHEN 17 THEN pkg_poker_ai.get_hand_rank(p.c2, p.c3, p.c4, p.c5, p.c7)
						WHEN 18 THEN pkg_poker_ai.get_hand_rank(p.c2, p.c3, p.c4, p.c6, p.c7)
						WHEN 19 THEN pkg_poker_ai.get_hand_rank(p.c2, p.c3, p.c5, p.c6, p.c7)
						WHEN 20 THEN pkg_poker_ai.get_hand_rank(p.c2, p.c4, p.c5, p.c6, p.c7)
						WHEN 21 THEN pkg_poker_ai.get_hand_rank(p.c3, p.c4, p.c5, p.c6, p.c7)
				   END hand_rank,
				   p.c1 card_1,
				   p.c2 card_2,
				   p.c3 card_3,
				   p.c4 card_4,
				   p.c5 card_5
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
		UPDATE player_state
		SET    best_hand_combination = v_player_rec.best_hand_combination,
			   best_hand_rank = v_player_rec.best_hand_rank,
			   best_hand_card_1 = v_player_rec.best_hand_card_1,
			   best_hand_card_2 = v_player_rec.best_hand_card_2,
			   best_hand_card_3 = v_player_rec.best_hand_card_3,
			   best_hand_card_4 = v_player_rec.best_hand_card_4,
			   best_hand_card_5 = v_player_rec.best_hand_card_5
		WHERE  seat_number = v_player_rec.seat_number;

	END LOOP;
	
END calculate_best_hands;

PROCEDURE sort_hands IS

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
		FROM   player_state
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
				FROM   deck
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
			MERGE INTO player_state ps USING (
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
			) u ON (v_player_rec.seat_number = ps.seat_number)
			WHEN MATCHED THEN UPDATE SET
				best_hand_card_1 = u.card_1,
				best_hand_card_2 = u.card_2,
				best_hand_card_3 = u.card_3,
				best_hand_card_4 = u.card_4,
				best_hand_card_5 = u.card_5;

		ELSIF v_player_rec.hand_rank = '05' THEN

			-- straight
			MERGE INTO player_state ps USING (
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
			) u ON (v_player_rec.seat_number = ps.seat_number)
			WHEN MATCHED THEN UPDATE SET
				best_hand_card_1 = u.card_1,
				best_hand_card_2 = u.card_2,
				best_hand_card_3 = u.card_3,
				best_hand_card_4 = u.card_4,
				best_hand_card_5 = u.card_5;

		ELSE

			-- four of a kind, full house, flush, three of a kind, two pair, one pair, high card
			MERGE INTO player_state ps USING (
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
			) u ON (v_player_rec.seat_number = ps.seat_number)
			WHEN MATCHED THEN UPDATE SET
				best_hand_card_1 = u.card_1,
				best_hand_card_2 = u.card_2,
				best_hand_card_3 = u.card_3,
				best_hand_card_4 = u.card_4,
				best_hand_card_5 = u.card_5;

		END IF;

	END LOOP;

END sort_hands;

FUNCTION get_can_fold (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_fold
	INTO   v_result
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number = p_seat_number
	   AND gs.turn_seat_number = p_seat_number
	   AND gs.betting_round_in_progress = 'Y' 
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN');
	   
	RETURN v_result;
	
END get_can_fold;

FUNCTION get_can_check (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_check
	INTO   v_result
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number = p_seat_number
	   AND gs.turn_seat_number = p_seat_number
	   AND gs.betting_round_in_progress = 'Y' 
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	   AND pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number) = 0;
	   
	RETURN v_result;
	
END get_can_check;

FUNCTION get_can_call (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_call
	INTO   v_result
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number = p_seat_number
	   AND gs.turn_seat_number = p_seat_number
	   AND gs.betting_round_in_progress = 'Y'
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	   AND pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number) > 0;
			   
	RETURN v_result;
	
END get_can_call;

FUNCTION get_can_bet (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	WITH bet_exists AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_exists
		FROM   game_state gs,
			   pot p
		WHERE  gs.betting_round_number = p.betting_round_number
	),
	
	player_bet_state AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_bet
		FROM   game_state gs,
			   player_state this_player_state,
			   player_state peer_player_state
		WHERE  this_player_state.seat_number = p_seat_number
		   AND gs.turn_seat_number = p_seat_number
		   AND gs.betting_round_in_progress = 'Y'
		   AND this_player_state.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
		   AND pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number) = 0
		   AND peer_player_state.seat_number != p_seat_number
		   AND peer_player_state.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	)
	
	SELECT CASE WHEN be.bet_exists = 'N' AND pbs.can_bet = 'Y' THEN 'Y' ELSE 'N' END can_bet
	INTO   v_result
	FROM   bet_exists be,
		   player_bet_state pbs;

	RETURN v_result;
	
END get_can_bet;

FUNCTION get_can_raise (
	p_seat_number player_state.seat_number%TYPE
) RETURN VARCHAR2 IS

	v_result VARCHAR2(1);
	
BEGIN

	WITH bet_exists AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_exists
		FROM   game_state gs,
			   pot p
		WHERE  gs.betting_round_number = p.betting_round_number
	),

	other_players_to_raise AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END other_players_to_raise_exist
		FROM   player_state
		WHERE  seat_number != p_seat_number
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
	),
	
	player_raise_state AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_raise
		FROM   game_state gs,
			   player_state ps
		WHERE  ps.seat_number = p_seat_number
		   AND gs.turn_seat_number = p_seat_number
		   AND gs.betting_round_in_progress = 'Y'
		   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED', 'ALL_IN')
		   AND (ps.money - pkg_poker_ai.get_pot_deficit(p_seat_number => ps.seat_number)) > 0
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

FUNCTION get_min_bet_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE IS

	v_min_bet game_state.min_raise_amount%TYPE;
	
BEGIN

	SELECT MIN(CASE WHEN ps.money < gs.min_raise_amount THEN ps.money ELSE gs.min_raise_amount END) min_bet
	INTO   v_min_bet
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number = p_seat_number;
	
	RETURN v_min_bet;
	
END get_min_bet_amount;

FUNCTION get_max_bet_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN player_state.money%TYPE IS

	v_max_bet player_state.money%TYPE;
	
BEGIN

	WITH player_money AS (
		SELECT money max_bet
		FROM   player_state
		WHERE  seat_number = p_seat_number
	),
	
	peer_max_money AS (
		SELECT MAX(money) peer_max_money
		FROM   player_state
		WHERE  seat_number != p_seat_number
		   AND state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
	)
	
	SELECT LEAST(pmm.peer_max_money, pm.max_bet) max_bet
	INTO   v_max_bet
	FROM   player_money pm,
		   peer_max_money pmm;
	
	RETURN v_max_bet;
	
END get_max_bet_amount;

FUNCTION get_min_raise_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE IS

	v_min_raise game_state.min_raise_amount%TYPE;
	
BEGIN

	WITH remaining_money AS (
		SELECT money - pkg_poker_ai.get_pot_deficit(p_seat_number => seat_number) remaining_money
		FROM   player_state
		WHERE  seat_number = p_seat_number
	)
	
	SELECT CASE WHEN rm.remaining_money >= gs.min_raise_amount THEN gs.min_raise_amount 
				ELSE rm.remaining_money
		   END min_raise
	INTO   v_min_raise
	FROM   remaining_money rm,
		   game_state gs;

	RETURN v_min_raise;
	
END get_min_raise_amount;

FUNCTION get_max_raise_amount (
	p_seat_number player_state.seat_number%TYPE
) RETURN game_state.min_raise_amount%TYPE IS

	v_max_raise game_state.min_raise_amount%TYPE;
	
BEGIN

	WITH pot_players AS (
		SELECT p.pot_number,
			   p.betting_round_number,
			   p.bet_value,
			   ps.seat_number,
			   ps.money
		FROM   pot p,
			   player_state ps
		WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
	),

	pot_deficits AS (
		SELECT pp.seat_number,
			   pp.bet_value deficit
		FROM   pot_players pp,
			   pot_contribution pc
		WHERE  pp.pot_number = pc.pot_number (+)
		   AND pp.betting_round_number = pc.betting_round_number (+)
		   AND pp.seat_number = pc.player_seat_number (+)
		   AND pc.player_seat_number IS NULL
		 
		UNION ALL
		 
		SELECT pc.player_seat_number seat_number,
			   (p.bet_value - pc.pot_contribution) deficit
		FROM   pot p,
			   pot_contribution pc
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
	
END get_max_raise_amount;

FUNCTION get_pot_deficit (
	p_seat_number player_state.seat_number%TYPE
) RETURN pot_contribution.pot_contribution%TYPE IS

	v_result pot_contribution.pot_contribution%TYPE;
	
BEGIN

	WITH pot_players AS (
		SELECT ps.seat_number,
			   p.pot_number,
			   p.betting_round_number,
			   p.bet_value,
			   ps.money
		FROM   pot p,
			   player_state ps
		WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		   AND ps.seat_number = p_seat_number
	),
	
	pot_deficits AS (
		SELECT pp.bet_value deficit
		FROM   pot_players pp,
			   pot_contribution pc
		WHERE  pp.pot_number = pc.pot_number (+)
		   AND pp.betting_round_number = pc.betting_round_number (+)
		   AND pp.seat_number = pc.player_seat_number (+)
		   AND pc.player_seat_number IS NULL
		 
		UNION ALL
		 
		SELECT (p.bet_value - pc.pot_contribution) deficit
		FROM   pot_players pp,
			   pot p,
			   pot_contribution pc
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

PROCEDURE contribute_to_pot (
	p_player_seat_number pot_contribution.player_seat_number%TYPE,
	p_pot_contribution   pot_contribution.pot_contribution%TYPE
) IS

	v_round_highest_pot_number pot.pot_number%TYPE;
	v_highest_pot_number       pot.pot_number%TYPE;
	v_highest_pot_bet_value    pot.bet_value%TYPE;
	v_current_betting_round    game_state.betting_round_number%TYPE;
	v_total_pot_contribution   pot_contribution.pot_contribution%TYPE;
	v_this_pot_contribution    pot_contribution.pot_contribution%TYPE;
	v_highest_pot_total_contr  pot_contribution.pot_contribution%TYPE;
	v_need_side_pot            VARCHAR2(1);
	
BEGIN

	pkg_poker_ai.log(p_message => 'player at seat ' || p_player_seat_number || ' contributes ' || p_pot_contribution || ' to the pot');
	
	-- determine current betting round
	SELECT NVL(betting_round_number, 1) current_betting_round
	INTO   v_current_betting_round
	FROM   game_state;
	
	-- determine highest put number for the current betting round
	SELECT MAX(pot_number) round_highest_pot_number
	INTO   v_round_highest_pot_number
	FROM   pot
	WHERE  betting_round_number = v_current_betting_round;
	
	IF v_round_highest_pot_number IS NULL THEN
	
		-- determine highest overall pot number
		SELECT NVL(MAX(pot_number), 1) highest_pot_number
		INTO   v_highest_pot_number
		FROM   pot;

		-- create initial pot for round
		INSERT INTO pot (
			pot_number,
			betting_round_number,
			bet_value
		) VALUES (
			v_highest_pot_number,
			v_current_betting_round,
			p_pot_contribution
		);
		INSERT INTO pot_contribution (
			pot_number,
			betting_round_number,
			player_seat_number,
			pot_contribution
		) VALUES (
			v_highest_pot_number,
			v_current_betting_round,
			p_player_seat_number,
			p_pot_contribution
		);
		
	ELSE
	
		-- starting from the lowest pot number, put in money to cover any deficits
		v_total_pot_contribution := p_pot_contribution;
		FOR v_rec IN (
			SELECT p.pot_number,
				   p.betting_round_number,
				   p.bet_value,
				   p.bet_value deficit
			FROM   pot p,
				   pot_contribution pc
			WHERE  p.pot_number = pc.pot_number (+)
			   AND p.betting_round_number = pc.betting_round_number (+)
			   AND p.betting_round_number = v_current_betting_round
			   AND pc.player_seat_number (+) = p_player_seat_number
			   AND pc.player_seat_number IS NULL
			 
			UNION ALL
			 
			SELECT p.pot_number,
				   p.betting_round_number,
				   p.bet_value,
				   (p.bet_value - pc.pot_contribution) deficit
			FROM   pot p,
				   pot_contribution pc
			WHERE  p.pot_number = pc.pot_number
			   AND p.betting_round_number = pc.betting_round_number
			   AND p.betting_round_number = v_current_betting_round
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
			MERGE INTO pot_contribution pc USING (SELECT dummy FROM DUAL) s ON (
				pc.pot_number = v_rec.pot_number
				AND pc.betting_round_number = v_rec.betting_round_number
				AND pc.player_seat_number = p_player_seat_number
			) WHEN MATCHED THEN UPDATE SET
				pc.pot_contribution = pc.pot_contribution + v_this_pot_contribution
			WHEN NOT MATCHED THEN INSERT (
				pot_number,
				betting_round_number,
				player_seat_number,
				pot_contribution
			) VALUES (
				v_rec.pot_number,
				v_rec.betting_round_number,
				p_player_seat_number,
				v_this_pot_contribution
			);
			
			-- take this pot contribution away from total amount being contributed
			v_total_pot_contribution := v_total_pot_contribution - v_this_pot_contribution;
			
			-- on the highest pot, need to possibly split pots or increase pot bet
			IF v_rec.pot_number = v_round_highest_pot_number THEN
			
				v_highest_pot_bet_value := v_rec.bet_value;
				SELECT NVL(MIN(pot_contribution), 0) highest_pot_total_contr
				INTO   v_highest_pot_total_contr
				FROM   pot_contribution
				WHERE  pot_number = v_round_highest_pot_number
				   AND betting_round_number = v_current_betting_round
				   AND player_seat_number = p_player_seat_number;
				
				IF v_highest_pot_total_contr < v_highest_pot_bet_value THEN
				
					-- player is going all in and cannot cover the current bet, need to split pot
					INSERT INTO pot (
						pot_number,
						betting_round_number,
						bet_value
					) VALUES (
						v_round_highest_pot_number + 1,
						v_current_betting_round,
						v_highest_pot_bet_value - v_highest_pot_total_contr
					);

					-- move balance of all other players in pot to new pot
					INSERT INTO pot_contribution (
						pot_number,
						betting_round_number,
						player_seat_number,
						pot_contribution
					)
					SELECT (v_round_highest_pot_number + 1) pot_number,
						   betting_round_number,
						   player_seat_number,
						   (pot_contribution - v_highest_pot_total_contr) pot_contribution
					FROM   pot_contribution
					WHERE  pot_number = v_round_highest_pot_number
					   AND betting_round_number = v_current_betting_round
					   AND player_seat_number != p_player_seat_number
					   AND pot_contribution > v_highest_pot_total_contr;
					
					-- update the bet value on the old highest pot number to the contribution of the player going all in
					UPDATE pot
					SET    bet_value = v_highest_pot_total_contr
					WHERE  pot_number = v_round_highest_pot_number
					   AND betting_round_number = v_current_betting_round;

					-- update the player contributions on the old highest pot number to the contribution of the
					-- player going all in for all players who's contributions rolled into the next pot 
					UPDATE pot_contribution
					SET    pot_contribution = v_highest_pot_total_contr
					WHERE  pot_number = v_round_highest_pot_number
					   AND betting_round_number = v_current_betting_round
					   AND player_seat_number != p_player_seat_number
					   AND pot_contribution > v_highest_pot_total_contr;
					
				ELSIF v_highest_pot_total_contr > v_highest_pot_bet_value THEN
				
					-- player is increasing the bet value.  If any other contributors to this pot are all in, need to split pot
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END need_side_pot
					INTO   v_need_side_pot
					FROM   pot_contribution pc,
						   player_state ps
					WHERE  pc.pot_number = v_round_highest_pot_number
					   AND pc.betting_round_number = v_current_betting_round
					   AND pc.player_seat_number != p_player_seat_number
					   AND pc.player_seat_number = ps.seat_number
					   AND ps.state = 'ALL_IN';
					   
					IF v_need_side_pot = 'Y' THEN
			
						-- create new pot
						INSERT INTO pot (
							pot_number,
							betting_round_number,
							bet_value
						) VALUES (
							v_round_highest_pot_number + 1,
							v_current_betting_round,
							v_highest_pot_total_contr - v_highest_pot_bet_value
						);

						-- move balance of player's contribution into new pot
						INSERT INTO pot_contribution (
							pot_number,
							betting_round_number,
							player_seat_number,
							pot_contribution
						) VALUES (
							v_round_highest_pot_number + 1,
							v_current_betting_round,
							p_player_seat_number,
							v_highest_pot_total_contr - v_highest_pot_bet_value
						);
						
						-- update the player contribution on the old highest pot number to the contribution of the player going all in
						UPDATE pot_contribution
						SET    pot_contribution = v_highest_pot_bet_value
						WHERE  pot_number = v_round_highest_pot_number
						   AND betting_round_number = v_current_betting_round
						   AND player_seat_number = p_player_seat_number;
						
					ELSE
					
						-- new pot not needed, just increase bet value of highest pot
						UPDATE pot
						SET    bet_value = v_highest_pot_total_contr
						WHERE  pot_number = v_round_highest_pot_number
						   AND betting_round_number = v_current_betting_round;
						
					END IF;
					
				END IF;
				
			END IF;
			
			-- abort loop if the player has no more money to contribute to further pots
			EXIT WHEN v_total_pot_contribution = 0;
			
		END LOOP;
	
	END IF;
	
	-- remove money from player's stack and flag all in state when needed
	UPDATE player_state
	SET    money = money - p_pot_contribution,
		   state = CASE WHEN money - p_pot_contribution = 0 THEN 'ALL_IN' ELSE state END,
		   times_all_in = CASE WHEN money - p_pot_contribution = 0 THEN times_all_in + 1 ELSE times_all_in END,
		   total_money_played = total_money_played + p_pot_contribution
	WHERE  seat_number = p_player_seat_number;
	
	pkg_poker_ai.issue_applicable_pot_refunds;
	
END contribute_to_pot;

PROCEDURE issue_applicable_pot_refunds IS
BEGIN

	-- if there are any pots that only have one contributor and all the other active players are all in,
	-- refund to the pot contributor and delete the pot
	FOR v_rec IN (
		WITH sole_contributor_pots AS (
			SELECT pot_number,
				   MIN(player_seat_number) sole_contributor,
				   SUM(pot_contribution) pot_contribution
			FROM   pot_contribution
			GROUP BY pot_number
			HAVING COUNT(DISTINCT player_seat_number) = 1
		)

		SELECT scp.pot_number,
			   scp.sole_contributor,
			   scp.pot_contribution
		FROM   sole_contributor_pots scp,
			   player_state ps
		WHERE  scp.sole_contributor != ps.seat_number
		   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		GROUP BY
			scp.pot_number,
			scp.sole_contributor,
			scp.pot_contribution
		HAVING SUM(CASE WHEN ps.state = 'ALL_IN' THEN 1 ELSE 0 END) = COUNT(*)
	) LOOP
	
		pkg_poker_ai.log(p_message => 'refunding ' || v_rec.pot_contribution || ' back to player at seat '
			|| v_rec.sole_contributor || ' from pot ' || v_rec.pot_number);
			
		UPDATE player_state
		SET    state = CASE WHEN state = 'ALL_IN' THEN 'RAISED' ELSE state END,
			   money = money + v_rec.pot_contribution,
			   total_money_played = total_money_played - v_rec.pot_contribution
		WHERE  seat_number = v_rec.sole_contributor;
		
		DELETE FROM pot_contribution
		WHERE  pot_number = v_rec.pot_number;
		
		DELETE FROM pot
		WHERE  pot_number = v_rec.pot_number;
		
	END LOOP;
	
END issue_applicable_pot_refunds;

PROCEDURE issue_default_pot_wins IS
BEGIN

	-- if all non-all in players but one player fold on a given pot, by default the non-folded
	-- contributor wins the pot
	FOR v_rec IN (
		WITH pot_contibutions AS (
			SELECT ps.seat_number,
				   ps.state,
				   pc.pot_number,
				   SUM(pc.pot_contribution) pot_contribution
			FROM   player_state ps,
				   pot_contribution pc
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
			FROM   pot_contibutions
			GROUP BY pot_number
			HAVING SUM(CASE WHEN state = 'FOLDED' THEN 1 ELSE 0 END) = COUNT(*) - 1
		)

		SELECT w.pot_number,
			   w.pot_winner,
			   w.win_amount
		FROM   pot_contibutions pc,
			   pots_w_1_non_folded_contrib w
		WHERE  pc.pot_number != w.pot_number
		   AND pc.seat_number != w.pot_winner
		GROUP BY
			w.pot_number,
			w.pot_winner,
			w.win_amount
		HAVING SUM(CASE WHEN pc.state NOT IN ('FOLDED', 'ALL_IN') THEN 1 ELSE 0 END) = 0
	) LOOP
	
		pkg_poker_ai.log(p_message => 'by default, player at seat ' || v_rec.pot_winner || ' wins '
			|| v_rec.win_amount || ' from pot ' || v_rec.pot_number);
			
		UPDATE player_state
		SET    state = CASE WHEN state = 'ALL_IN' THEN 'RAISED' ELSE state END,
			   money = money + v_rec.win_amount,
			   total_money_won = total_money_won + v_rec.win_amount
		WHERE  seat_number = v_rec.pot_winner;
		
		DELETE FROM pot_contribution
		WHERE  pot_number = v_rec.pot_number;
		
		DELETE FROM pot
		WHERE  pot_number = v_rec.pot_number;

	END LOOP;
	
END issue_default_pot_wins;

PROCEDURE edit_card(
	p_card_type   VARCHAR2,
	p_seat_number player_state.seat_number%TYPE,
	p_card_slot   NUMBER,
	p_card_id     deck.card_id%TYPE
) IS

	v_current_card_id deck.card_id%TYPE;
	
BEGIN

	IF p_card_type = 'HOLE_CARD' THEN
		SELECT CASE WHEN p_card_slot = 1 THEN hole_card_1 ELSE hole_card_2 END current_card_id
		INTO   v_current_card_id
		FROM   player_state
		WHERE  seat_number = p_seat_number;
		
		UPDATE player_state
		SET    hole_card_1 = CASE WHEN p_card_slot = 1 THEN p_card_id ELSE hole_card_1 END,
			   hole_card_2 = CASE WHEN p_card_slot = 2 THEN p_card_id ELSE hole_card_2 END
		WHERE  seat_number = p_seat_number;
	ELSE
		SELECT CASE p_card_slot
					WHEN 1 THEN community_card_1
					WHEN 2 THEN community_card_2
					WHEN 3 THEN community_card_3
					WHEN 4 THEN community_card_4
					WHEN 5 THEN community_card_5
			   END current_card_id
		INTO   v_current_card_id
		FROM   game_state;
		
		UPDATE game_state
		SET    community_card_1 = CASE WHEN p_card_slot = 1 THEN p_card_id ELSE community_card_1 END,
			   community_card_2 = CASE WHEN p_card_slot = 2 THEN p_card_id ELSE community_card_2 END,
			   community_card_3 = CASE WHEN p_card_slot = 3 THEN p_card_id ELSE community_card_3 END,
			   community_card_4 = CASE WHEN p_card_slot = 4 THEN p_card_id ELSE community_card_4 END,
			   community_card_5 = CASE WHEN p_card_slot = 5 THEN p_card_id ELSE community_card_5 END;
	END IF;
	
	IF v_current_card_id IS NOT NULL AND v_current_card_id != 0 THEN
		UPDATE deck
		SET    dealt = 'N'
		WHERE  card_id = v_current_card_id;
	END IF;
	
	UPDATE deck
	SET    dealt = 'Y'
	WHERE  card_id = p_card_id;
	
	pkg_poker_ai.calculate_best_hands;
	pkg_poker_ai.sort_hands;
	
	COMMIT;
	
END edit_card;

PROCEDURE select_ui_state (
	p_tournament_state OUT t_rc_generic,
	p_game_state       OUT t_rc_generic,
	p_player_state     OUT t_rc_generic,
	p_pots             OUT t_rc_generic,
	p_status           OUT t_rc_generic
) IS
BEGIN

	OPEN p_tournament_state FOR
		SELECT player_count,
			   buy_in_amount,
			   current_game_number,
			   CASE game_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END game_in_progress,
			   current_state_id
		FROM   tournament_state;

	OPEN p_game_state FOR
		SELECT gs.small_blind_seat_number,
			   gs.big_blind_seat_number,
			   gs.turn_seat_number,
			   gs.small_blind_value,
			   gs.big_blind_value,
			   mfv.display_value betting_round_number,
			   CASE gs.betting_round_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END betting_round_in_progress,
			   gs.last_to_raise_seat_number,
			   gs.community_card_1,
			   gs.community_card_2,
			   gs.community_card_3,
			   gs.community_card_4,
			   gs.community_card_5
		FROM   game_state gs,
			   master_field_value mfv
		WHERE  mfv.field_name_code (+) = 'BETTING_ROUND_NUMBER'
		   AND gs.betting_round_number = mfv.field_value_code (+);

	OPEN p_player_state FOR
		WITH seats AS (
			SELECT ROWNUM seat_number
			FROM   DUAL
			CONNECT BY ROWNUM <= v_max_player_count
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
			   AND ps.best_hand_rank = mfv.field_value_code
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
			   pkg_poker_ai.get_can_fold(p_seat_number => s.seat_number) can_fold,
			   pkg_poker_ai.get_can_check(p_seat_number => s.seat_number) can_check,
			   pkg_poker_ai.get_can_call(p_seat_number => s.seat_number) can_call,
			   pkg_poker_ai.get_can_bet(p_seat_number => s.seat_number) can_bet,
			   pkg_poker_ai.get_min_bet_amount(p_seat_number => s.seat_number) min_bet_amount,
			   pkg_poker_ai.get_max_bet_amount(p_seat_number => s.seat_number) max_bet_amount,
			   pkg_poker_ai.get_can_raise(p_seat_number => s.seat_number) can_raise,
			   pkg_poker_ai.get_min_raise_amount(p_seat_number => s.seat_number) min_raise_amount,
			   pkg_poker_ai.get_max_raise_amount(p_seat_number => s.seat_number) max_raise_amount
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
			FROM   pot_contribution
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
		WHERE  state_id = (SELECT current_state_id FROM tournament_state)
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

PROCEDURE log (
	p_message poker_ai_log.message%TYPE
) IS

	PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

	INSERT INTO poker_ai_log (
		log_record_number,
		mod_date,
		state_id,
		message
	) VALUES (
		pai_seq_generic.NEXTVAL,
		SYSDATE,
		v_state_id,
		p_message
	);

	COMMIT;

END log;

PROCEDURE capture_state_log IS
BEGIN

	INSERT INTO tournament_state_log (
		state_id,
		tournament_mode,
		fitness_test_id,
		player_count,
		buy_in_amount,
		tournament_in_progress,
		current_game_number,
		game_in_progress
	)
	SELECT v_state_id state_id,
		   tournament_mode,
		   fitness_test_id,
		   player_count,
		   buy_in_amount,
		   tournament_in_progress,
		   current_game_number,
		   game_in_progress
	FROM   tournament_state;

	INSERT INTO game_state_log (
		state_id,
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
	)
	SELECT v_state_id state_id,
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
	FROM   game_state;
	
	INSERT INTO player_state_log (
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
	SELECT v_state_id state_id,
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
	FROM   player_state;
	
	INSERT INTO pot_log (
		state_id,
		pot_number,
		betting_round_number,
		bet_value
	)
	SELECT v_state_id state_id,
		   pot_number,
		   betting_round_number,
		   bet_value
	FROM   pot;

	INSERT INTO pot_contribution_log (
		state_id,
		pot_number,
		betting_round_number,
		player_seat_number,
		pot_contribution
	)
	SELECT v_state_id state_id,
		   pot_number,
		   betting_round_number,
		   player_seat_number,
		   pot_contribution
	FROM   pot_contribution;

END capture_state_log;

FUNCTION get_state_id RETURN poker_ai_log.state_id%TYPE IS
BEGIN

	RETURN pai_seq_sid.NEXTVAL;

END get_state_id;

PROCEDURE load_state (
	p_state_id poker_ai_log.state_id%TYPE
) IS
BEGIN
	
	DELETE FROM pot_contribution;
	DELETE FROM pot;
	DELETE FROM player_state;
	DELETE FROM game_state;
	DELETE FROM tournament_state;
	
	INSERT INTO tournament_state (
		tournament_mode,
		fitness_test_id,
		player_count,
		buy_in_amount,
		tournament_in_progress,
		current_game_number,
		game_in_progress,
		current_state_id
	)
	SELECT tournament_mode,
		   fitness_test_id,
		   player_count,
		   buy_in_amount,
		   tournament_in_progress,
		   current_game_number,
		   game_in_progress,
		   state_id current_state_id
	FROM   tournament_state_log
	WHERE  state_id = p_state_id;
			
	INSERT INTO game_state (
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
	)
	SELECT small_blind_seat_number,
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
	FROM   game_state_log
	WHERE  state_id = p_state_id;
	
	INSERT INTO player_state (
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
	SELECT seat_number,
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
	FROM   player_state_log
	WHERE  state_id = p_state_id;
	
	INSERT INTO pot (
		pot_number,
		betting_round_number,
		bet_value
	)
	SELECT pot_number,
		   betting_round_number,
		   bet_value
	FROM   pot_log
	WHERE  state_id = p_state_id;

	INSERT INTO pot_contribution (
		pot_number,
		betting_round_number,
		player_seat_number,
		pot_contribution
	)
	SELECT pot_number,
		   betting_round_number,
		   player_seat_number,
		   pot_contribution
	FROM   pot_contribution_log
	WHERE  state_id = p_state_id;

	pkg_poker_ai.initialize_deck;
	
	UPDATE deck
	SET    dealt = 'Y'
	WHERE  card_id IN (
		SELECT hole_card_1 card_id FROM player_state WHERE hole_card_1 IS NOT NULL AND hole_card_1 != 0 UNION ALL
		SELECT hole_card_2 card_id FROM player_state WHERE hole_card_2 IS NOT NULL AND hole_card_2 != 0 UNION ALL
		SELECT community_card_1 card_id FROM game_state WHERE community_card_1 IS NOT NULL AND community_card_1 != 0 UNION ALL
		SELECT community_card_2 card_id FROM game_state WHERE community_card_2 IS NOT NULL AND community_card_2 != 0 UNION ALL
		SELECT community_card_3 card_id FROM game_state WHERE community_card_3 IS NOT NULL AND community_card_3 != 0 UNION ALL
		SELECT community_card_4 card_id FROM game_state WHERE community_card_4 IS NOT NULL AND community_card_4 != 0 UNION ALL
		SELECT community_card_5 card_id FROM game_state WHERE community_card_5 IS NOT NULL AND community_card_5 != 0 
	);
	
	COMMIT;
	
END load_state;

PROCEDURE load_previous_state (
	p_state_id poker_ai_log.state_id%TYPE
) IS

	v_previous_state_id poker_ai_log.state_id%TYPE;
	
BEGIN

	SELECT MAX(state_id) previous_state_id
	INTO   v_previous_state_id
	FROM   poker_ai_log
	WHERE  state_id < p_state_id;
	
	IF v_previous_state_id IS NOT NULL THEN
		pkg_poker_ai.load_state(p_state_id => v_previous_state_id);
	END IF;
	
END load_previous_state;

PROCEDURE load_next_state (
	p_state_id poker_ai_log.state_id%TYPE
) IS

	v_next_state_id poker_ai_log.state_id%TYPE;
	
BEGIN

	SELECT MIN(state_id) next_state_id
	INTO   v_next_state_id
	FROM   poker_ai_log
	WHERE  state_id > p_state_id;
	
	IF v_next_state_id IS NOT NULL THEN
		pkg_poker_ai.load_state(p_state_id => v_next_state_id);
	END IF;
	
END load_next_state;
	
END pkg_poker_ai;