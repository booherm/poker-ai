CREATE OR REPLACE PACKAGE pkg_ga_util AS

FUNCTION get_random_int (
	p_lower_limit INTEGER,
	p_upper_limit INTEGER
) RETURN INTEGER;

FUNCTION get_random_bit_string (
	p_length INTEGER
) RETURN CLOB;

FUNCTION bit_string_to_unsigned_int(
	p_bit_string VARCHAR2
) RETURN INTEGER RESULT_CACHE;

FUNCTION indent(
	p_level INTEGER
) RETURN VARCHAR2 RESULT_CACHE;

FUNCTION mutate_chromosome(
	p_chromosome    CLOB,
	p_mutation_rate NUMBER
) RETURN CLOB;

END pkg_ga_util;
