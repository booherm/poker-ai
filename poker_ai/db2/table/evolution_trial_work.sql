CREATE TABLE evolution_trial_work (
	trial_id            NUMBER(10, 0),
	tournament_sequence NUMBER(10, 0),
	strategy_id         NUMBER(10, 0),
	tournament_id       NUMBER(10, 0),
	assigned            VARCHAR2(1),
	played              VARCHAR2(1)
) INMEMORY;

ALTER TABLE evolution_trial_work ADD
(
	CONSTRAINT etw_pk_tidtssid PRIMARY KEY (trial_id, tournament_sequence, strategy_id)
);

CREATE BITMAP INDEX etw_i_tidts ON evolution_trial_work(trial_id, tournament_sequence);