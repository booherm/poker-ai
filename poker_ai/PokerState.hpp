#ifndef POKERSTATE_HPP
#define POKERSTATE_HPP

#include "PokerEnumerations.hpp"
#include "Deck.hpp"
#include "PotController.hpp"

class PokerState {
public:
	void load(ocilib::Resultset& pokerStateRs);

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

	Deck deck;
	PotController potController;
};

#endif
