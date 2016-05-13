CREATE OR REPLACE PACKAGE BODY pkg_poker_ai AS

PROCEDURE log (
	p_message poker_ai_log.message%TYPE
) IS

	PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

	INSERT INTO poker_ai_log (
		log_record_number,
		mod_date,
		message
	) VALUES (
		pai_seq_generic.NEXTVAL,
		SYSDATE,
		p_message
	);

	COMMIT;

END log;

PROCEDURE initialize_tournament
(
	p_player_count      tournament_state.player_count%TYPE,
    p_buy_in_amount     tournament_state.buy_in_amount%TYPE,
	p_small_blind_value game_state.small_blind_value%TYPE,
	p_big_blind_value   game_state.big_blind_value%TYPE
) IS
BEGIN

	-- init tournament state
	pkg_poker_ai.log(p_message => 'initializing tournament');
	DELETE FROM tournament_state;
	INSERT INTO tournament_state(
		player_count,
		buy_in_amount,
		current_game_number,
		game_in_progress
	) VALUES (
		p_player_count,
		p_buy_in_amount,
		NULL,
		'N'
	);

	-- clear game state
	pkg_poker_ai.clear_game_state;

	-- select random players
	pkg_poker_ai.log(p_message => 'selecting random players');
	DELETE FROM player_state;
    INSERT INTO player_state(
        player_id,
        seat_number,
		hand_showing,
        money,
		state,
		presented_bet_opportunity
    )
    WITH players AS (
        SELECT player_id
        FROM   player
        ORDER BY DBMS_RANDOM.VALUE
    )
    SELECT player_id,
           ROWNUM seat_number,
		   'N' hand_showing,
           p_buy_in_amount money,
		   'NO_MOVE' state,
		   'N' presented_bet_opportunity
    FROM   players
    WHERE  ROWNUM <= p_player_count;
    
	pkg_poker_ai.step_play( 
		p_small_blind_value  => p_small_blind_value,
		p_big_blind_value    => p_big_blind_value,
		p_player_move        => 0,
		p_player_move_amount => 0
	);

END initialize_tournament;

PROCEDURE step_play( 
	p_small_blind_value  game_state.small_blind_value%TYPE,
	p_big_blind_value    game_state.big_blind_value%TYPE,
	p_player_move        NUMBER,
	p_player_move_amount NUMBER
) IS

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

	-- determine how many active players remain
	SELECT COUNT(*) remaining_player_count
	INTO   v_remaining_player_count
	FROM   player_state
	WHERE  state != 'OUT_OF_TOURNAMENT';

	IF v_remaining_player_count > 0 THEN
		
		SELECT game_in_progress,
			   current_game_number
		INTO   v_game_in_progress,
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
					p_include_folded_players     => 'Y'
				);
			END IF;

			pkg_poker_ai.initialize_game(
				p_small_blind_seat_number => v_small_blind_seat_number,
				p_small_blind_value       => p_small_blind_value,
				p_big_blind_value         => p_big_blind_value);

			UPDATE tournament_state
			SET    current_game_number = NVL(current_game_number, 0) + 1,
				   game_in_progress = 'Y';
				   
		   	pkg_poker_ai.step_play( 
				p_small_blind_value  => p_small_blind_value,
				p_big_blind_value    => p_big_blind_value,
				p_player_move        => 0,
				p_player_move_amount => 0
			);

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
					pkg_poker_ai.log(p_message => 'posting blinds');
					pkg_poker_ai.post_blinds;

					-- deal hole cards
					pkg_poker_ai.log(p_message => 'dealing hole cards');
					UPDATE player_state
					SET    hole_card_1 = pkg_poker_ai.draw_deck_card,
						   hole_card_2 = pkg_poker_ai.draw_deck_card
					WHERE  state != 'OUT_OF_TOURNAMENT';
				
				ELSIF v_betting_round_number = 1 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- reset player turn
					UPDATE game_state
					SET    turn_seat_number = pkg_poker_ai.get_next_active_seat_number(
						p_current_player_seat_number => big_blind_seat_number,
						p_include_folded_players     => 'N'
					);

					-- deal flop
					pkg_poker_ai.log(p_message => 'dealing flop');
					UPDATE game_state
					SET    community_card_1 = pkg_poker_ai.draw_deck_card,
						   community_card_2 = pkg_poker_ai.draw_deck_card,
						   community_card_3 = pkg_poker_ai.draw_deck_card;

					pkg_poker_ai.calculate_best_hands;
					pkg_poker_ai.sort_hands;

				ELSIF v_betting_round_number = 2 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- reset player turn
					UPDATE game_state
					SET    turn_seat_number = pkg_poker_ai.get_next_active_seat_number(
						p_current_player_seat_number => big_blind_seat_number,
						p_include_folded_players     => 'N'
					);

					-- deal turn
					pkg_poker_ai.log(p_message => 'dealing turn');
					UPDATE game_state
					SET    community_card_4 = pkg_poker_ai.draw_deck_card;

					pkg_poker_ai.calculate_best_hands;
					pkg_poker_ai.sort_hands;

				ELSIF v_betting_round_number = 3 THEN
					-- reset player state
					pkg_poker_ai.log(p_message => 'resetting player state');
					UPDATE player_state
					SET    state = 'NO_MOVE',
						   presented_bet_opportunity = 'N'
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT', 'ALL_IN');

					-- reset player turn
					UPDATE game_state
					SET    turn_seat_number = pkg_poker_ai.get_next_active_seat_number(
						p_current_player_seat_number => big_blind_seat_number,
						p_include_folded_players     => 'N'
					);

					-- deal river
					pkg_poker_ai.log(p_message => 'dealing river');
					UPDATE game_state
					SET    community_card_5 = pkg_poker_ai.draw_deck_card;

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
					-- if the pots aren't even, allow betting to continue
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END uneven_pot
					INTO   v_uneven_pot
					FROM   player_state
					WHERE  pkg_poker_ai.get_pot_deficit(p_seat_number => seat_number) > 0;

					-- if anyone has not been presented the opportunity to bet, proceed with betting
					v_next_player := pkg_poker_ai.get_next_active_seat_number(
						p_current_player_seat_number => v_turn_seat_number,
						p_include_folded_players     => 'N'
					);
					SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END bet_opportunity_not_presented
					INTO   v_bet_opp_not_presented
					FROM   player_state
					WHERE  state NOT IN ('FOLDED', 'OUT_OF_TOURNAMENT')
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
/*						
					   	pkg_poker_ai.step_play( 
							p_small_blind_value  => p_small_blind_value,
							p_big_blind_value    => p_big_blind_value,
							p_player_move        => 0,
							p_player_move_amount => 0
						);
	*/					
					END IF;

				END IF;

			END IF;

		END IF;

	END IF;

