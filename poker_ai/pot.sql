CREATE TABLE pot
(
	pot_number NUMBER(2, 0),
	bet_value  NUMBER(10, 0)
);

ALTER TABLE pot ADD
(
	CONSTRAINT p_pk_pnpsn PRIMARY KEY (pot_number)
);
