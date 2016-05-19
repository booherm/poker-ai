CREATE OR REPLACE PACKAGE pkg_ga_player AS

PROCEDURE perform_automatic_player_move (
	p_seat_number player_state.seat_number%TYPE
);

FUNCTION get_random_int (
	p_lower_limit INTEGER,
	p_upper_limit INTEGER
) RETURN INTEGER;

END pkg_ga_player;
