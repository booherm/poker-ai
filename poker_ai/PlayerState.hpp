#ifndef PLAYERSTATE_HPP
#define PLAYERSTATE_HPP

#include "PokerEnumerations.hpp"

class PlayerState {
public:

	PlayerState();
	void updateStatFold(PokerEnums::BettingRound bettingRound);
	void updateStatCheck(PokerEnums::BettingRound bettingRound);
	void updateStatCall(PokerEnums::BettingRound bettingRound);
	void updateStatBet(PokerEnums::BettingRound bettingRound, unsigned int betAmount);
	void updateStatRaise(PokerEnums::BettingRound bettingRound, unsigned int raiseAmount);

	unsigned int seatNumber;
	unsigned int playerId;
	unsigned int assumedStrategyId;
	bool handShowing;
	bool presentedBetOpportunity;
	int money;
	PokerEnums::State state;
	unsigned int gameRank;
	unsigned int tournamentRank;

	// stats
	unsigned int gamesPlayed;
	unsigned int mainPotsWon;
	unsigned int mainPotsSplit;
	unsigned int sidePotsWon;
	unsigned int sidePotsSplit;
	float averageGameProfit;
	unsigned int flopsSeen;
	unsigned int turnsSeen;
	unsigned int riversSeen;
	unsigned int preFlopFolds;
	unsigned int flopFolds;
	unsigned int turnFolds;
	unsigned int riverFolds;
	unsigned int totalFolds;
	unsigned int preFlopChecks;
	unsigned int flopChecks;
	unsigned int turnChecks;
	unsigned int riverChecks;
	unsigned int totalChecks;
	unsigned int preFlopCalls;
	unsigned int flopCalls;
	unsigned int turnCalls;
	unsigned int riverCalls;
	unsigned int totalCalls;
	unsigned int preFlopBets;
	unsigned int flopBets;
	unsigned int turnBets;
	unsigned int riverBets;
	unsigned int totalBets;
	unsigned int preFlopTotalBetAmount;
	unsigned int flopTotalBetAmount;
	unsigned int turnTotalBetAmount;
	unsigned int riverTotalBetAmount;
	unsigned int totalBetAmount;
	float preFlopAverageBetAmount;
	float flopAverageBetAmount;
	float turnAverageBetAmount;
	float riverAverageBetAmount;
	float averageBetAmount;
	unsigned int preFlopRaises;
	unsigned int flopRaises;
	unsigned int turnRaises;
	unsigned int riverRaises;
	unsigned int totalRaises;
	unsigned int preFlopTotalRaiseAmount;
	unsigned int flopTotalRaiseAmount;
	unsigned int turnTotalRaiseAmount;
	unsigned int riverTotalRaiseAmount;
	unsigned int totalRaiseAmount;
	float preFlopAverageRaiseAmount;
	float flopAverageRaiseAmount;
	float turnAverageRaiseAmount;
	float riverAverageRaiseAmount;
	float averageRaiseAmount;
	unsigned int timesAllIn;
	unsigned int totalMoneyPlayed;
	unsigned int totalMoneyWon;
};

#endif
