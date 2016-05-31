CREATE TABLE player
(
	player_id               NUMBER(10, 0),
	current_strategy_id     NUMBER(10, 0)
/*	tournaments_played      NUMBER(10, 0),
	average_tournament_rank NUMBER(10, 2),
	average_game_profit     NUMBER(10, 2),
	games_played            NUMBER(10, 0),
	flops_seen              NUMBER(10, 0),
	turns_seen              NUMBER(10, 0),
	rivers_seen             NUMBER(10, 0),
	pre_flop_folds          NUMBER(10, 0),
	flop_folds              NUMBER(10, 0),
	turn_folds              NUMBER(10, 0),
	river_folds             NUMBER(10, 0),
	money_played            NUMBER(38, 0),
	money_won               NUMBER(38, 0)
	*/
);

ALTER TABLE player ADD
(
	CONSTRAINT p_pk_pid PRIMARY KEY (player_id)
);

ALTER TABLE player ADD
(
	CONSTRAINT p_fk_csid FOREIGN KEY (current_strategy_id) REFERENCES strategy(strategy_id)
);

INSERT INTO player(player_id)
SELECT pai_seq_generic.NEXTVAL player_id
FROM   DUAL
CONNECT BY ROWNUM <= 50;
COMMIT;
