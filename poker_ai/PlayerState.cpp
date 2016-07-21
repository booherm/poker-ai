#include "PlayerState.hpp"

void PlayerState::initialize(unsigned int seatNumber, StateVariableCollection* stateVariables) {

	this->stateVariables = stateVariables;
	this->seatNumber = seatNumber;

	setGamesPlayed(0);
	setMainPotsWon(0);
	setMainPotsSplit(0);
	setSidePotsWon(0);
	setSidePotsSplit(0);
	setFlopsSeen(0);
	setTurnsSeen(0);
	setRiversSeen(0);
	setPreFlopFolds(0);
	setFlopFolds(0);
	setTurnFolds(0);
	setRiverFolds(0);
	setTotalFolds(0);
	setPreFlopChecks(0);
	setFlopChecks(0);
	setTurnChecks(0);
	setRiverChecks(0);
	setTotalChecks(0);
	setPreFlopCalls(0);
	setFlopCalls(0);
	setTurnCalls(0);
	setRiverCalls(0);
	setTotalCalls(0);
	setPreFlopBets(0);
	setFlopBets(0);
	setTurnBets(0);
	setRiverBets(0);
	setTotalBets(0);
	setPreFlopTotalBetAmount(0);
	setFlopTotalBetAmount(0);
	setTurnTotalBetAmount(0);
	setRiverTotalBetAmount(0);
	setTotalBetAmount(0);
	setPreFlopRaises(0);
	setFlopRaises(0);
	setTurnRaises(0);
	setRiverRaises(0);
	setTotalRaises(0);
	setPreFlopTotalRaiseAmount(0);
	setFlopTotalRaiseAmount(0);
	setTurnTotalRaiseAmount(0);
	setRiverTotalRaiseAmount(0);
	setTotalRaiseAmount(0);
	setTimesAllIn(0);
	setTotalMoneyPlayed(0);
	setTotalMoneyWon(0);
}

void PlayerState::setTournamentRank(unsigned int tournamentRank) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOURNAMENT_RANK, seatNumber, (float) tournamentRank);
	this->tournamentRank = tournamentRank;
}

void PlayerState::setState(PokerEnums::State state) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::STATE, seatNumber, (float) state);
	this->state = state;
}

void PlayerState::setSeatNumber(unsigned int seatNumber) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::SEAT_NUMBER, seatNumber, (float) seatNumber);
	this->seatNumber = seatNumber;
}

void PlayerState::setPlayerId(unsigned int playerId) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PLAYER_ID, seatNumber, (float) playerId);
	this->playerId = playerId;
}

void PlayerState::setAssumedStrategyId(unsigned int assumedStrategyId) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::ASSUMED_STRATEGY_ID, seatNumber, (float) assumedStrategyId);
	this->assumedStrategyId = assumedStrategyId;
}

void PlayerState::setMoney(unsigned int money) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::MONEY, seatNumber, (float) money);
	this->money = money;
}

void PlayerState::setHandShowing(bool handShowing) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::HAND_SHOWING, seatNumber, handShowing ? 1.0f : 0.0f);
	this->handShowing = handShowing;
}

void PlayerState::setPresentedBetOpportunity(bool presentedBetOpportunity) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRESENTED_BET_OPPORTUNITY, seatNumber, presentedBetOpportunity ? 1.0f : 0.0f);
	this->presentedBetOpportunity = presentedBetOpportunity;
}

void PlayerState::setGameRank(unsigned int gameRank) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::GAME_RANK, seatNumber, (float) gameRank);
	this->gameRank = gameRank;
}

void PlayerState::setEligibleToWinMoney(unsigned int eligibleToWinMoney) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::ELIGIBLE_TO_WIN_MONEY, seatNumber, (float) eligibleToWinMoney);
	this->eligibleToWinMoney = eligibleToWinMoney;
}

void PlayerState::setTotalPotContribution(unsigned int totalPotContribution) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_POT_CONTRIBUTION, seatNumber, (float) totalPotContribution);
	this->totalPotContribution = totalPotContribution;
}

