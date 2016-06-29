-- clear strategy and trials
DELETE FROM strategy_fitness;
DELETE FROM strategy;
DELETE FROM evolution_trial_work;
DELETE FROM evolution_trial;
TRUNCATE TABLE poker_ai_log;
DECLARE
	v_purge_options DBMS_AQADM.AQ$_PURGE_OPTIONS_T;
BEGIN
	DBMS_AQADM.PURGE_QUEUE_TABLE('ev_trial_work_queue_tbl', NULL, v_purge_options);
END;
COMMIT;

BEGIN
	pkg_ga_evolver.init_evolution_trial(
		p_trial_id                  => 'TEST_TRIAL',
		p_generation_size           => 100,
		p_max_generations           => 2,
		p_crossover_rate            => 0.85,
		p_crossover_point           => NULL,
		p_mutation_rate             => NULL,
		p_players_per_tournament    => 10,
		p_tournament_play_count     => 2,
		p_tournament_buy_in         => 500,
		p_initial_small_blind_value => 5,
		p_double_blinds_interval    => 5
	);
END;
SELECT * FROM evolution_trial;
SELECT * FROM evolution_trial_work;

WITH tournaments AS (
	SELECT DISTINCT
		   tournament_id,
		   played
	FROM   evolution_trial_work
)

SELECT SUM(CASE WHEN played = 'Y' THEN 1 ELSE 0 END) tournaments_played,
	   COUNT(*) total_tournaments,
	   ROUND((SUM(CASE WHEN played = 'Y' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100), 2) percent_complete
FROM   tournaments;

SELECT * FROM ev_trial_work_queue_tbl;
SELECT * FROM strategy;
SELECT * FROM strategy_fitness;

-- step generation worker
DECLARE
	v_response VARCHAR2(200);
BEGIN
	v_response := pkg_ga_evolver.step_generation(p_trial_id => 'TEST_TRIAL');
	DBMS_OUTPUT.PUT_LINE('v_response = ' || v_response);
END;

-- step tournament worker
DECLARE
	v_response VARCHAR2(200);
BEGIN
	FOR v_i IN 1 .. 20 LOOP
		v_response := pkg_ga_evolver.step_tournament_work(p_trial_id => 'TEST_TRIAL', p_worker_id => 'TOURNAMENT_WORKER_1');
		DBMS_OUTPUT.PUT_LINE('v_response = ' || v_response);
	END LOOP;
END;


-- monitor progress
SELECT log_record_number,
	   TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
	   message
FROM   poker_ai_log
WHERE  message LIKE 'evolver:%'
ORDER BY log_record_number DESC;


-- average generation creation and test time
SELECT log_record_number,
       TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
       message
FROM   poker_ai_log
WHERE  message LIKE 'evolver: %begin%creation%'
ORDER BY log_record_number DESC;
-- ~48 min

-- average tournament play time
SELECT AVG(tournament_time_sec) FROM 
(
    SELECT log_record_number,
           TO_CHAR(mod_date, 'MM/DD/YYYY HH12:MI:SS AM') mod_date,
           ((mod_date - LAG(mod_date) OVER (ORDER BY log_record_number)) * 24 * 60 * 60) tournament_time_sec, 
           message
    FROM   poker_ai_log
    WHERE  message LIKE 'evolver:%begin play%'
       AND message NOT LIKE '%tournament group 1 tournament number 1%'
    ORDER BY log_record_number DESC
);
-- ~32 seconds


-- analyze evolution
SELECT s.generation,
	   MIN(s.strategy_id) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_strategy_id,
	   MIN(sf.fitness_score) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_fitness_score,
	   MIN(sf.average_game_profit) KEEP (DENSE_RANK FIRST ORDER BY sf.fitness_score DESC, s.strategy_id) best_avgerage_game_profit,
	   ROUND(AVG(sf.fitness_score), 2) average_fitness_score,
	   ROUND(AVG(sf.average_game_profit), 2) average_average_game_profit
FROM   strategy s,
	   strategy_fitness sf
WHERE  s.strategy_id = sf.strategy_id
GROUP BY s.generation
ORDER BY generation;
