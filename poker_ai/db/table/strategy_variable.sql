CREATE TABLE strategy_variable(
	variable_id   NUMBER(10, 0),
	variable_name VARCHAR2(100),
	value         NUMBER
);

ALTER TABLE strategy_variable ADD (CONSTRAINT sv_pk_vid PRIMARY KEY (variable_id));
