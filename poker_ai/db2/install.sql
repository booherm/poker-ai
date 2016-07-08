----- drop all
DROP TABLE evolution_trial;
DROP TABLE player_state_log;
DROP TABLE poker_ai_log;
DROP TABLE poker_state_log;
DROP TABLE pot_contribution_log;
DROP TABLE pot_log;
DROP TABLE strategy_fitness;
DROP TABLE tournament_result;
DROP SEQUENCE pai_seq_generic;
DROP SEQUENCE pai_seq_sid;
DROP PACKAGE BODY pkg_poker_ai;
DROP PACKAGE pkg_poker_ai;
PURGE RECYCLEBIN;

----- install
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\sequence\sequences.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\evolution_trial.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\player_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\poker_ai_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\poker_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\pot_contribution_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\pot_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\strategy_fitness.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\table\tournament_result.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_header\pkg_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db2\package_body\pkg_poker_ai.sql;
