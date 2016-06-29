CREATE OR REPLACE TYPE t_row_pot_contribution AS OBJECT
(
	pot_number           NUMBER(10, 0),
	betting_round_number NUMBER(1, 0),
	player_seat_number   NUMBER(2, 0),
	pot_contribution     NUMBER(10, 0)
);
