#ifndef DECK_HPP
#define DECK_HPP

#include <vector>
#include "Util.hpp"

class Deck {
public:
	enum Suit {
		UNKNOWN = 0,
		HEARTS = 1,
		DIAMONDS = 2,
		SPADES = 3,
		CLUBS = 4
	};

	struct Card {
		unsigned int cardId;
		Suit suit;
		unsigned int value;
		bool dealt;
	};

	Deck();
	void initialize(Util::RandomNumberGenerator* randomNumberGenerator);
	Card getUnknownCard() const;
	Card getCardById(unsigned int cardId) const;
	bool getIsCardDealt(unsigned int cardId) const;
	Card drawCardById(unsigned int cardId);
	Card drawRandomCard();
	void releaseCard(unsigned int cardId);

private:
	Util::RandomNumberGenerator* randomNumberGenerator;
	Card unkownCard;
	std::vector<Card> cards;
};

#endif