END step_play;

/*
PROCEDURE play_tournament IS

	v_initial_player_count    tournament_state.player_count%TYPE;
	v_small_blind_seat_number player_state.seat_number%TYPE;
	v_remaining_player_count  tournament_state.player_count%TYPE;
	v_current_game_number     tournament_state.current_game_number%TYPE;

BEGIN

	pkg_poker_ai.log(p_message => 'playing tournament');

	SELECT player_count initial_player_count
	INTO   v_initial_player_count
	FROM   tournament_state;

	v_small_blind_seat_number := DBMS_RANDOM.VALUE(1, v_initial_player_count);

	LOOP

		-- determine how many active players remain, quit when none remain
		SELECT COUNT(*) remaining_player_count
		INTO   v_remaining_player_count
		FROM   player_state
		WHERE  tournament_rank IS NULL;

		pkg_poker_ai.log(p_message => v_remaining_player_count || ' players remain in the tournament');

		EXIT WHEN v_remaining_player_count = 0;

		-- init new game
		pkg_poker_ai.initialize_game(
			p_small_blind_seat_number => v_small_blind_seat_number,
			p_small_blind_value       => 1,
			p_big_blind_value         => 2);

		-- play game
		pkg_poker_ai.play_game;

		SELECT current_game_number
		INTO   v_current_game_number
		FROM   tournament_state;
		pkg_poker_ai.log(p_message => 'game ' || v_current_game_number || ' complete');

		-- update number of games played in the tournament
		pkg_poker_ai.log(p_message => 'updating tournament state games played');
		UPDATE tournament_state
		SET    current_game_number = current_game_number + 1;

		IF v_current_game_number > 500 THEN
			pkg_poker_ai.log(p_message => 'over 500 games played in tournament, aborting');
			EXIT;
		END IF;

		-- move the small blind to next active player
		pkg_poker_ai.log(p_message => 'advancing small blind seat');
		v_small_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(p_current_player_seat_number => v_small_blind_seat_number);

	END LOOP;

END play_tournament;
*/

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
    p_small_blind_value       game_state.small_blind_value%TYPE,
    p_big_blind_value         game_state.big_blind_value%TYPE
) IS

	v_big_blind_seat_number   game_state.big_blind_seat_number%TYPE;
	v_turn_seat_number        game_state.turn_seat_number%TYPE;

