CREATE TABLE poker_ai_log
(
	log_record_number NUMBER(38, 0),
	mod_date          DATE,
	state_id          NUMBER(38, 0),
	message           VARCHAR2(4000)
);

ALTER TABLE poker_ai_log ADD
(
	CONSTRAINT pail_pk_lrn PRIMARY KEY (log_record_number)
);

CREATE INDEX pail_i_sid ON poker_ai_log(state_id);