void PlayerState::setTotalPotDeficit(int totalPotDeficit) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_POT_DEFICIT, seatNumber, (float) totalPotDeficit);
	this->totalPotDeficit = totalPotDeficit;
}

void PlayerState::setAverageGameProfit(float averageGameProfit) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::AVERAGE_GAME_PROFIT, seatNumber, averageGameProfit);
	this->averageGameProfit = averageGameProfit;
}

void PlayerState::setGamesPlayed(unsigned int gamesPlayed) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::GAMES_PLAYED, seatNumber, (float) gamesPlayed);
	this->gamesPlayed = gamesPlayed;
}

void PlayerState::setMainPotsWon(unsigned int mainPotsWon) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::MAIN_POTS_WON, seatNumber, (float) mainPotsWon);
	this->mainPotsWon = mainPotsWon;
}

void PlayerState::setMainPotsSplit(unsigned int mainPotsSplit) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::MAIN_POTS_SPLIT, seatNumber, (float) mainPotsSplit);
	this->mainPotsSplit = mainPotsSplit;
}

void PlayerState::setSidePotsWon(unsigned int sidePotsWon) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::SIDE_POTS_WON, seatNumber, (float) sidePotsWon);
	this->sidePotsWon = sidePotsWon;
}

void PlayerState::setSidePotsSplit(unsigned int sidePotsSplit) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::SIDE_POTS_SPLIT, seatNumber, (float) sidePotsSplit);
	this->sidePotsSplit = sidePotsSplit;
}

void PlayerState::setFlopsSeen(unsigned int flopsSeen) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOPS_SEEN, seatNumber, (float) flopsSeen);
	this->flopsSeen = flopsSeen;
}

void PlayerState::setTurnsSeen(unsigned int turnsSeen) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURNS_SEEN, seatNumber, (float) turnsSeen);
	this->turnsSeen = turnsSeen;
}

void PlayerState::setRiversSeen(unsigned int riversSeen) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVERS_SEEN, seatNumber, (float) riversSeen);
	this->riversSeen = riversSeen;
}

void PlayerState::setPreFlopFolds(unsigned int preFlopFolds) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_FOLDS, seatNumber, (float) preFlopFolds);
	this->preFlopFolds = preFlopFolds;
}

void PlayerState::setFlopFolds(unsigned int flopFolds) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_FOLDS, seatNumber, (float) flopFolds);
	this->flopFolds = flopFolds;
}

void PlayerState::setTurnFolds(unsigned int turnFolds) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_FOLDS, seatNumber, (float) turnFolds);
	this->turnFolds = turnFolds;
}

void PlayerState::setRiverFolds(unsigned int riverFolds) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_FOLDS, seatNumber, (float) riverFolds);
	this->riverFolds = riverFolds;
}

void PlayerState::setTotalFolds(unsigned int totalFolds) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_FOLDS, seatNumber, (float) totalFolds);
	this->totalFolds = totalFolds;
}

void PlayerState::setPreFlopChecks(unsigned int preFlopChecks) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_CHECKS, seatNumber, (float) preFlopChecks);
	this->preFlopChecks = preFlopChecks;
}

void PlayerState::setFlopChecks(unsigned int flopChecks) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_CHECKS, seatNumber, (float) flopChecks);
	this->flopChecks = flopChecks;
}

void PlayerState::setTurnChecks(unsigned int turnChecks) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_CHECKS, seatNumber, (float) turnChecks);
	this->turnChecks = turnChecks;
}

void PlayerState::setRiverChecks(unsigned int riverChecks) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_CHECKS, seatNumber, (float) riverChecks);
	this->riverChecks = riverChecks;
}

void PlayerState::setTotalChecks(unsigned int totalChecks)
{
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_CHECKS, seatNumber, (float) totalChecks);
	this->totalChecks = totalChecks;
}

void PlayerState::setPreFlopCalls(unsigned int preFlopCalls) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_CALLS, seatNumber, (float) preFlopCalls);
	this->preFlopCalls = preFlopCalls;
}

