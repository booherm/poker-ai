CREATE GLOBAL TEMPORARY TABLE strategy_expression_map
(
	expression_slot_id  NUMBER(10, 0),
	left_operand_id     NUMBER(38, 0),
	operator_id         NUMBER(38, 0),
	right_operand_id    NUMBER(38, 0)
) ON COMMIT DELETE ROWS;

ALTER TABLE strategy_expression_map ADD (CONSTRAINT sem_pk_esid PRIMARY KEY (expression_slot_id));
