#ifndef POKERCONTROLLER_HPP
#define POKERCONTROLLER_HPP

#include <string>
#include <vector>
#include "Deck.hpp"
#include "Player.hpp"
#include "PotController.hpp"

class PokerController {
public:
	enum TournamentMode {
		INTERNAL = 0,
		EXTERNAL = 1
	};

	PokerController();

private:

	// tournament attributes
	unsigned int tournamentId;
	TournamentMode tournamentMode;
	unsigned int currentStateId;
	std::string evolutionTrialId;
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
	unsigned int bettingRoundNumber;
	bool bettingRoundInProgress;
	unsigned int lastToRaiseSeatNumber;
	unsigned int minRaiseAmount;
	std::vector<Deck::Card> communityCards;

	std::vector<Player> players;
	Deck deck;
	PotController potController;




};

#endif
