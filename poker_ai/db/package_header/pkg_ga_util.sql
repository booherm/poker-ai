CREATE OR REPLACE PACKAGE pkg_ga_util AS

FUNCTION get_random_int (
	p_lower_limit INTEGER,
	p_upper_limit INTEGER
) RETURN INTEGER;

FUNCTION get_random_bit_string (
	p_length INTEGER
) RETURN VARCHAR2;

FUNCTION bit_string_to_unsigned_int(
	p_bit_string VARCHAR2
) RETURN INTEGER;

FUNCTION indent(
	p_level INTEGER
) RETURN VARCHAR2;

END pkg_ga_util;
