#include "TournamentResultCollector.hpp"

void TournamentResultCollector::initialize(DbConnectionManager* dbConnectionManager) {
	this->dbConnectionManager = dbConnectionManager;
	this->con = dbConnectionManager->getConnection();
}

void TournamentResultCollector::pushTournamentResult(
	unsigned int trialId,
	unsigned int tournamentId,
	unsigned int generation,
	unsigned int strategyId,
	const PlayerState& playerState
) {

	TournamentResult tournamentResultStruct;
	tournamentResults.push_back(tournamentResultStruct);
	
	TournamentResult* tournamentResult = &tournamentResults[tournamentResults.size() - 1];
	tournamentResult->trialId = trialId;
	tournamentResult->tournamentId = tournamentId;
	tournamentResult->generation = generation;
	tournamentResult->strategyId = strategyId;
	tournamentResult->playerState = PlayerState(playerState);

}

void TournamentResultCollector::writeToDatabase() {
	
	std::string procCall = "BEGIN pkg_poker_ai.insert_tournament_result(";
	procCall.append("p_trial_id                    => :1, ");
	procCall.append("p_generation                  => :2, ");
	procCall.append("p_strategy_id                 => :3, ");
	procCall.append("p_tournament_id               => :4, ");
	procCall.append("p_tournament_rank             => :5, ");
	procCall.append("p_games_played                => :6, ");
	procCall.append("p_main_pots_won               => :7, ");
	procCall.append("p_main_pots_split             => :8, ");
	procCall.append("p_side_pots_won               => :9, ");
	procCall.append("p_side_pots_split             => :10, ");
	procCall.append("p_average_game_profit         => :11, ");
	procCall.append("p_flops_seen                  => :12, ");
	procCall.append("p_turns_seen                  => :13, ");
	procCall.append("p_rivers_seen                 => :14, ");
	procCall.append("p_pre_flop_folds              => :15, ");
	procCall.append("p_flop_folds                  => :16, ");
	procCall.append("p_turn_folds                  => :17, ");
	procCall.append("p_river_folds                 => :18, ");
	procCall.append("p_total_folds                 => :19, ");
	procCall.append("p_pre_flop_checks             => :20, ");
	procCall.append("p_flop_checks                 => :21, ");
	procCall.append("p_turn_checks                 => :22, ");
	procCall.append("p_river_checks                => :23, ");
	procCall.append("p_total_checks                => :24, ");
	procCall.append("p_pre_flop_calls              => :25, ");
	procCall.append("p_flop_calls                  => :26, ");
	procCall.append("p_turn_calls                  => :27, ");
	procCall.append("p_river_calls                 => :28, ");
	procCall.append("p_total_calls                 => :29, ");
	procCall.append("p_pre_flop_bets               => :30, ");
	procCall.append("p_flop_bets                   => :31, ");
	procCall.append("p_turn_bets                   => :32, ");
	procCall.append("p_river_bets                  => :33, ");
	procCall.append("p_total_bets                  => :34, ");
	procCall.append("p_pre_flop_total_bet_amount   => :35, ");
	procCall.append("p_flop_total_bet_amount       => :36, ");
	procCall.append("p_turn_total_bet_amount       => :37, ");
	procCall.append("p_river_total_bet_amount      => :38, ");
	procCall.append("p_total_bet_amount            => :39, ");
	procCall.append("p_pre_flop_average_bet_amount => :40, ");
	procCall.append("p_flop_average_bet_amount     => :41, ");
	procCall.append("p_turn_average_bet_amount     => :42, ");
	procCall.append("p_river_average_bet_amount    => :43, ");
	procCall.append("p_average_bet_amount          => :44, ");
	procCall.append("p_pre_flop_raises             => :45, ");
	procCall.append("p_flop_raises                 => :46, ");
	procCall.append("p_turn_raises                 => :47, ");
	procCall.append("p_river_raises                => :48, ");
	procCall.append("p_total_raises                => :49, ");
	procCall.append("p_pre_flop_total_raise_amount => :50, ");
	procCall.append("p_flop_total_raise_amount     => :51, ");
	procCall.append("p_turn_total_raise_amount     => :52, ");
	procCall.append("p_river_total_raise_amount    => :53, ");
	procCall.append("p_total_raise_amount          => :54, ");
	procCall.append("p_pre_flop_average_raise_amt  => :55, ");
	procCall.append("p_flop_average_raise_amount   => :56, ");
	procCall.append("p_turn_average_raise_amount   => :57, ");
	procCall.append("p_river_average_raise_amount  => :58, ");
	procCall.append("p_average_raise_amount        => :59, ");
	procCall.append("p_times_all_in                => :60, ");
	procCall.append("p_total_money_played          => :61, ");
	procCall.append("p_total_money_won             => :62");
	procCall.append("); END;");
	oracle::occi::Statement* statement = con->createStatement(procCall);

	for (unsigned int i = 0; i < tournamentResults.size(); i++) {

		TournamentResult* tournamentResult = &tournamentResults[i];
		PlayerState* playerState = &tournamentResult->playerState;

		statement->setUInt(1, tournamentResult->trialId);
		statement->setUInt(2, tournamentResult->generation);
		statement->setUInt(3, tournamentResult->strategyId);
		statement->setUInt(4, tournamentResult->tournamentId);
		statement->setUInt(5, playerState->tournamentRank);
		statement->setUInt(6, playerState->gamesPlayed);
		statement->setUInt(7, playerState->mainPotsWon);
		statement->setUInt(8, playerState->mainPotsSplit);
		statement->setUInt(9, playerState->sidePotsWon);
		statement->setUInt(10, playerState->sidePotsSplit);
		if (playerState->gamesPlayed == 0)
			statement->setNull(11, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(11, playerState->averageGameProfit);
		statement->setUInt(12, playerState->flopsSeen);
		statement->setUInt(13, playerState->turnsSeen);
		statement->setUInt(14, playerState->riversSeen);
		statement->setUInt(15, playerState->preFlopFolds);
		statement->setUInt(16, playerState->flopFolds);
		statement->setUInt(17, playerState->turnFolds);
		statement->setUInt(18, playerState->riverFolds);
		statement->setUInt(19, playerState->totalFolds);
		statement->setUInt(20, playerState->preFlopChecks);
		statement->setUInt(21, playerState->flopChecks);
		statement->setUInt(22, playerState->turnChecks);
		statement->setUInt(23, playerState->riverChecks);
		statement->setUInt(24, playerState->totalChecks);
		statement->setUInt(25, playerState->preFlopCalls);
		statement->setUInt(26, playerState->flopCalls);
		statement->setUInt(27, playerState->turnCalls);
		statement->setUInt(28, playerState->riverCalls);
		statement->setUInt(29, playerState->totalCalls);
		statement->setUInt(30, playerState->preFlopBets);
		statement->setUInt(31, playerState->flopBets);
		statement->setUInt(32, playerState->turnBets);
		statement->setUInt(33, playerState->riverBets);
		statement->setUInt(34, playerState->totalBets);
		statement->setUInt(35, playerState->preFlopTotalBetAmount);
		statement->setUInt(36, playerState->flopTotalBetAmount);
		statement->setUInt(37, playerState->turnTotalBetAmount);
		statement->setUInt(38, playerState->riverTotalBetAmount);
		statement->setUInt(39, playerState->totalBetAmount);
		if (playerState->preFlopBets == 0)
			statement->setNull(40, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(40, playerState->preFlopAverageBetAmount);
		if (playerState->flopBets == 0)
			statement->setNull(41, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(41, playerState->flopAverageBetAmount);
		if (playerState->turnBets == 0)
			statement->setNull(42, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(42, playerState->turnAverageBetAmount);
		if (playerState->riverBets == 0)
			statement->setNull(43, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(43, playerState->riverAverageBetAmount);
		if (playerState->totalBets == 0)
			statement->setNull(44, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(44, playerState->averageBetAmount);
		statement->setUInt(45, playerState->preFlopRaises);
		statement->setUInt(46, playerState->flopRaises);
		statement->setUInt(47, playerState->turnRaises);
		statement->setUInt(48, playerState->riverRaises);
		statement->setUInt(49, playerState->totalRaises);
		statement->setUInt(50, playerState->preFlopTotalRaiseAmount);
		statement->setUInt(51, playerState->flopTotalRaiseAmount);
		statement->setUInt(52, playerState->turnTotalRaiseAmount);
		statement->setUInt(53, playerState->riverTotalRaiseAmount);
		statement->setUInt(54, playerState->totalRaiseAmount);
		if (playerState->preFlopRaises == 0)
			statement->setNull(55, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(55, playerState->preFlopAverageRaiseAmount);
		if (playerState->flopRaises == 0)
			statement->setNull(56, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(56, playerState->flopAverageRaiseAmount);
		if (playerState->turnRaises == 0)
			statement->setNull(57, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(57, playerState->turnAverageRaiseAmount);
		if (playerState->riverRaises == 0)
			statement->setNull(58, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(58, playerState->riverAverageRaiseAmount);
		if (playerState->totalRaises == 0)
			statement->setNull(59, oracle::occi::OCCIFLOAT);
		else
			statement->setFloat(59, playerState->averageRaiseAmount);
		statement->setUInt(60, playerState->timesAllIn);
		statement->setUInt(61, playerState->totalMoneyPlayed);
		statement->setUInt(62, playerState->totalMoneyWon);
		statement->execute();
	}

	con->terminateStatement(statement);
	con->commit();

	tournamentResults.clear();

}

TournamentResultCollector::~TournamentResultCollector() {
	dbConnectionManager->releaseConnection(con);
}
