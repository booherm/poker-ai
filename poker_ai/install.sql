DROP PACKAGE BODY pkg_poker_ai;
DROP PACKAGE pkg_poker_ai;

DROP TYPE t_tbl_hand;
DROP TYPE t_row_hand;

DROP TABLE poker_ai_log;
DROP TABLE hand_compare_test;
DROP TABLE tournament_state;
DROP TABLE game_state;
DROP TABLE player_state;
DROP TABLE pot;
DROP TABLE player;
DROP TABLE deck;
DROP SEQUENCE pai_seq_generic;
PURGE RECYCLEBIN;

@C:\projects\vs_workspace\poker_ai\poker_ai\sequences.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\deck.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\player.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\pot.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\player_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\game_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\tournament_state.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\hand_compare_test.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\log.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\t_row_hand.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\t_tbl_hand.sql;

@C:\projects\vs_workspace\poker_ai\poker_ai\pkgh_poker_ai.sql;
@C:\projects\vs_workspace\poker_ai\poker_ai\pkg_poker_ai.sql;