BEGIN

	pkg_poker_ai.log(p_message => 'initializing game start');

	pkg_poker_ai.clear_game_state;

	-- initialize player state
	pkg_poker_ai.log(p_message => 'clearing player state cards and game rank');
	UPDATE player_state
	SET    hole_card_1 = NULL,
		   hole_card_2 = NULL,
		   best_hand_card_1 = NULL,
		   best_hand_card_2 = NULL,
		   best_hand_card_3 = NULL,
		   best_hand_card_4 = NULL,
		   best_hand_card_5 = NULL,
		   hand_showing = 'N',
		   state = CASE WHEN state = 'OUT_OF_TOURNAMENT' THEN 'OUT_OF_TOURNAMENT' ELSE 'NO_MOVE' END,
		   game_rank = NULL,
		   presented_bet_opportunity = 'N';

	-- determine seats
	v_big_blind_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_current_player_seat_number => p_small_blind_seat_number,
		p_include_folded_players     => 'Y'
	);
	v_turn_seat_number := pkg_poker_ai.get_next_active_seat_number(
		p_current_player_seat_number => v_big_blind_seat_number,
		p_include_folded_players     => 'Y'
	);
	pkg_poker_ai.log(p_message => 'small blind seat number = ' || p_small_blind_seat_number);
	pkg_poker_ai.log(p_message => 'big blind seat number = ' || v_big_blind_seat_number);
	pkg_poker_ai.log(p_message => 'initial turn seat number = ' || v_turn_seat_number);

	-- initialize game state
	pkg_poker_ai.log(p_message => 'initializing game state');
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
		p_big_blind_value,
		NULL,
		'N',
		p_big_blind_value
	);
   
END initialize_game;

/*
PROCEDURE play_game IS

	v_active_players_remaining INTEGER;
	v_round                    INTEGER := 1;

BEGIN

	pkg_poker_ai.log(p_message => 'playing game');

	LOOP
		
		-- do a betting round to determine the number of active players remaining
		v_active_players_remaining := play_round;
		
		-- quit when there is only one active player remaining (everyone else folded) or all three betting rounds have been played
		pkg_poker_ai.log(p_message => 'round ' || v_round || ', ' || v_active_players_remaining || ' players remain in the game');
		EXIT WHEN v_active_players_remaining <= 1 OR v_round > 3;

		-- reset non-folded active player states
		UPDATE player_state
		SET    state = 'NO_MOVE'
		WHERE  tournament_rank IS NULL
		   AND state != 'FOLDED';

		-- increment round and update game state
		pkg_poker_ai.log(p_message => 'round ' || v_round || ' complete');
		v_round := v_round + 1;

		UPDATE game_state
		SET    betting_round_number = v_round;

	END LOOP;

	-- determine the outcome of the game
	pkg_poker_ai.process_game_results;

END play_game;

FUNCTION play_round RETURN INTEGER IS

	v_betting_round_number game_state.betting_round_number%TYPE;
	v_turn_seat_number     game_state.turn_seat_number%TYPE;
	v_player_count         tournament_state.player_count%TYPE;
	v_active_players       tournament_state.player_count%TYPE;
	v_uneven_pot_count     INTEGER;

BEGIN

	-- get tournament state
	SELECT player_count
	INTO   v_player_count
	FROM   tournament_state;

	-- get game state
	SELECT betting_round_number,
		   turn_seat_number
	INTO   v_betting_round_number,
		   v_turn_seat_number
	FROM   game_state;

	pkg_poker_ai.log(p_message => 'begin playing betting round ' || v_betting_round_number);

	-- deal cards
	IF v_betting_round_number = 1 THEN
		
		-- post blinds
		pkg_poker_ai.log(p_message => 'posting blinds');
		pkg_poker_ai.post_blinds;

		-- deal hole cards
		pkg_poker_ai.log(p_message => 'dealing hole cards');
		UPDATE player_state
		SET    hole_card_1 = pkg_poker_ai.draw_deck_card,
			   hole_card_2 = pkg_poker_ai.draw_deck_card;

	ELSIF v_betting_round_number = 2 THEN

		-- deal flop
		pkg_poker_ai.log(p_message => 'dealing flop');
		UPDATE game_state
		SET    community_card_1 = pkg_poker_ai.draw_deck_card,
			   community_card_2 = pkg_poker_ai.draw_deck_card,
			   community_card_3 = pkg_poker_ai.draw_deck_card;

	ELSIF v_betting_round_number = 3 THEN

		-- deal turn
		pkg_poker_ai.log(p_message => 'dealing turn');
		UPDATE game_state
		SET    community_card_4 = pkg_poker_ai.draw_deck_card;

	ELSIF v_betting_round_number = 4 THEN

		-- deal river
		pkg_poker_ai.log(p_message => 'dealing river');
		UPDATE game_state
		SET    community_card_5 = pkg_poker_ai.draw_deck_card;

	END IF;

	-- betting loop
	LOOP

		pkg_poker_ai.log(p_message => 'begin betting loop, ' || v_player_count || ' active players remain');

		-- for every active non-folded player that has some money left, let them make their move
		FOR v_player IN (
			SELECT seat_number
			FROM   player_state
			WHERE  tournament_rank IS NULL
			   AND state != 'FOLDED'
			   AND money > 0
			ORDER BY MOD(seat_number - v_turn_seat_number + v_player_count, v_player_count)
		) LOOP
			v_active_players := pkg_poker_ai.get_active_player_count;

			IF v_active_players > 1 THEN
				pkg_poker_ai.perform_player_move(p_seat_number => v_player.seat_number);
			END IF;
		END LOOP;
		pkg_poker_ai.log(p_message => 'end betting loop');

		-- if the pots aren't even, continue betting loop
		SELECT MAX(COUNT(DISTINCT p.pot_number)) uneven_pot_count
		INTO   v_uneven_pot_count
		FROM   pot p,
			   player_state ps
		WHERE  p.player_seat_number = ps.seat_number
		   AND ps.state != 'FOLDED'
		GROUP BY p.pot_number
		HAVING COUNT(DISTINCT p.pot_contribution) != 1;

		-- exit betting loop when the pots are squared up or everyone folded except one player
		v_active_players := pkg_poker_ai.get_active_player_count;
		EXIT WHEN v_uneven_pot_count = 0 OR v_active_players <= 1;

	END LOOP;
	pkg_poker_ai.log(p_message => 'end betting loop, ' || v_active_players || ' active players remain');
	pkg_poker_ai.log(p_message => 'end playing betting round ' || v_betting_round_number);

	RETURN v_active_players;

END play_round;
*/

