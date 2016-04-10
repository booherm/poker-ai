CREATE TABLE poker_ai_log
(
	log_record_number NUMBER(38, 0),
	mod_date          DATE,
	message           VARCHAR2(4000)
);

ALTER TABLE poker_ai_log ADD
(
	CONSTRAINT pail_pk_lrn PRIMARY KEY (log_record_number)
);
