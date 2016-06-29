CREATE OR REPLACE PACKAGE pkg_strategy_variable AS

TYPE t_strategy_variable_ids IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
TYPE t_strat_variable_qualifiers IS RECORD (
	seat_number player_state_log.seat_number%TYPE,
	can_fold    VARCHAR2(1),
	can_check   VARCHAR2(1),
	can_call    VARCHAR2(1),
	can_bet     VARCHAR2(1),
	can_raise   VARCHAR2(1)
);

v_strategy_variable_ids t_strategy_variable_ids;
v_variable_index        INTEGER;
v_public_variable_count INTEGER;

FUNCTION get_strategy_variable_value (
	p_poker_state          t_poker_state,
	p_strategy_variable_id INTEGER,
	p_variable_qualifiers  t_strat_variable_qualifiers
) RETURN NUMBER;

END pkg_strategy_variable;