FUNCTION get_next_active_seat_number
(
	p_current_player_seat_number player_state.seat_number%TYPE,
	p_include_folded_players     VARCHAR2
) RETURN player_state.seat_number%TYPE IS

	v_next_player_seat_number player_state.seat_number%TYPE;

BEGIN

	-- get the seat number of the next active player clockwise of current player
	SELECT MIN(seat_number) next_player_seat_number
	INTO   v_next_player_seat_number
	FROM   player_state
	WHERE  seat_number > p_current_player_seat_number
	   AND state != 'OUT_OF_TOURNAMENT'
	   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END;

	IF v_next_player_seat_number IS NULL THEN
		SELECT MIN(seat_number) next_player_seat_number
		INTO   v_next_player_seat_number
		FROM   player_state
		WHERE  seat_number < p_current_player_seat_number
		   AND state != 'OUT_OF_TOURNAMENT'
		   AND state != CASE WHEN p_include_folded_players = 'N' THEN 'FOLDED' ELSE '-X-' END;
	END IF;

	RETURN v_next_player_seat_number;
	
END get_next_active_seat_number;

FUNCTION draw_deck_card RETURN deck.card_id%TYPE IS

	v_drawn_card_id deck.card_id%TYPE;

BEGIN

	-- draw a non-played card at random, mark as in play
	WITH remaining_deck AS (
		SELECT card_id
		FROM   deck
		WHERE  dealt = 'N'
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

END post_blinds;

PROCEDURE perform_player_move
(
	p_seat_number        player_state.seat_number%TYPE,
	p_player_move        NUMBER,
	p_player_move_amount NUMBER
) IS

	v_can_fold              VARCHAR2(1) := 'Y';
	v_can_check             VARCHAR2(1) := 'N';
	v_can_call              VARCHAR2(1) := 'N';
	v_can_raise             VARCHAR2(1) := 'N';
	v_current_pot_bet_value pot.bet_value%TYPE;
	v_total_deficit         pot_contribution.pot_contribution%TYPE;
	v_player_money          player_state.money%TYPE;
	
BEGIN

	IF p_player_move != 0 THEN
		-- overriding player move is being sent from the UI
		IF p_player_move = 1 THEN
		
			-- fold
			pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' folds');
			UPDATE player_state
			SET    state = 'FOLDED'
			WHERE  seat_number = p_seat_number;
		
		ELSIF p_player_move = 2 THEN
		
			-- check
			pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' checks');
			UPDATE player_state
			SET    state = CASE WHEN state != 'ALL_IN' THEN 'CHECKED' ELSE 'ALL_IN' END
			WHERE  seat_number = p_seat_number;
			
		ELSIF p_player_move = 3 THEN
		
			-- call
			pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' calls');
			
			-- determine call amount
			SELECT SUM(CASE WHEN pc.player_seat_number IS NULL THEN p.bet_value ELSE p.bet_value - pc.pot_contribution END) deficit
			INTO   v_total_deficit
			FROM   game_state gs,
				   pot p,
				   pot_contribution pc
			WHERE  gs.betting_round_number = p.betting_round_number
			   AND p.pot_number = pc.pot_number (+)
			   AND p.betting_round_number = pc.betting_round_number (+)
			   AND pc.player_seat_number (+) = p_seat_number;
			
			-- determine player's money
			SELECT money
			INTO   v_player_money
			FROM   player_state
			WHERE  seat_number = p_seat_number;
			
			pkg_poker_ai.contribute_to_pot(
				p_player_seat_number => p_seat_number,
				p_pot_contribution   => LEAST(v_player_money, v_total_deficit)
			);

			UPDATE player_state
			SET    state = CASE WHEN state != 'ALL_IN' THEN 'CALLED' ELSE 'ALL_IN' END
			WHERE  seat_number = p_seat_number;
	
		ELSIF p_player_move = 4 THEN
		
			-- bet
			pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' bets ' || p_player_move_amount);
			
			pkg_poker_ai.contribute_to_pot(
				p_player_seat_number => p_seat_number,
				p_pot_contribution   => p_player_move_amount
			);

			UPDATE player_state
			SET    state = CASE WHEN state != 'ALL_IN' THEN 'BET' ELSE 'ALL_IN' END
			WHERE  seat_number = p_seat_number;
			
			UPDATE game_state
			SET    last_to_raise_seat_number = p_seat_number,
				   min_raise_amount = CASE WHEN p_player_move_amount < min_raise_amount THEN min_raise_amount + p_player_move_amount ELSE p_player_move_amount END;
		
		ELSIF p_player_move = 5 THEN
		
			-- raise
			pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' raises ' || p_player_move_amount);
 
			SELECT p.bet_value
			INTO   v_current_pot_bet_value
			FROM   game_state gs,
				   pot p
			WHERE  gs.betting_round_number = p.betting_round_number
			   AND p.pot_number = (
					SELECT MAX(p.pot_number)
					FROM   game_state gs,
						   pot p
					WHERE  gs.betting_round_number = p.betting_round_number);
			
			pkg_poker_ai.contribute_to_pot(
				p_player_seat_number => p_seat_number,
				p_pot_contribution   => (v_current_pot_bet_value + p_player_move_amount)
			);

			UPDATE player_state
			SET    state = CASE WHEN state != 'ALL_IN' THEN 'RAISED' ELSE 'ALL_IN' END
			WHERE  seat_number = p_seat_number;
			
			UPDATE game_state
			SET    last_to_raise_seat_number = p_seat_number,
				   min_raise_amount = CASE WHEN p_player_move_amount < min_raise_amount THEN min_raise_amount + p_player_move_amount ELSE p_player_move_amount END;
		
		END IF;
		
		RETURN;
	END IF;
	
	-- else automatic move determination
	/*

	SELECT last_to_raise_seat_number
	INTO   v_last_to_raise_seat_number
	FROM   game_state;

	IF v_last_to_raise_seat_number IS NOT NULL THEN
		NULL;
	END IF;

	-- possible moves:
	-- 0 - auto
	-- 1 - fold
	-- 2 - check
	-- 3 - call
	-- raise

	-- deterime if player can check
	SELECT CASE WHEN pc.player_seat_number IS NULL OR p.bet_value != pc.pot_contribution THEN 'N' ELSE 'Y' END
	INTO   v_can_check
	FROM   pot p,
		   pot_contribution pc
	WHERE  p.pot_number = pc.pot_number (+)
	   AND pc.player_seat_number (+) = p_seat_number;

	-- determine if player can call or raise
	IF v_can_check = 'N' THEN
		v_can_call := 'Y';
		v_can_raise := 'Y';
	END IF;
	*/

	-- fold
	pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' folds');
	UPDATE player_state
	SET    state = 'FOLDED'
	WHERE  seat_number = p_seat_number;

