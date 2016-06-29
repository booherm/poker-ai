CREATE OR REPLACE PACKAGE pkg_ga_evolver AS

PROCEDURE init_evolution_trial(
	p_trial_id                  evolution_trial.trial_id%TYPE,
	p_generation_size           evolution_trial.generation_size%TYPE,
	p_max_generations           evolution_trial.max_generations%TYPE,
	p_crossover_rate            evolution_trial.crossover_rate%TYPE,
	p_crossover_point           evolution_trial.crossover_point%TYPE,
	p_mutation_rate             evolution_trial.mutation_rate%TYPE,
	p_players_per_tournament    evolution_trial.players_per_tournament%TYPE,
	p_tournament_play_count     evolution_trial.tournament_play_count%TYPE,
	p_tournament_buy_in         evolution_trial.tournament_buy_in%TYPE,
	p_initial_small_blind_value evolution_trial.initial_small_blind_value%TYPE,
	p_double_blinds_interval    evolution_trial.double_blinds_interval%TYPE
);

PROCEDURE create_initial_generation(
	p_trial_id               evolution_trial.trial_id%TYPE,
	p_generation_size        evolution_trial.generation_size%TYPE,
	p_tournament_play_count  evolution_trial.tournament_play_count%TYPE,
	p_players_per_tournament evolution_trial.players_per_tournament%TYPE
);

PROCEDURE enqueue_tournaments(
	p_trial_id               evolution_trial.trial_id%TYPE,
	p_generation             evolution_trial.current_generation%TYPE,
	p_generation_size        evolution_trial.generation_size%TYPE,
	p_tournament_play_count  evolution_trial.tournament_play_count%TYPE,
	p_players_per_tournament evolution_trial.players_per_tournament%TYPE
);

FUNCTION step_generation (
	p_trial_id evolution_trial.trial_id%TYPE
) RETURN evolution_trial.current_generation%TYPE;

FUNCTION step_tournament_work (
	p_trial_id  evolution_trial.trial_id%TYPE,
	p_worker_id VARCHAR2
) RETURN INTEGER;

END pkg_ga_evolver;
