#ifndef DECK_HPP
#define DECK_HPP

#include <string>

class Deck {
public:
	enum Suit {
		HEARTS = 0,
		DIAMONDS = 1,
		SPADES = 2,
		CLUBS = 3
	};

	struct Card {
		unsigned int cardId;
		Suit suit;
		std::string displayValue;
		unsigned int value;
		bool dealt;
	};
};

#endif