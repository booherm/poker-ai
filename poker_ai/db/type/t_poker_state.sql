CREATE OR REPLACE TYPE t_poker_state AS OBJECT
(
	-- tournament attributes
	tournament_id             NUMBER(10, 0),
	tournament_mode           VARCHAR2(30),
	current_state_id          NUMBER(10, 0),
	evolution_trial_id        VARCHAR2(100),
	player_count              NUMBER(2, 0),
	buy_in_amount             NUMBER(10, 0),
	tournament_in_progress    VARCHAR2(1),
	current_game_number       NUMBER(10, 0),
	game_in_progress          VARCHAR2(1),
	
	-- game attributes
	small_blind_seat_number   NUMBER(2, 0),
    big_blind_seat_number     NUMBER(2, 0),
    turn_seat_number          NUMBER(2, 0),
    small_blind_value         NUMBER(10, 0),
    big_blind_value           NUMBER(10, 0),
    betting_round_number      NUMBER(1, 0),
	betting_round_in_progress VARCHAR2(1),
	last_to_raise_seat_number NUMBER(2, 0),
	min_raise_amount          NUMBER(10, 0),
    community_card_1          NUMBER(2, 0),
    community_card_2          NUMBER(2, 0),
    community_card_3          NUMBER(2, 0),
    community_card_4          NUMBER(2, 0),
    community_card_5          NUMBER(2, 0),

	player_state              t_tbl_player_state,
	pot                       t_tbl_pot,
	pot_contribution          t_tbl_pot_contribution,
	deck                      t_tbl_deck
);
