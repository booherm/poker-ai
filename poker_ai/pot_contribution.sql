CREATE TABLE pot_contribution
(
	pot_number         NUMBER(2, 0),
	player_seat_number NUMBER(2, 0),
	pot_contribution   NUMBER(10, 0)
);

ALTER TABLE pot_contribution ADD
(
	CONSTRAINT pc_pk_pnpsn PRIMARY KEY (pot_number, player_seat_number)
);

ALTER TABLE pot_contribution ADD
(
    CONSTRAINT pc_fk_pn FOREIGN KEY (pot_number) REFERENCES pot(pot_number)
);
