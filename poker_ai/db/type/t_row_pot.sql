CREATE OR REPLACE TYPE t_row_pot AS OBJECT
(
	pot_number           NUMBER(2, 0),
	betting_round_number NUMBER(1, 0),
	bet_value            NUMBER(10, 0)
);