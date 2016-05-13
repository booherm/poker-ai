BEGIN
	
	pkg_poker_ai.initialize_tournament(
		p_player_count  => 8,
		p_buy_in_amount => 50);

	pkg_poker_ai.play_tournament;

END;

BEGIN
	
	pkg_poker_ai.initialize_game(
		p_small_blind_seat_number => 3,
		p_small_blind_value       => 1,
		p_big_blind_value         => 2);

END;

BEGIN
	pkg_poker_ai.play_game;
END;

DECLARE
	v_active_players INTEGER;
BEGIN
	
	v_active_players := pkg_poker_ai.play_round;
	DBMS_OUTPUT.PUT_LINE('v_active_players = ' || v_active_players);

END;

EXEC pkg_poker_ai.process_game_results;

-- setup random hands and compare
DECLARE

	v_h1_card_1 deck.card_id%TYPE;
	v_h1_card_2 deck.card_id%TYPE;
	v_h1_card_3 deck.card_id%TYPE;
	v_h1_card_4 deck.card_id%TYPE;
	v_h1_card_5 deck.card_id%TYPE;
	v_h2_card_1 deck.card_id%TYPE;
	v_h2_card_2 deck.card_id%TYPE;
	v_h2_card_3 deck.card_id%TYPE;
	v_h2_card_4 deck.card_id%TYPE;
	v_h2_card_5 deck.card_id%TYPE;
	v_h1_rank VARCHAR2(50);
	v_h2_rank VARCHAR2(50);

BEGIN

	EXECUTE IMMEDIATE 'TRUNCATE TABLE hand_compare_test';
	FOR v_i IN 1 .. 1000 LOOP

		-- reset deck
		UPDATE deck
		SET    dealt = 'N';

		v_h1_card_1 := pkg_poker_ai.draw_deck_card;
		v_h1_card_2 := pkg_poker_ai.draw_deck_card;
		v_h1_card_3 := pkg_poker_ai.draw_deck_card;
		v_h1_card_4 := pkg_poker_ai.draw_deck_card;
		v_h1_card_5 := pkg_poker_ai.draw_deck_card;
		v_h2_card_1 := pkg_poker_ai.draw_deck_card;
		v_h2_card_2 := pkg_poker_ai.draw_deck_card;
		v_h2_card_3 := pkg_poker_ai.draw_deck_card;
		v_h2_card_4 := pkg_poker_ai.draw_deck_card;
		v_h2_card_5 := pkg_poker_ai.draw_deck_card;

		v_h1_rank := pkg_poker_ai.get_hand_rank(
			p_card_1 => v_h1_card_1,
			p_card_2 => v_h1_card_2,
			p_card_3 => v_h1_card_3,
			p_card_4 => v_h1_card_4,
			p_card_5 => v_h1_card_5
		);
		v_h2_rank := pkg_poker_ai.get_hand_rank(
			p_card_1 => v_h2_card_1,
			p_card_2 => v_h2_card_2,
			p_card_3 => v_h2_card_3,
			p_card_4 => v_h2_card_4,
			p_card_5 => v_h2_card_5
		);

		INSERT INTO hand_compare_test(
			comparison_number,
			h1_c1,
			h1_c2,
			h1_c3,
			h1_c4,
			h1_c5,
			h2_c1,
			h2_c2,
			h2_c3,
			h2_c4,
			h2_c5,
			hand_1_rank,
			hand_1_display_value,
			hand_2_rank,
			hand_2_display_value,
			better_hand
		) VALUES (
			pai_seq_generic.NEXTVAL,
			v_h1_card_1,
			v_h1_card_2,
			v_h1_card_3,
			v_h1_card_4,
			v_h1_card_5,
			v_h2_card_1,
			v_h2_card_2,
			v_h2_card_3,
			v_h2_card_4,
			v_h2_card_5,
			v_h1_rank,
			pkg_poker_ai.get_hand_display_value(
				p_hand_rank => v_h1_rank,
				p_card_1    => v_h1_card_1,
				p_card_2    => v_h1_card_2,
				p_card_3    => v_h1_card_3,
				p_card_4    => v_h1_card_4,
				p_card_5    => v_h1_card_5),
			v_h2_rank,
			pkg_poker_ai.get_hand_display_value(
				p_hand_rank => v_h2_rank,
				p_card_1    => v_h2_card_1,
				p_card_2    => v_h2_card_2,
				p_card_3    => v_h2_card_3,
				p_card_4    => v_h2_card_4,
				p_card_5    => v_h2_card_5),
			CASE WHEN v_h1_rank > v_h2_rank THEN 1 WHEN v_h1_rank < v_h2_rank THEN 2 END
		);

	END LOOP;

END;

SELECT *
FROM   hand_comparison
ORDER BY
	hand_number,
	card_index;

SELECT pkg_poker_ai.get_hand_rank(p_hand_number => 1) hand_1_rank,
	   pkg_poker_ai.get_hand_rank(p_hand_number => 2) hand_2_rank,
	   pkg_poker_ai.get_better_hand better_hand_overall,
	   pkg_poker_ai.get_better_hand_by_high_card better_hand_by_high_card
FROM   DUAL;
	



















-- tournament state
SELECT * FROM tournament_state;

-- game state
SELECT * FROM game_state;

-- player state
SELECT seat_number,
	   player_id,
       pkg_poker_ai.get_card_display_value(p_card_id => hole_card_1) hole_card_1,
       pkg_poker_ai.get_card_display_value(p_card_id => hole_card_2) hole_card_2,
	   pkg_poker_ai.get_hand_display_value(
            p_hand_rank => best_hand_rank,
            p_card_1    => best_hand_card_1,
            p_card_2    => best_hand_card_2,
            p_card_3    => best_hand_card_3,
            p_card_4    => best_hand_card_4,
            p_card_5    => best_hand_card_5) best_possible_hand,
	   hand_showing,
       money,
       state,
       game_rank,
       tournament_rank
FROM   player_state
ORDER BY seat_number;

-- pots
SELECT * FROM pot;

-- deck
SELECT * FROM deck ORDER BY suit, value;

-- log
SELECT * FROM poker_ai_log ORDER BY log_record_number DESC;