void PlayerState::setFlopCalls(unsigned int flopCalls) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_CALLS, seatNumber, (float) flopCalls);
	this->flopCalls = flopCalls;
}

void PlayerState::setTurnCalls(unsigned int turnCalls) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_CALLS, seatNumber, (float) turnCalls);
	this->turnCalls = turnCalls;
}

void PlayerState::setRiverCalls(unsigned int riverCalls) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_CALLS, seatNumber, (float) riverCalls);
	this->riverCalls = riverCalls;
}

void PlayerState::setTotalCalls(unsigned int totalCalls) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_CALLS, seatNumber, (float) totalCalls);
	this->totalCalls = totalCalls;
}

void PlayerState::setPreFlopBets(unsigned int preFlopBets) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_BETS, seatNumber, (float) preFlopBets);
	this->preFlopBets = preFlopBets;
}

void PlayerState::setFlopBets(unsigned int flopBets) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_BETS, seatNumber, (float) flopBets);
	this->flopBets = flopBets;
}

void PlayerState::setTurnBets(unsigned int turnBets) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_BETS, seatNumber, (float) turnBets);
	this->turnBets = turnBets;
}

void PlayerState::setRiverBets(unsigned int riverBets) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_BETS, seatNumber, (float) riverBets);
	this->riverBets = riverBets;
}

void PlayerState::setTotalBets(unsigned int totalBets) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_BETS, seatNumber, (float) totalBets);
	this->totalBets = totalBets;
}

void PlayerState::setPreFlopTotalBetAmount(unsigned int preFlopTotalBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_TOTAL_BET_AMOUNT, seatNumber, (float) preFlopTotalBetAmount);
	this->preFlopTotalBetAmount = preFlopTotalBetAmount;
}

void PlayerState::setFlopTotalBetAmount(unsigned int flopTotalBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_TOTAL_BET_AMOUNT, seatNumber, (float) flopTotalBetAmount);
	this->flopTotalBetAmount = flopTotalBetAmount;
}

void PlayerState::setTurnTotalBetAmount(unsigned int turnTotalBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_TOTAL_BET_AMOUNT, seatNumber, (float) turnTotalBetAmount);
	this->turnTotalBetAmount = turnTotalBetAmount;
}

void PlayerState::setRiverTotalBetAmount(unsigned int riverTotalBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_TOTAL_BET_AMOUNT, seatNumber, (float) riverTotalBetAmount);
	this->riverTotalBetAmount = riverTotalBetAmount;
}

void PlayerState::setTotalBetAmount(unsigned int totalBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_BET_AMOUNT, seatNumber, (float) totalBetAmount);
	this->totalBetAmount = totalBetAmount;
}

void PlayerState::setPreFlopRaises(unsigned int preFlopRaises) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_RAISES, seatNumber, (float) preFlopRaises);
	this->preFlopRaises = preFlopRaises;
}

void PlayerState::setFlopRaises(unsigned int flopRaises) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_RAISES, seatNumber, (float) flopRaises);
	this->flopRaises = flopRaises;
}

void PlayerState::setTurnRaises(unsigned int turnRaises) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_RAISES, seatNumber, (float) turnRaises);
	this->turnRaises = turnRaises;
}

void PlayerState::setRiverRaises(unsigned int riverRaises) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_RAISES, seatNumber, (float) riverRaises);
	this->riverRaises = riverRaises;
}

void PlayerState::setTotalRaises(unsigned int totalRaises) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_RAISES, seatNumber, (float) totalRaises);
	this->totalRaises = totalRaises;
}

void PlayerState::setPreFlopTotalRaiseAmount(unsigned int preFlopTotalRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_TOTAL_RAISE_AMOUNT, seatNumber, (float) preFlopTotalRaiseAmount);
	this->preFlopTotalRaiseAmount = preFlopTotalRaiseAmount;
}

void PlayerState::setFlopTotalRaiseAmount(unsigned int flopTotalRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_TOTAL_RAISE_AMOUNT, seatNumber, (float) flopTotalRaiseAmount);
	this->flopTotalRaiseAmount = flopTotalRaiseAmount;
}

