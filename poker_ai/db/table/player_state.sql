CREATE TABLE player_state
(
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

ALTER TABLE player_state ADD
(
	CONSTRAINT ps_pk_pid PRIMARY KEY (player_id)
);

ALTER TABLE player_state ADD
(
	CONSTRAINT ps_fk_pid FOREIGN KEY (player_id) REFERENCES player(player_id),
    CONSTRAINT ps_fk_hc1 FOREIGN KEY (hole_card_1) REFERENCES deck(card_id),
    CONSTRAINT ps_fk_hc2 FOREIGN KEY (hole_card_2) REFERENCES deck(card_id)
);
