CREATE OR REPLACE TYPE t_row_evolution_trial_queue AS OBJECT (
	trial_id      VARCHAR2(100),
	tournament_id NUMBER(10, 0),
	player_count  NUMBER(10, 0),
	strategy_ids  t_strategy_id_varray
);