END perform_player_move;

FUNCTION get_player_showdown_muck(
	p_seat_number player_state.seat_number%TYPE
) RETURN BOOLEAN IS
BEGIN
	
	RETURN FALSE;
	--pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' chooses not to show cards');

END get_player_showdown_muck;

FUNCTION get_active_player_count RETURN INTEGER IS

	v_active_players INTEGER;

BEGIN

	SELECT COUNT(*) active_players
	INTO   v_active_players
	FROM   player_state
	WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED');

	RETURN v_active_players;

END get_active_player_count;

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
			   game_rank = 1
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
			SELECT seat_number
			FROM   player_state
			WHERE  state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
			ORDER BY MOD(seat_number + (v_first_to_show_seat_number - 1), v_active_player_count)
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
					   RANK() OVER (PARTITION BY pc.pot_number, pc.betting_round_number ORDER BY ps.best_hand_rank DESC) pot_rank
				FROM   player_state ps,
					   pot_contribution pc
				WHERE  ps.hand_showing = 'Y'
				   AND ps.seat_number = pc.player_seat_number
			),

			pot_winner_counts AS (
				SELECT pr.pot_number,
					   COUNT(*) pot_winners_count,
					   FLOOR(MIN(ps.pot_value) / COUNT(*)) per_player_amount,
					   CASE WHEN FLOOR(MIN(ps.pot_value) / COUNT(*)) != (MIN(ps.pot_value) / COUNT(*)) THEN 'Y' ELSE 'N' END odd_split
				FROM   pot_ranks pr,
					   pot_sums ps
				WHERE  pr.pot_rank = 1
				   AND pr.pot_number = ps.pot_number
				GROUP BY pr.pot_number
			),

			-- winning player closest to small blind going clockwise gets any odd split chip per pot
			player_positions AS (
				SELECT DISTINCT
					   pot_number,
					   MIN(seat_number) KEEP (DENSE_RANK FIRST ORDER BY distance_from_small_blind) OVER (PARTITION BY pot_number) odd_chip_keeper
				FROM   pot_ranks
				WHERE  pot_rank = 1
			)

			SELECT pr.pot_number,
				   pr.seat_number,
				   CASE WHEN pwc.odd_split = 'Y' AND pr.seat_number = pp.odd_chip_keeper THEN pwc.per_player_amount + 1
						ELSE pwc.per_player_amount
				   END player_winnings
			FROM   pot_winner_counts pwc,
				   pot_ranks pr,
				   player_positions pp
			WHERE  pwc.pot_number = pr.pot_number
			   AND pr.pot_rank = 1
			   AND pr.pot_number = pp.pot_number
			ORDER BY
				pot_number,
				seat_number
		) LOOP

			-- distribute pot money
			pkg_poker_ai.log(p_message => 'player at seat ' || v_winners_rec.seat_number || ' wins ' || v_winners_rec.player_winnings || ' from pot ' || v_winners_rec.pot_number);
			UPDATE player_state
			SET    money = money + v_winners_rec.player_winnings
			WHERE  seat_number = v_winners_rec.seat_number;

		END LOOP;

	END IF;

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

