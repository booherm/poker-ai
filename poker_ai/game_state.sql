CREATE TABLE game_state
(
	small_blind_seat_number   NUMBER(2, 0),
    big_blind_seat_number     NUMBER(2, 0),
    turn_seat_number          NUMBER(2, 0),
    small_blind_value         NUMBER(10, 0),
    big_blind_value           NUMBER(10, 0),
    round_number              NUMBER(1, 0),
	last_to_raise_seat_number NUMBER(2, 0),
    community_card_1          NUMBER(2, 0),
    community_card_2          NUMBER(2, 0),
    community_card_3          NUMBER(2, 0),
    community_card_4          NUMBER(2, 0),
    community_card_5          NUMBER(2, 0)
);

ALTER TABLE game_state ADD
(
    CONSTRAINT gs_fk_cc1 FOREIGN KEY (community_card_1) REFERENCES deck(card_id),
    CONSTRAINT gs_fk_cc2 FOREIGN KEY (community_card_2) REFERENCES deck(card_id),
    CONSTRAINT gs_fk_cc3 FOREIGN KEY (community_card_3) REFERENCES deck(card_id),
    CONSTRAINT gs_fk_cc4 FOREIGN KEY (community_card_4) REFERENCES deck(card_id),
    CONSTRAINT gs_fk_cc5 FOREIGN KEY (community_card_5) REFERENCES deck(card_id)
);
