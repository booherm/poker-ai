#include "Deck.hpp"

Deck::Deck() {
	cards.push_back({1, Deck::Suit::HEARTS, 2, false });
	cards.push_back({2, Deck::Suit::HEARTS, 3, false });
	cards.push_back({3, Deck::Suit::HEARTS, 4, false });
	cards.push_back({4, Deck::Suit::HEARTS, 5, false });
	cards.push_back({5, Deck::Suit::HEARTS, 6, false });
	cards.push_back({6, Deck::Suit::HEARTS, 7, false });
	cards.push_back({7, Deck::Suit::HEARTS, 8, false });
	cards.push_back({8, Deck::Suit::HEARTS, 9, false });
	cards.push_back({9, Deck::Suit::HEARTS, 10, false });
	cards.push_back({10, Deck::Suit::HEARTS, 11, false });
	cards.push_back({11, Deck::Suit::HEARTS, 12, false });
	cards.push_back({12, Deck::Suit::HEARTS, 13, false });
	cards.push_back({13, Deck::Suit::HEARTS, 14, false });
	cards.push_back({14, Deck::Suit::DIAMONDS, 2, false });
	cards.push_back({15, Deck::Suit::DIAMONDS, 3, false });
	cards.push_back({16, Deck::Suit::DIAMONDS, 4, false });
	cards.push_back({17, Deck::Suit::DIAMONDS, 5, false });
	cards.push_back({18, Deck::Suit::DIAMONDS, 6, false });
	cards.push_back({19, Deck::Suit::DIAMONDS, 7, false });
	cards.push_back({20, Deck::Suit::DIAMONDS, 8, false });
	cards.push_back({21, Deck::Suit::DIAMONDS, 9, false });
	cards.push_back({22, Deck::Suit::DIAMONDS, 10, false });
	cards.push_back({23, Deck::Suit::DIAMONDS, 11, false });
	cards.push_back({24, Deck::Suit::DIAMONDS, 12, false });
	cards.push_back({25, Deck::Suit::DIAMONDS, 13, false });
	cards.push_back({26, Deck::Suit::DIAMONDS, 14, false });
	cards.push_back({27, Deck::Suit::SPADES, 2, false });
	cards.push_back({28, Deck::Suit::SPADES, 3, false });
	cards.push_back({29, Deck::Suit::SPADES, 4, false });
	cards.push_back({30, Deck::Suit::SPADES, 5, false });
	cards.push_back({31, Deck::Suit::SPADES, 6, false });
	cards.push_back({32, Deck::Suit::SPADES, 7, false });
	cards.push_back({33, Deck::Suit::SPADES, 8, false });
	cards.push_back({34, Deck::Suit::SPADES, 9, false });
	cards.push_back({35, Deck::Suit::SPADES, 10, false });
	cards.push_back({36, Deck::Suit::SPADES, 11, false });
	cards.push_back({37, Deck::Suit::SPADES, 12, false });
	cards.push_back({38, Deck::Suit::SPADES, 13, false });
	cards.push_back({39, Deck::Suit::SPADES, 14, false });
	cards.push_back({40, Deck::Suit::CLUBS, 2, false });
	cards.push_back({41, Deck::Suit::CLUBS, 3, false });
	cards.push_back({42, Deck::Suit::CLUBS, 4, false });
	cards.push_back({43, Deck::Suit::CLUBS, 5, false });
	cards.push_back({44, Deck::Suit::CLUBS, 6, false });
	cards.push_back({45, Deck::Suit::CLUBS, 7, false });
	cards.push_back({46, Deck::Suit::CLUBS, 8, false });
	cards.push_back({47, Deck::Suit::CLUBS, 9, false });
	cards.push_back({48, Deck::Suit::CLUBS, 10, false });
	cards.push_back({49, Deck::Suit::CLUBS, 11, false });
	cards.push_back({50, Deck::Suit::CLUBS, 12, false });
	cards.push_back({51, Deck::Suit::CLUBS, 13, false });
	cards.push_back({52, Deck::Suit::CLUBS, 14, false });

	unkownCard = {0, Deck::Suit::UNKNOWN, 0, false};
}

void Deck::initialize(Util::RandomNumberGenerator* randomNumberGenerator) {
	this->randomNumberGenerator = randomNumberGenerator;
	for (unsigned int i = 0; i < cards.size(); i++) {
		cards[i].dealt = false;
	}
}

Deck::Card Deck::getCardById(unsigned int cardId) const {
	return cards[cardId - 1];
}

bool Deck::getIsCardDealt(unsigned int cardId) const {
	if (cardId == 0)
		return false;

	return cards[cardId - 1].dealt;
}

Deck::Card Deck::drawCardById(unsigned int cardId) {
	if(cardId == 0)
		return unkownCard;

	cards[cardId - 1].dealt = true;
	return cards[cardId - 1];
}

Deck::Card Deck::drawRandomCard() {

	// debug - this could be better with a parallel array or something to hold drawn cards

	std::vector<unsigned int> undealtCards;
	for (unsigned int i = 0; i < cards.size(); i++) {
		if (!cards[i].dealt)
			undealtCards.push_back(i);
	}

	if (undealtCards.size() == 0)
		return unkownCard;

	unsigned int randomCardIndex = undealtCards[randomNumberGenerator->getRandomUnsignedInt(0, undealtCards.size() - 1)];
	cards[randomCardIndex].dealt = true;

	return cards[randomCardIndex];
}

Deck::Card Deck::getUnknownCard() const {
	return unkownCard;
}

void Deck::releaseCard(unsigned int cardId) {
	if(cardId != 0)
		cards[cardId - 1].dealt = false;
}