#include "PlayerState.hpp"

PlayerState::PlayerState() {
	gamesPlayed = 0;
	mainPotsWon = 0;
	mainPotsSplit = 0;
	sidePotsWon = 0;
	sidePotsSplit = 0;
	flopsSeen = 0;
	turnsSeen = 0;
	riversSeen = 0;
	preFlopFolds = 0;
	flopFolds = 0;
	turnFolds = 0;
	riverFolds = 0;
	totalFolds = 0;
	preFlopChecks = 0;
	flopChecks = 0;
	turnChecks = 0;
	riverChecks = 0;
	totalChecks = 0;
	preFlopCalls = 0;
	flopCalls = 0;
	turnCalls = 0;
	riverCalls = 0;
	totalCalls = 0;
	preFlopBets = 0;
	flopBets = 0;
	turnBets = 0;
	riverBets = 0;
	totalBets = 0;
	preFlopTotalBetAmount = 0;
	flopTotalBetAmount = 0;
	turnTotalBetAmount = 0;
	riverTotalBetAmount = 0;
	totalBetAmount = 0;
	preFlopRaises = 0;
	flopRaises = 0;
	turnRaises = 0;
	riverRaises = 0;
	totalRaises = 0;
	preFlopTotalRaiseAmount = 0;
	flopTotalRaiseAmount = 0;
	turnTotalRaiseAmount = 0;
	riverTotalRaiseAmount = 0;
	totalRaiseAmount = 0;
	timesAllIn = 0;
	totalMoneyPlayed = 0;
	totalMoneyWon = 0;
}

void PlayerState::updateStatFold(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		preFlopFolds++;
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		flopFolds++;
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		turnFolds++;
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		riverFolds++;
	totalFolds++;
}

void PlayerState::updateStatCheck(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		preFlopChecks++;
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		flopChecks++;
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		turnChecks++;
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		riverChecks++;
	totalChecks++;
}

void PlayerState::updateStatCall(PokerEnums::BettingRound bettingRound) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP)
		preFlopCalls++;
	else if (bettingRound == PokerEnums::BettingRound::FLOP)
		flopCalls++;
	else if (bettingRound == PokerEnums::BettingRound::TURN)
		turnCalls++;
	else if (bettingRound == PokerEnums::BettingRound::RIVER)
		riverCalls++;
	totalCalls++;
}

void PlayerState::updateStatBet(PokerEnums::BettingRound bettingRound, unsigned int betAmount) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP) {
		preFlopBets++;
		preFlopTotalBetAmount += betAmount;
		preFlopAverageBetAmount = (float) preFlopTotalBetAmount / preFlopBets;
	}
	else if (bettingRound == PokerEnums::BettingRound::FLOP) {
		flopBets++;
		flopTotalBetAmount += betAmount;
		flopAverageBetAmount = (float) flopTotalBetAmount / flopBets;
	}
	else if (bettingRound == PokerEnums::BettingRound::TURN) {
		turnBets++;
		turnTotalBetAmount += betAmount;
		turnAverageBetAmount = (float) turnTotalBetAmount / turnBets;
	}
	else if (bettingRound == PokerEnums::BettingRound::RIVER) {
		riverBets++;
		riverTotalBetAmount += betAmount;
		riverAverageBetAmount = (float) riverTotalBetAmount / riverBets;
	}
	totalBets++;
	totalBetAmount += betAmount;
	averageBetAmount = (float) totalBetAmount / totalBets;
}

void PlayerState::updateStatRaise(PokerEnums::BettingRound bettingRound, unsigned int raiseAmount) {
	if (bettingRound == PokerEnums::BettingRound::PRE_FLOP) {
		preFlopRaises++;
		preFlopTotalRaiseAmount += raiseAmount;
		preFlopAverageRaiseAmount = (float) preFlopTotalRaiseAmount / preFlopRaises;
	}
	else if (bettingRound == PokerEnums::BettingRound::FLOP) {
		flopRaises++;
		flopTotalRaiseAmount += raiseAmount;
		flopAverageRaiseAmount = (float) flopTotalRaiseAmount / flopRaises;
	}
	else if (bettingRound == PokerEnums::BettingRound::TURN) {
		turnRaises++;
		turnTotalRaiseAmount += raiseAmount;
		turnAverageRaiseAmount = (float) turnTotalRaiseAmount / turnRaises;
	}
	else if (bettingRound == PokerEnums::BettingRound::RIVER) {
		riverRaises++;
		riverTotalRaiseAmount += raiseAmount;
		riverAverageRaiseAmount = (float) riverTotalRaiseAmount / riverRaises;
	}
	totalRaises++;
	totalRaiseAmount += raiseAmount;
	averageRaiseAmount = (float) totalRaiseAmount / totalRaises;
}
