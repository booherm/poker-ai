CREATE TABLE evolution_trial
(
	trial_id                  NUMBER(10, 0),
	generation_size           NUMBER(10, 0),
	max_generations           NUMBER(10, 0),
	crossover_rate            NUMBER(5, 4),
	crossover_point           NUMBER(10, 0),
	mutation_rate             NUMBER(5, 4),
	players_per_tournament    NUMBER(10, 0),
	tournament_play_count     NUMBER(10, 0),
	tournament_buy_in         NUMBER(10, 0),
	initial_small_blind_value NUMBER(10, 0),
	double_blinds_interval    NUMBER(10, 0),
	current_generation        NUMBER(10, 0),
	trial_complete            VARCHAR2(1)
) INMEMORY;

ALTER TABLE evolution_trial ADD
(
	CONSTRAINT et_pk_tid PRIMARY KEY (trial_id)
);
