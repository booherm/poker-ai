CREATE TABLE evolution_trial_work (
	trial_id      NUMBER(10, 0),
	tournament_id NUMBER(10, 0),
	strategy_ids  t_strategy_id_varray,
	picked_up_by  VARCHAR2(50),
	played        VARCHAR2(1)
) INMEMORY;

ALTER TABLE evolution_trial_work ADD
(
	CONSTRAINT etw_pk_tidtssid PRIMARY KEY (trial_id, tournament_id)
);
