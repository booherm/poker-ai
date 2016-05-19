DROP PACKAGE BODY pkg_poker_ai;
DROP PACKAGE pkg_poker_ai;
DROP PACKAGE BODY pkg_ga_player;
DROP PACKAGE pkg_ga_player;

DROP TYPE t_tbl_hand;
DROP TYPE t_row_hand;
DROP TYPE t_tbl_number;
DROP TYPE t_row_number;

DROP TABLE poker_ai_log;
DROP TABLE game_state_log;
DROP TABLE player_state_log;
DROP TABLE pot_contribution_log;
DROP TABLE tournament_state_log;
DROP TABLE pot_log;
DROP TABLE hand_compare_test;
DROP TABLE tournament_state;
DROP TABLE game_state;
DROP TABLE player_state;
DROP TABLE pot_contribution;
DROP TABLE pot;
DROP TABLE player;
DROP TABLE preflop_odds;
DROP TABLE deck;
DROP SEQUENCE pai_seq_generic;
DROP SEQUENCE pai_seq_sid;
PURGE RECYCLEBIN;

@C:\projects\vs_workspace\poker_ai\poker_ai\db\sequence\sequences.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\deck.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\pot.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\pot_contribution.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\player_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\game_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\tournament_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\hand_compare_test.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\poker_ai_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\tournament_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\game_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\player_state_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\pot_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\pot_contribution_log.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\table\preflop_odds.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db\type\t_row_hand.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\type\t_row_number.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\type\t_tbl_hand.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\type\t_tbl_number.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\db\package_header\pkg_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\package_header\pkg_ga_player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\package_body\pkg_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\db\package_body\pkg_ga_player.sql;
