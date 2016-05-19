CREATE TABLE pot_contribution_log
(
	state_id             NUMBER(38, 0),
	pot_number           NUMBER(2, 0),
	betting_round_number NUMBER(1, 0),
	player_seat_number   NUMBER(2, 0),
	pot_contribution     NUMBER(10, 0)
);

ALTER TABLE pot_contribution_log ADD
(
	CONSTRAINT pcl_pk_sidpnbrnpsn PRIMARY KEY (state_id, pot_number, betting_round_number, player_seat_number)
);
