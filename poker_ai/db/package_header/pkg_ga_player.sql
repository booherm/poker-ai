CREATE OR REPLACE PACKAGE pkg_ga_player AS

TYPE t_strat_chromosome_metadata IS RECORD (
	exp_operand_id_bit_length  strategy_build.l_exp_l_op_bit_string_length%TYPE,
	exp_operator_id_bit_length strategy_build.l_exp_op_bit_string_length%TYPE,
	expression_bit_length      strategy_build.l_exp_l_op_bit_string_length%TYPE,
	bool_operator_bit_length   strategy_build.bool_op_bit_string_length%TYPE,
	amount_mult_bit_length     strategy_build.l_amt_mult_bit_string_length%TYPE,
	dec_tree_unit_bit_length   strategy_build.l_exp_l_op_bit_string_length%TYPE,
	stack_depth                NUMBER(10, 0),
	dec_tree_unit_slots        NUMBER(10, 0),
	chromosome_bit_length      strategy_build.l_exp_l_op_bit_string_length%TYPE,
	expression_slot_id_count   NUMBER(10, 0)
);

TYPE t_expression_map_entries IS TABLE OF strategy_expression_map.expression_slot_id%TYPE INDEX BY BINARY_INTEGER;

v_strat_chromosome_metadata t_strat_chromosome_metadata;
v_public_variable_count     NUMBER(10, 0);

PROCEDURE perform_automatic_player_move (
	p_seat_number player_state.seat_number%TYPE
);

FUNCTION get_strategy_procedure(
	p_strategy_chromosome strategy.strategy_chromosome%TYPE
) RETURN strategy.strategy_procedure%TYPE;

FUNCTION get_expression_loader RETURN VARCHAR2;

FUNCTION get_decision_tree (
	p_decision_tree_unit_id strategy_build.decision_tree_unit_id%TYPE,
	p_max_depth             INTEGER
) RETURN VARCHAR2;

FUNCTION get_expression_value(
	p_expression_id strategy_expression_map.expression_slot_id%TYPE
) RETURN strategy_variable.value%TYPE;

FUNCTION get_sub_expression_value(
	p_expression_id  strategy_expression_map.expression_slot_id%TYPE,
	p_referenced_ids IN OUT t_expression_map_entries
) RETURN strategy_variable.value%TYPE;

FUNCTION get_move_for_dec_tree_unit(
	p_decision_type         INTEGER,
	p_decision_tree_unit_id strategy_build.decision_tree_unit_id%TYPE
) RETURN VARCHAR2;

FUNCTION get_move_amt_for_dec_tree_unit(
	p_seat_number       player_state.seat_number%TYPE,
	p_player_move       VARCHAR2,
	p_amount_multiplier NUMBER
) RETURN player_state.money%TYPE;

FUNCTION get_expression_operator_text(
	p_expression_operator_id INTEGER
) RETURN VARCHAR2;

FUNCTION get_boolean_operator_text(
	p_boolean_operator_id INTEGER
) RETURN VARCHAR2;

FUNCTION get_amount_multiplier_text(
	p_amount_multiplier_id INTEGER
) RETURN VARCHAR2;

PROCEDURE load_strategy_build_table(
	p_strategy_chromosome strategy.strategy_chromosome%TYPE
);

PROCEDURE execute_strategy(
	p_strategy_procedure strategy.strategy_procedure%TYPE,
	p_seat_number        player_state.seat_number%TYPE,
	p_can_fold           VARCHAR2,
	p_can_check          VARCHAR2,
	p_can_call           VARCHAR2,
	p_can_bet            VARCHAR2,
	p_can_raise          VARCHAR2,
	p_player_move        OUT VARCHAR2,
	p_player_move_amount OUT player_state.money%TYPE
);

FUNCTION get_decision_type(
	p_can_fold  VARCHAR2,
	p_can_check VARCHAR2,
	p_can_call  VARCHAR2,
	p_can_bet   VARCHAR2,
	p_can_raise VARCHAR2
) RETURN INTEGER;

END pkg_ga_player;