void PlayerState::setTurnTotalRaiseAmount(unsigned int turnTotalRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_TOTAL_RAISE_AMOUNT, seatNumber, (float) turnTotalRaiseAmount);
	this->turnTotalRaiseAmount = turnTotalRaiseAmount;
}

void PlayerState::setRiverTotalRaiseAmount(unsigned int riverTotalRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_TOTAL_RAISE_AMOUNT, seatNumber, (float) riverTotalRaiseAmount);
	this->riverTotalRaiseAmount = riverTotalRaiseAmount;
}

void PlayerState::setTotalRaiseAmount(unsigned int totalRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_RAISE_AMOUNT, seatNumber, (float) totalRaiseAmount);
	this->totalRaiseAmount = totalRaiseAmount;
}

void PlayerState::setTimesAllIn(unsigned int timesAllIn) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TIMES_ALL_IN, seatNumber, (float) timesAllIn);
	this->timesAllIn = timesAllIn;
}

void PlayerState::setTotalMoneyPlayed(unsigned int totalMoneyPlayed) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_MONEY_PLAYED, seatNumber, (float) totalMoneyPlayed);
	this->totalMoneyPlayed = totalMoneyPlayed;
}

void PlayerState::setTotalMoneyWon(unsigned int totalMoneyWon) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TOTAL_MONEY_WON, seatNumber, (float) totalMoneyWon);
	this->totalMoneyWon = totalMoneyWon;
}

void PlayerState::setPreFlopAverageBetAmount(float preFlopAverageBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_AVERAGE_BET_AMOUNT, seatNumber, preFlopAverageBetAmount);
	this->preFlopAverageBetAmount = preFlopAverageBetAmount;
}

void PlayerState::setFlopAverageBetAmount(float flopAverageBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_AVERAGE_BET_AMOUNT, seatNumber, flopAverageBetAmount);
	this->flopAverageBetAmount = flopAverageBetAmount;
}

void PlayerState::setTurnAverageBetAmount(float turnAverageBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_AVERAGE_BET_AMOUNT, seatNumber, turnAverageBetAmount);
	this->turnAverageBetAmount = turnAverageBetAmount;
}

void PlayerState::setRiverAverageBetAmount(float riverAverageBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_AVERAGE_BET_AMOUNT, seatNumber, riverAverageBetAmount);
	this->riverAverageBetAmount = riverAverageBetAmount;
}

void PlayerState::setAverageBetAmount(float averageBetAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::AVERAGE_BET_AMOUNT, seatNumber, averageBetAmount);
	this->averageBetAmount = averageBetAmount;
}

void PlayerState::setPreFlopAverageRaiseAmount(float preFlopAverageRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::PRE_FLOP_AVERAGE_RAISE_AMOUNT, seatNumber, preFlopAverageRaiseAmount);
	this->preFlopAverageRaiseAmount = preFlopAverageRaiseAmount;
}

void PlayerState::setFlopAverageRaiseAmount(float flopAverageRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::FLOP_AVERAGE_RAISE_AMOUNT, seatNumber, flopAverageRaiseAmount);
	this->flopAverageRaiseAmount = flopAverageRaiseAmount;
}

void PlayerState::setTurnAverageRaiseAmount(float turnAverageRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::TURN_AVERAGE_RAISE_AMOUNT, seatNumber, turnAverageRaiseAmount);
	this->turnAverageRaiseAmount = turnAverageRaiseAmount;
}

void PlayerState::setRiverAverageRaiseAmount(float riverAverageRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::RIVER_AVERAGE_RAISE_AMOUNT, seatNumber, riverAverageRaiseAmount);
	this->riverAverageRaiseAmount = riverAverageRaiseAmount;
}

void PlayerState::setAverageRaiseAmount(float averageRaiseAmount) {
	stateVariables->setPublicPlayerStateVariableValue(StateVariableCollection::PublicPlayerStateVariable::AVERAGE_RAISE_AMOUNT, seatNumber, averageRaiseAmount);
	this->averageRaiseAmount = averageRaiseAmount;
}

