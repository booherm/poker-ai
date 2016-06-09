CREATE TABLE tournament_state_log
(
	state_id               NUMBER(38, 0),
	fitness_test_id        VARCHAR2(100),
	tournament_mode        VARCHAR2(30),
	player_count           NUMBER(2, 0),
	buy_in_amount          NUMBER(10, 0),
	tournament_in_progress VARCHAR2(1),
	current_game_number    NUMBER(10, 0),
	game_in_progress       VARCHAR2(1)
);

ALTER TABLE tournament_state_log ADD (
	CONSTRAINT tsl_pk_sid PRIMARY KEY (state_id)
);
