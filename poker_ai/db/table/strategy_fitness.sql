CREATE TABLE strategy_fitness
(
	strategy_id                   NUMBER(10, 0),
	fitness_test_id               VARCHAR2(100),
	fitness_score                 NUMBER(38, 10),
	tournaments_played            NUMBER(10, 0),
	average_tournament_profit     NUMBER(12, 2),
	games_played                  NUMBER(10, 0),
	main_pots_won                 NUMBER(10, 0),
	main_pots_split               NUMBER(10, 0),
	side_pots_won                 NUMBER(10, 0),
	side_pots_split               NUMBER(10, 0),
	average_game_profit           NUMBER(12, 2),
	flops_seen                    NUMBER(10, 0),
	turns_seen                    NUMBER(10, 0),
	rivers_seen                   NUMBER(10, 0),
	pre_flop_folds                NUMBER(10, 0),
	flop_folds                    NUMBER(10, 0),
	turn_folds                    NUMBER(10, 0),
	river_folds                   NUMBER(10, 0),
	total_folds                   NUMBER(10, 0),
	pre_flop_checks               NUMBER(10, 0),
	flop_checks                   NUMBER(10, 0),
	turn_checks                   NUMBER(10, 0),
	river_checks                  NUMBER(10, 0),
	total_checks                  NUMBER(10, 0),
	pre_flop_calls                NUMBER(10, 0),
	flop_calls                    NUMBER(10, 0),
	turn_calls                    NUMBER(10, 0),
	river_calls                   NUMBER(10, 0),
	total_calls                   NUMBER(10, 0),
	pre_flop_bets                 NUMBER(10, 0),
	flop_bets                     NUMBER(10, 0),
	turn_bets                     NUMBER(10, 0),
	river_bets                    NUMBER(10, 0),
	total_bets                    NUMBER(10, 0),
	pre_flop_total_bet_amount     NUMBER(10, 0),
	flop_total_bet_amount         NUMBER(10, 0),
	turn_total_bet_amount         NUMBER(10, 0),
	river_total_bet_amount        NUMBER(10, 0),
	total_bet_amount              NUMBER(10, 0),
	pre_flop_average_bet_amount   NUMBER(12, 2),
	flop_average_bet_amount       NUMBER(12, 2),
	turn_average_bet_amount       NUMBER(12, 2),
	river_average_bet_amount      NUMBER(12, 2),
	average_bet_amount            NUMBER(12, 2),
	pre_flop_raises               NUMBER(10, 0),
	flop_raises                   NUMBER(10, 0),
	turn_raises                   NUMBER(10, 0),
	river_raises                  NUMBER(10, 0),
	total_raises                  NUMBER(10, 0),
	pre_flop_total_raise_amount   NUMBER(10, 0),
	flop_total_raise_amount       NUMBER(10, 0),
	turn_total_raise_amount       NUMBER(10, 0),
	river_total_raise_amount      NUMBER(10, 0),
	total_raise_amount            NUMBER(10, 0),
	pre_flop_average_raise_amount NUMBER(12, 2),
	flop_average_raise_amount     NUMBER(12, 2),
	turn_average_raise_amount     NUMBER(12, 2),
	river_average_raise_amount    NUMBER(12, 2),
	average_raise_amount          NUMBER(12, 2),
	times_all_in                  NUMBER(10, 0),
	total_money_played            NUMBER(38, 0),
	total_money_won               NUMBER(38, 0)
);

ALTER TABLE strategy_fitness ADD
(
	CONSTRAINT sf_pk_sidftid PRIMARY KEY (strategy_id, fitness_test_id)
);

ALTER TABLE strategy_fitness ADD
(
	CONSTRAINT sf_fk_sid FOREIGN KEY (strategy_id) REFERENCES strategy(strategy_id)
);

