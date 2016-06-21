CREATE GLOBAL TEMPORARY TABLE pot
(
	pot_number           NUMBER(2, 0),
	betting_round_number NUMBER(1, 0),
	bet_value            NUMBER(10, 0)
) ON COMMIT PRESERVE ROWS;

ALTER TABLE pot ADD
(
	CONSTRAINT p_pk_pnpsnbrn PRIMARY KEY (pot_number, betting_round_number)
);
