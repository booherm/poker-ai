CREATE TABLE strategy
(
	trial_id              NUMBER(10, 0),
	generation            NUMBER(10, 0),
	strategy_id           NUMBER(10, 0),
	strategy_chromosome_1 CLOB,
	strategy_procedure_1  CLOB,
	strategy_chromosome_2 CLOB,
	strategy_procedure_2  CLOB,
	strategy_chromosome_3 CLOB,
	strategy_procedure_3  CLOB,
	strategy_chromosome_4 CLOB,
	strategy_procedure_4  CLOB
) INMEMORY;

ALTER TABLE strategy ADD
(
	CONSTRAINT s_pk_tidgsid PRIMARY KEY (trial_id, generation, strategy_id)
);