FUNCTION get_distance_from_small_blind (
	p_seat_number player_state.seat_number%TYPE
) RETURN INTEGER IS

	v_small_blind_seat_number player_state.seat_number%TYPE;

BEGIN

	SELECT small_blind_seat_number
	INTO   v_small_blind_seat_number
	FROM   game_state;

	IF p_seat_number >= v_small_blind_seat_number THEN
		RETURN p_seat_number - v_small_blind_seat_number;
	ELSE
		RETURN v_small_blind_seat_number + p_seat_number;
	END IF;

END get_distance_from_small_blind;

FUNCTION get_hand_rank(
	p_card_1 deck.card_id%TYPE,
	p_card_2 deck.card_id%TYPE,
	p_card_3 deck.card_id%TYPE,
	p_card_4 deck.card_id%TYPE,
	p_card_5 deck.card_id%TYPE
) RETURN VARCHAR2 IS

	v_hand_rank  VARCHAR2(17);
	v_card_order VARCHAR2(14);
	v_row_hand   t_row_hand := t_row_hand(NULL, NULL, NULL, NULL);
	v_tbl_hand   t_tbl_hand := t_tbl_hand();

BEGIN

	IF p_card_1 IS NULL OR p_card_2 IS NULL OR p_card_3 IS NULL OR p_card_4 IS NULL OR p_card_5 IS NULL THEN
		-- incomplete hand
		RETURN '00';
	END IF;

	-- store hand for read back
	v_tbl_hand.EXTEND(5);
	FOR v_rec IN (
		WITH cards AS (
			SELECT card_id,
				   suit,
				   value
			FROM   deck
			WHERE  card_id IN (p_card_1, p_card_2, p_card_3, p_card_4, p_card_5)
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

FUNCTION get_card_display_value(
	p_card_id deck.card_id%TYPE
) RETURN deck.display_value%TYPE RESULT_CACHE IS

	v_display_value deck.display_value%TYPE;

BEGIN

	SELECT LPAD(display_value, 4, ' ') display_value
	INTO   v_display_value
	FROM   deck
	WHERE  card_id = p_card_id;

	RETURN v_display_value;	

END get_card_display_value;

FUNCTION get_hand_rank_display_value(
	p_hand_rank player_state.best_hand_rank%TYPE
) RETURN VARCHAR2 IS

	v_display_value VARCHAR2(30);

BEGIN

	CASE SUBSTR(p_hand_rank, 1, 2)
		WHEN '01' THEN v_display_value  := 'High Card';
		WHEN '02' THEN v_display_value  := 'One Pair';
		WHEN '03' THEN v_display_value  := 'Two Pair';
		WHEN '04' THEN v_display_value  := 'Three of a Kind';
		WHEN '05' THEN v_display_value  := 'Straight';
		WHEN '06' THEN v_display_value  := 'Flush';
		WHEN '07' THEN v_display_value  := 'Full House';
		WHEN '08' THEN v_display_value  := 'Four of a Kind';
		WHEN '09' THEN v_display_value  := 'Straight Flush';
		WHEN '10' THEN v_display_value  := 'Royal Flush';
		ELSE v_display_value := NULL;
	END CASE;

	RETURN v_display_value;
		
END get_hand_rank_display_value;

/*
FUNCTION get_hand_display_value(
	p_hand_rank player_state.best_hand_rank%TYPE,
	p_card_1    deck.card_id%TYPE,
	p_card_2    deck.card_id%TYPE,
	p_card_3    deck.card_id%TYPE,
	p_card_4    deck.card_id%TYPE,
	p_card_5    deck.card_id%TYPE
) RETURN VARCHAR2 IS

	v_display_value VARCHAR2(51);

BEGIN

	IF p_hand_rank IS NULL THEN
		RETURN NULL;
	END IF;

	CASE SUBSTR(p_hand_rank, 1, 2)
		WHEN '01' THEN v_display_value  := '01 - High Card       : ';
		WHEN '02' THEN v_display_value  := '02 - One Pair        : ';
		WHEN '03' THEN v_display_value  := '03 - Two Pair        : ';
		WHEN '04' THEN v_display_value  := '04 - Three of a Kind : ';
		WHEN '05' THEN v_display_value  := '05 - Straight        : ';
		WHEN '06' THEN v_display_value  := '06 - Flush           : ';
		WHEN '07' THEN v_display_value  := '07 - Full House      : ';
		WHEN '08' THEN v_display_value  := '08 - Four of a Kind  : ';
		WHEN '09' THEN v_display_value  := '09 - Straight Flush  : ';
		WHEN '10' THEN v_display_value  := '10 - Royal Flush     : ';
	END CASE;

	SELECT v_display_value || LISTAGG(LPAD(display_value, 4, ' '), '  ') WITHIN GROUP (ORDER BY value DESC, suit) display_value
	INTO   v_display_value
	FROM   deck
	WHERE  card_id IN (p_card_1, p_card_2, p_card_3, p_card_4, p_card_5);

	RETURN v_display_value;

END get_hand_display_value;
*/

PROCEDURE select_ui_state (
	p_last_log_record_number poker_ai_log.log_record_number%TYPE,
	p_tournament_state       OUT t_rc_generic,
	p_game_state             OUT t_rc_generic,
	p_player_state           OUT t_rc_generic,
	p_pots                   OUT t_rc_generic,
	p_status                 OUT t_rc_generic
) IS

	v_max_player_count INTEGER := 10;

BEGIN

	OPEN p_tournament_state FOR
		SELECT player_count,
			   buy_in_amount,
			   current_game_number,
			   CASE game_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END game_in_progress
		FROM   tournament_state;

	OPEN p_game_state FOR
		SELECT small_blind_seat_number,
			   big_blind_seat_number,
			   turn_seat_number,
			   small_blind_value,
			   big_blind_value,
			   CASE betting_round_number
					WHEN 1 THEN '1 - Pre-flop'
					WHEN 2 THEN '2 - Flop'
					WHEN 3 THEN '3 - Turn'
					WHEN 4 THEN '4 - River'
			   END betting_round_number,
			   CASE betting_round_in_progress WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' END betting_round_in_progress,
			   last_to_raise_seat_number,
			   community_card_1,
			   community_card_2,
			   community_card_3,
			   community_card_4,
			   community_card_5
		FROM   game_state;

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
				   pkg_poker_ai.get_hand_rank_display_value(ps.best_hand_rank) best_hand_rank_type
			FROM   player_state ps,
				   active_player_count apc
			WHERE  ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
			   AND ps.best_hand_rank IS NOT NULL
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
			   CASE WHEN ps.state IS NULL THEN 'No Player'
					WHEN ps.state = 'NO_MOVE' THEN 'No Move'
					WHEN ps.state = 'FOLDED' THEN 'Folded'
					WHEN ps.state = 'CHECKED' THEN 'Checked'
					WHEN ps.state = 'CALLED' THEN 'Called'
					WHEN ps.state = 'BET' THEN 'Bet'
					WHEN ps.state = 'RAISED' THEN 'Raised'
					WHEN ps.state = 'OUT_OF_TOURNAMENT' THEN 'Out of Tournament'
					WHEN ps.state = 'ALL_IN' THEN 'All In'
					ELSE ps.state
			   END state,
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
			   hand_ranks hr
		WHERE  s.seat_number = ps.seat_number (+)
		   AND s.seat_number = pc.player_seat_number (+)
		   AND s.seat_number = hr.seat_number (+)
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

	IF p_last_log_record_number IS NULL THEN
		OPEN p_status FOR
			SELECT log_record_number,
				   message
			FROM   poker_ai_log
			WHERE  log_record_number = (SELECT MAX(log_record_number) FROM poker_ai_log);
	ELSE
		OPEN p_status FOR
			SELECT log_record_number,
				   message
			FROM   poker_ai_log
			WHERE  log_record_number > p_last_log_record_number
			ORDER BY log_record_number;
	END IF;

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

		possible_hands AS (
			-- 7 choose 5 = 21 possible combinations per player
			SELECT '1,2,3,4,5' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c4, c5) hand_rank, c1 card_1, c2 card_2, c3 card_3, c4 card_4, c5 card_5 FROM players UNION ALL
			SELECT '1,2,3,4,6' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c4, c6) hand_rank, c1 card_1, c2 card_2, c3 card_3, c4 card_4, c6 card_5 FROM players UNION ALL
			SELECT '1,2,3,4,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c4, c7) hand_rank, c1 card_1, c2 card_2, c3 card_3, c4 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,2,3,5,6' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c5, c6) hand_rank, c1 card_1, c2 card_2, c3 card_3, c5 card_4, c6 card_5 FROM players UNION ALL
			SELECT '1,2,3,5,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c5, c7) hand_rank, c1 card_1, c2 card_2, c3 card_3, c5 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,2,3,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c3, c6, c7) hand_rank, c1 card_1, c2 card_2, c3 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,2,4,5,6' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c4, c5, c6) hand_rank, c1 card_1, c2 card_2, c4 card_3, c5 card_4, c6 card_5 FROM players UNION ALL
			SELECT '1,2,4,5,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c4, c5, c7) hand_rank, c1 card_1, c2 card_2, c4 card_3, c5 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,2,4,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c4, c6, c7) hand_rank, c1 card_1, c2 card_2, c4 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,2,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c2, c5, c6, c7) hand_rank, c1 card_1, c2 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,3,4,5,6' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c3, c4, c5, c6) hand_rank, c1 card_1, c3 card_2, c4 card_3, c5 card_4, c6 card_5 FROM players UNION ALL
			SELECT '1,3,4,5,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c3, c4, c5, c7) hand_rank, c1 card_1, c3 card_2, c4 card_3, c5 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,3,4,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c3, c4, c6, c7) hand_rank, c1 card_1, c3 card_2, c4 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,3,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c3, c5, c6, c7) hand_rank, c1 card_1, c3 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '1,4,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c1, c4, c5, c6, c7) hand_rank, c1 card_1, c4 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '2,3,4,5,6' combination, seat_number, pkg_poker_ai.get_hand_rank(c2, c3, c4, c5, c6) hand_rank, c2 card_1, c3 card_2, c4 card_3, c5 card_4, c6 card_5 FROM players UNION ALL
			SELECT '2,3,4,5,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c2, c3, c4, c5, c7) hand_rank, c2 card_1, c3 card_2, c4 card_3, c5 card_4, c7 card_5 FROM players UNION ALL
			SELECT '2,3,4,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c2, c3, c4, c6, c7) hand_rank, c2 card_1, c3 card_2, c4 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '2,3,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c2, c3, c5, c6, c7) hand_rank, c2 card_1, c3 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '2,4,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c2, c4, c5, c6, c7) hand_rank, c2 card_1, c4 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players UNION ALL
			SELECT '3,4,5,6,7' combination, seat_number, pkg_poker_ai.get_hand_rank(c3, c4, c5, c6, c7) hand_rank, c3 card_1, c4 card_2, c5 card_3, c6 card_4, c7 card_5 FROM players
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
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED');
	   
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
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
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
	   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
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
			   player_state ps
		WHERE  ps.seat_number = p_seat_number
		   AND gs.turn_seat_number = p_seat_number
		   AND gs.betting_round_in_progress = 'Y'
		   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		   AND pkg_poker_ai.get_pot_deficit(p_seat_number => p_seat_number) = 0
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

	player_raise_state AS (
		SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END can_raise
		FROM   game_state gs,
			   player_state ps
		WHERE  ps.seat_number = p_seat_number
		   AND gs.turn_seat_number = p_seat_number
		   AND gs.betting_round_in_progress = 'Y'
		   AND ps.state NOT IN ('OUT_OF_TOURNAMENT', 'FOLDED')
		   AND (ps.money - pkg_poker_ai.get_pot_deficit(p_seat_number => ps.seat_number)) > 0
	)

	SELECT CASE WHEN be.bet_exists = 'Y' AND prs.can_raise = 'Y' THEN 'Y' ELSE 'N' END can_raise
	INTO   v_result
	FROM   bet_exists be,
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

	SELECT MIN(CASE WHEN ps.money < gs.min_raise_amount THEN ps.money ELSE gs.min_raise_amount END) min_raise
	INTO   v_min_raise
	FROM   game_state gs,
		   player_state ps
	WHERE  ps.seat_number = p_seat_number;
	
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
	SELECT MAX(pot_number) v_round_highest_pot_number
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
			   AND pc.player_seat_number = p_player_seat_number
			   AND (p.bet_value - pc.pot_contribution) != 0
			   
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
			
		END LOOP;
	
	END IF;
	
	-- remove money from player's stack and flag all in state when needed
	UPDATE player_state
	SET    money = money - p_pot_contribution,
		   state = CASE WHEN money - p_pot_contribution = 0 THEN 'ALL_IN' ELSE state END
	WHERE  seat_number = p_player_seat_number;
	
END contribute_to_pot;

END pkg_poker_ai;

