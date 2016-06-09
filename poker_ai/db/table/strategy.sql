CREATE TABLE strategy
(
	strategy_id         NUMBER(10, 0),
	generation          NUMBER(10, 0),
	strategy_chromosome CLOB,
	strategy_procedure  CLOB
);

ALTER TABLE strategy ADD
(
	CONSTRAINT s_pk_sid PRIMARY KEY (strategy_id)
);
