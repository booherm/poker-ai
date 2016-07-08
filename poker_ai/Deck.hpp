#ifndef DECK_HPP
#define DECK_HPP

#include <vector>

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
	void initialize();
	Card getCardById(unsigned int cardId);
	Card getUnknownCard() const;
	Card drawCard();

private:
	Card unkownCard;
	std::vector<Card> cards;
};

#endif