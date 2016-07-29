CREATE TABLE evolution_trial_work (
	trial_id      NUMBER(10, 0),
	tournament_id NUMBER(10, 0),
	strategy_id   NUMBER(10, 0),
	played        VARCHAR2(1)
) INMEMORY;

ALTER TABLE evolution_trial_work ADD
(
	CONSTRAINT etw_pk_tidtssid PRIMARY KEY (trial_id, tournament_id, strategy_id)
);
