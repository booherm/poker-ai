CREATE OR REPLACE PACKAGE BODY pkg_ga_util AS

FUNCTION get_random_int (
	p_lower_limit INTEGER,
	p_upper_limit INTEGER
) RETURN INTEGER IS
BEGIN

	RETURN ROUND(DBMS_RANDOM.VALUE(p_lower_limit - 0.5, p_upper_limit + 0.5));

END get_random_int;

FUNCTION get_random_bit_string (
	p_length INTEGER
) RETURN CLOB IS

	v_bit_string CLOB;

BEGIN

	DBMS_LOB.CREATETEMPORARY(lob_loc => v_bit_string, cache => TRUE, dur => DBMS_LOB.CALL);

	FOR v_i IN 1 .. p_length LOOP
		DBMS_LOB.WRITEAPPEND(lob_loc => v_bit_string, amount => 1, buffer => pkg_ga_util.get_random_int(p_lower_limit => 0, p_upper_limit => 1));
	END LOOP;
	
	RETURN v_bit_string;
	
END get_random_bit_string;

FUNCTION bit_string_to_unsigned_int(
	p_bit_string VARCHAR2
) RETURN INTEGER RESULT_CACHE IS

	v_result        INTEGER := 0;
	v_string_length INTEGER := LENGTH(p_bit_string) - 1;
	
BEGIN

	FOR v_i IN 0 .. v_string_length LOOP
		IF SUBSTR(p_bit_string, v_i + 1, 1) = '1' THEN
			v_result := v_result + POWER(2, v_string_length - v_i);
		END IF;
	END LOOP;
	
	RETURN v_result;
	
END bit_string_to_unsigned_int;

FUNCTION indent(
	p_level INTEGER
) RETURN VARCHAR2 RESULT_CACHE IS

	v_indention VARCHAR2(1000);
	
BEGIN

	FOR v_i IN 1 .. p_level LOOP
		v_indention := v_indention || CHR(9);
	END LOOP;
	
	RETURN v_indention;
	
END indent;

FUNCTION mutate_chromosome(
	p_chromosome    CLOB,
	p_mutation_rate NUMBER
) RETURN CLOB IS

	v_mutated CLOB;
	
BEGIN

	DBMS_LOB.CREATETEMPORARY(lob_loc => v_mutated, cache => TRUE, dur => DBMS_LOB.CALL);

	FOR v_i IN 1 .. LENGTH(p_chromosome) LOOP
		IF DBMS_RANDOM.VALUE < p_mutation_rate THEN
			IF SUBSTR(p_chromosome, v_i, 1) = '0' THEN
				DBMS_LOB.WRITEAPPEND(lob_loc => v_mutated, amount => 1, buffer => '1');
			ELSE
				DBMS_LOB.WRITEAPPEND(lob_loc => v_mutated, amount => 1, buffer => '0');
			END IF;
		ELSE
			DBMS_LOB.WRITEAPPEND(lob_loc => v_mutated, amount => 1, buffer => SUBSTR(p_chromosome, v_i, 1));
		END IF;
	END LOOP;
	
	RETURN v_mutated;
	
END mutate_chromosome;

END pkg_ga_util;
