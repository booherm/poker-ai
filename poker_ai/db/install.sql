----- drop all
DROP TABLE evolution_trial;
DROP TABLE evolution_trial_work;
DROP TABLE master_field_value;
DROP TABLE player;
DROP TABLE player_state_log;
DROP TABLE poker_ai_log;
DROP TABLE poker_state_log;
DROP TABLE pot_contribution_log;
DROP TABLE pot_log;
--DROP TABLE preflop_odds;
DROP TABLE strategy;
DROP TABLE strategy_build;
DROP TABLE strategy_fitness;
DROP TABLE tournament_result;

DROP SEQUENCE pai_seq_generic;
DROP SEQUENCE pai_seq_sid;
DROP SEQUENCE pai_seq_stratid;
DROP SEQUENCE pai_seq_tid;

BEGIN
	DBMS_AQADM.STOP_QUEUE(queue_name => 'ev_trial_work_queue');
	DBMS_AQADM.DROP_QUEUE(queue_name => 'ev_trial_work_queue');
	DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ev_trial_work_queue_tbl'); 
END;

DROP PACKAGE BODY pkg_ga_evolver;
DROP PACKAGE BODY pkg_ga_player;
DROP PACKAGE BODY pkg_ga_util;
DROP PACKAGE BODY pkg_poker_ai;
DROP PACKAGE BODY pkg_strategy_variable;
DROP PACKAGE BODY pkg_tournament_stepper;
DROP PACKAGE pkg_ga_evolver;
DROP PACKAGE pkg_ga_player;
DROP PACKAGE pkg_ga_util;
DROP PACKAGE pkg_poker_ai;
DROP PACKAGE pkg_strategy_variable;
DROP PACKAGE pkg_tournament_stepper;

DROP TYPE t_poker_state;
DROP TYPE t_tbl_deck;
DROP TYPE t_tbl_hand;
DROP TYPE t_tbl_number;
DROP TYPE t_tbl_player_state;
DROP TYPE t_tbl_pot;
DROP TYPE t_tbl_pot_contribution;
DROP TYPE t_row_deck;
DROP TYPE t_row_evolution_trial_queue;
DROP TYPE t_row_hand;
DROP TYPE t_row_number;
DROP TYPE t_row_player_state;
DROP TYPE t_row_pot;
DROP TYPE t_row_pot_contribution;
DROP TYPE t_strategy_id_varray;

PURGE RECYCLEBIN;



----- install
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_strategy_id_varray.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_deck.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_evolution_trial_queue.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_hand.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_number.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_player_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_pot.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_row_pot_contribution.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_deck.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_hand.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_number.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_player_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_pot.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_tbl_pot_contribution.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\type\t_poker_state.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db2\sequence\sequences.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\evolution_trial.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\evolution_trial_work.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\master_field_value.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\player_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\poker_ai_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\poker_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\pot_contribution_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\pot_log.sql;
--@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\preflop_odds.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\strategy.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\strategy_build.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\strategy_fitness.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\tournament_result.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db2\queue\ev_trial_work_queue.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_strategy_variable.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_ga_evolver.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_ga_player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_ga_util.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_tournament_stepper.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_strategy_variable.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_ga_evolver.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_ga_player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_ga_util.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_tournament_stepper.sql;