void PlayerState::updateStatFold(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		setPreFlopFolds(preFlopFolds + 1);
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		setFlopFolds(flopFolds + 1);
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		setTurnFolds(turnFolds + 1);
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		setRiverFolds(riverFolds + 1);
	setTotalFolds(totalFolds + 1);
}

void PlayerState::updateStatCheck(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		setPreFlopChecks(preFlopChecks + 1);
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		setFlopChecks(flopChecks + 1);
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		setTurnChecks(turnChecks + 1);
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		setRiverChecks(riverChecks + 1);
	setTotalChecks(totalChecks + 1);
}

void PlayerState::updateStatCall(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		setPreFlopCalls(preFlopCalls + 1);
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		setFlopCalls(flopCalls + 1);
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		setTurnCalls(turnCalls + 1);
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		setRiverCalls(riverCalls + 1);
	setTotalCalls(totalCalls + 1);
}

void PlayerState::updateStatBet(PokerEnums::BettingRound bettingRound, unsigned int betAmount) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP) {
		setPreFlopBets(preFlopBets + 1);
		setPreFlopTotalBetAmount(preFlopTotalBetAmount + betAmount);
		setPreFlopAverageBetAmount((float) preFlopTotalBetAmount / preFlopBets);
	}
	else if (bettingRound == PokerEnums::BettingRound::FLOP) {
		setFlopBets(flopBets + 1);
		setFlopTotalBetAmount(flopTotalBetAmount + betAmount);
		setFlopAverageBetAmount((float) flopTotalBetAmount / flopBets);
	}
	else if (bettingRound == PokerEnums::BettingRound::TURN) {
		setTurnBets(turnBets + 1);
		setTurnTotalBetAmount(turnTotalBetAmount + betAmount);
		setTurnAverageBetAmount((float) turnTotalBetAmount / turnBets);
	}
	else if (bettingRound == PokerEnums::BettingRound::RIVER) {
		setRiverBets(riverBets + 1);
		setRiverTotalBetAmount(riverTotalBetAmount + betAmount);
		setRiverAverageBetAmount((float) riverTotalBetAmount / riverBets);
	}
	setTotalBets(totalBets + 1);
	setTotalBetAmount(totalBetAmount + betAmount);
	setAverageBetAmount((float) totalBetAmount / totalBets);
}

void PlayerState::updateStatRaise(PokerEnums::BettingRound bettingRound, unsigned int raiseAmount) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP) {
		setPreFlopRaises(preFlopRaises + 1);
		setPreFlopTotalRaiseAmount(preFlopTotalRaiseAmount + raiseAmount);
		setPreFlopAverageRaiseAmount((float) preFlopTotalRaiseAmount / preFlopRaises);
	}
	else if (bettingRound == PokerEnums::BettingRound::FLOP) {
		setFlopRaises(flopRaises + 1);
		setFlopTotalRaiseAmount(flopTotalRaiseAmount + raiseAmount);
		setFlopAverageRaiseAmount((float) flopTotalRaiseAmount / flopRaises);
	}
	else if (bettingRound == PokerEnums::BettingRound::TURN) {
		setTurnRaises(turnRaises + 1);
		setTurnTotalRaiseAmount(turnTotalRaiseAmount + raiseAmount);
		setTurnAverageRaiseAmount((float) turnTotalRaiseAmount / turnRaises);
	}
	else if (bettingRound == PokerEnums::BettingRound::RIVER) {
		setRiverRaises(riverRaises + 1);
		setRiverTotalRaiseAmount(riverTotalRaiseAmount + raiseAmount);
		setRiverAverageRaiseAmount((float) riverTotalRaiseAmount / riverRaises);
	}
	setTotalRaises(totalRaises + 1);
	setTotalRaiseAmount(totalRaiseAmount + raiseAmount);
	setAverageRaiseAmount((float) totalRaiseAmount / totalRaises);
}
