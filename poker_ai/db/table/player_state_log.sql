CREATE TABLE player_state_log
(
	state_id                  NUMBER(38, 0),
	player_id                 NUMBER(10, 0),
	seat_number               NUMBER(2, 0),
    hole_card_1               NUMBER(2, 0),
    hole_card_2               NUMBER(2, 0),
	best_hand_combination     VARCHAR2(9),
	best_hand_rank            VARCHAR2(17),
	best_hand_card_1          NUMBER(2, 0),
	best_hand_card_2          NUMBER(2, 0),
	best_hand_card_3          NUMBER(2, 0),
	best_hand_card_4          NUMBER(2, 0),
	best_hand_card_5          NUMBER(2, 0),
	hand_showing              VARCHAR2(1),
	presented_bet_opportunity VARCHAR2(1),
    money                     NUMBER(10, 0),
    state                     VARCHAR2(20),
	game_rank                 NUMBER(2, 0),
	tournament_rank           NUMBER(2, 0)
);

ALTER TABLE player_state_log ADD
(
	CONSTRAINT psl_pk_sidpid PRIMARY KEY (state_id, player_id)
);
