CREATE TABLE evolution_trial_work (
	trial_id            NUMBER(10, 0),
	strategy_id         NUMBER(10, 0),
	tournament_sequence NUMBER(10, 0),
	tournament_id       NUMBER(10, 0),
	assigned            VARCHAR2(1),
	played              VARCHAR2(1)
) INMEMORY;

ALTER TABLE evolution_trial_work ADD
(
	CONSTRAINT etw_pk_tidsidts PRIMARY KEY (trial_id, strategy_id, tournament_sequence)
);
