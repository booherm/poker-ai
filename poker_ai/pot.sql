CREATE TABLE pot
(
	pot_number         NUMBER(2, 0),
	player_seat_number NUMBER(2, 0),
	pot_contribution   NUMBER(10, 0)
);

ALTER TABLE pot ADD
(
	CONSTRAINT p_pk_pnpsn PRIMARY KEY (pot_number, player_seat_number)
);
