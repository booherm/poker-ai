CREATE TABLE pot_log
(
	state_id             NUMBER(38, 0),
	pot_number           NUMBER(2, 0),
	betting_round_number NUMBER(1, 0),
	bet_value            NUMBER(10, 0)
) INMEMORY;

ALTER TABLE pot_log ADD
(
	CONSTRAINT pl_pk_sidpnbrn PRIMARY KEY (state_id, pot_number, betting_round_number)
);
