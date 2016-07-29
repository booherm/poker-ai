#ifndef POKERSTATE_HPP
#define POKERSTATE_HPP

#include "PokerEnumerations.hpp"
#include "Deck.hpp"
#include "PotController.hpp"
#include "Util.hpp"
#include "PythonManager.hpp"
#include "StateVariableCollection.hpp"

class PokerState {
public:
	void load(oracle::occi::ResultSet* pokerStateRs);
	void clearStateVariables();
	void setPlayerCount(unsigned int playerCount);
	void setBuyInAmount(unsigned int buyInAmount);
	void setCurrentBettingRound(PokerEnums::BettingRound bettingRound);
	void setTournamentInProgress(bool tournamentInProgress);
	void setCurrentGameNumber(unsigned int gameNumber);
	void setGameInProgress(bool gameInProgress);
	void setBettingRoundInProgress(bool bettingRoundInProgress);
	void setSmallBlindSeatNumber(unsigned int smallBlindSeatNumber);
	void setBigBlindSeatNumber(unsigned int bigBlindSeatNumber);
	void setTurnSeatNumber(unsigned int turnSeatNumber);
	void setLastToRaiseSeatNumber(unsigned int lastToRaiseSeatNumber);
	void setMinRaiseAmount(unsigned int minRaiseAmount);
	void setSmallBlindValue(unsigned int smallBlindValue);
	void setBigBlindValue(unsigned int bigBlindValue);
	void clearCommunityCards();
	void pushCommunityCard(const Deck::Card& card);
	void replaceCommunityCard(unsigned int cardSlot, unsigned int cardId);

	// tournament attributes
	unsigned int currentStateId;
	unsigned int playerCount;
	unsigned int buyInAmount;
	bool tournamentInProgress;
	unsigned int currentGameNumber;
	bool gameInProgress;

	// game attributes
	unsigned int smallBlindSeatNumber;
	unsigned int bigBlindSeatNumber;
	unsigned int turnSeatNumber;
	unsigned int smallBlindValue;
	unsigned int bigBlindValue;
	PokerEnums::BettingRound currentBettingRound;
	bool bettingRoundInProgress;
	unsigned int lastToRaiseSeatNumber;
	unsigned int minRaiseAmount;
	std::vector<Deck::Card> communityCards;
	bool allowFoldWhenCanCheck = false;

	Deck deck;
	PotController potController;
	Util::RandomNumberGenerator randomNumberGenerator;
	StateVariableCollection stateVariables;
	PythonManager* pythonManager;
};

#endif
