#include "PokerState.hpp"

void PokerState::load(oracle::occi::ResultSet* pokerStateRs) {
	
	clearStateVariables();

	// tournament attributes
	currentStateId = pokerStateRs->getUInt(1);
	setPlayerCount(pokerStateRs->getUInt(5));
	setBuyInAmount(pokerStateRs->getUInt(6));
	setTournamentInProgress(pokerStateRs->getUInt(7) == 1);
	setCurrentGameNumber(pokerStateRs->getUInt(8));
	setGameInProgress(pokerStateRs->getUInt(9) == 1);

	// game attributes
	setSmallBlindSeatNumber(pokerStateRs->getUInt(10));
	setBigBlindSeatNumber(pokerStateRs->getUInt(11));
	setTurnSeatNumber(pokerStateRs->getUInt(12));
	setSmallBlindValue(pokerStateRs->getUInt(13));
	setBigBlindValue(pokerStateRs->getUInt(14));
	setCurrentBettingRound((PokerEnums::BettingRound) pokerStateRs->getUInt(15));
	setBettingRoundInProgress(pokerStateRs->getUInt(16) == 1);
	setLastToRaiseSeatNumber(pokerStateRs->getUInt(17));
	setMinRaiseAmount(pokerStateRs->getUInt(18));
	deck.initialize(&randomNumberGenerator);

	// community cards
	clearCommunityCards();
	int communityCard1 = pokerStateRs->getUInt(19);
	if (communityCard1 != 0) {
		pushCommunityCard(deck.getCardById(communityCard1));
		pushCommunityCard(deck.getCardById(pokerStateRs->getUInt(20)));
		pushCommunityCard(deck.getCardById(pokerStateRs->getUInt(21)));
	}
	int communityCard4 = pokerStateRs->getUInt(22);
	if (communityCard4 != 0)
		pushCommunityCard(deck.getCardById(communityCard4));
	int communityCard5 = pokerStateRs->getUInt(23);
	if (communityCard5 != 0)
		pushCommunityCard(deck.getCardById(communityCard5));

}

void PokerState::clearStateVariables() {
	stateVariables.clear();
}

void PokerState::setPlayerCount(unsigned int playerCount) {
	this->playerCount = playerCount;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::PLAYER_COUNT, (float) playerCount);
}

void PokerState::setBuyInAmount(unsigned int buyInAmount) {
	this->buyInAmount = buyInAmount;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::BUY_IN_AMOUNT, (float) buyInAmount);
}

void PokerState::setCurrentBettingRound(PokerEnums::BettingRound bettingRound) {
	this->currentBettingRound = bettingRound;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::CURRENT_BETTING_ROUND, (float) bettingRound);
}

void PokerState::setTournamentInProgress(bool tournamentInProgress) {
	this->tournamentInProgress = tournamentInProgress;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::TOURNAMENT_IN_PROGRESS, tournamentInProgress ? 1.0f : 0.0f);
}

void PokerState::setCurrentGameNumber(unsigned int gameNumber) {
	this->currentGameNumber = gameNumber;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::CURRENT_GAME_NUMBER, (float) gameNumber);
}

void PokerState::setGameInProgress(bool gameInProgress) {
	this->gameInProgress = gameInProgress;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::GAME_IN_PROGRESS, gameInProgress ? 1.0f : 0.0f);
}

void PokerState::setBettingRoundInProgress(bool bettingRoundInProgress) {
	this->bettingRoundInProgress = bettingRoundInProgress;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::BETTING_ROUND_IN_PROGRESS, bettingRoundInProgress ? 1.0f : 0.0f);
}

void PokerState::setSmallBlindSeatNumber(unsigned int smallBlindSeatNumber) {
	this->smallBlindSeatNumber = smallBlindSeatNumber;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::SMALL_BLIND_SEAT_NUMBER, (float) smallBlindSeatNumber);
}

void PokerState::setBigBlindSeatNumber(unsigned int bigBlindSeatNumber) {
	this->bigBlindSeatNumber = bigBlindSeatNumber;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::BIG_BLIND_SEAT_NUMBER, (float) bigBlindSeatNumber);
}

void PokerState::setTurnSeatNumber(unsigned int turnSeatNumber) {
	this->turnSeatNumber = turnSeatNumber;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::TURN_SEAT_NUMBER, (float) turnSeatNumber);
}

void PokerState::setLastToRaiseSeatNumber(unsigned int lastToRaiseSeatNumber) {
	this->lastToRaiseSeatNumber = lastToRaiseSeatNumber;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::LAST_TO_RAISE_SEAT_NUMBER, (float) lastToRaiseSeatNumber);
}

void PokerState::setMinRaiseAmount(unsigned int minRaiseAmount) {
	this->minRaiseAmount = minRaiseAmount;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::MIN_RAISE_AMOUNT, (float) minRaiseAmount);
}

void PokerState::setSmallBlindValue(unsigned int smallBlindValue) {
	this->smallBlindValue = smallBlindValue;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::SMALL_BLIND_VALUE, (float) smallBlindValue);
}

void PokerState::setBigBlindValue(unsigned int bigBlindValue) {
	this->bigBlindValue = bigBlindValue;
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::BIG_BLIND_VALUE, (float) bigBlindValue);
}

void PokerState::clearCommunityCards() {
	communityCards.clear();
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_ID, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_SUIT, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_VALUE, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_ID, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_SUIT, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_VALUE, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_ID, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_SUIT, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_VALUE, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_ID, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_SUIT, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_VALUE, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_ID, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_SUIT, 0);
	stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_VALUE, 0);
}

void PokerState::pushCommunityCard(const Deck::Card& card) {
	communityCards.push_back(card);

	unsigned int communityCardCount = communityCards.size();
	if (communityCardCount == 1) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_ID, (float) card.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_SUIT, (float) card.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_VALUE, (float) card.value);
	}
	else if(communityCardCount == 2) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_ID, (float) card.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_SUIT, (float) card.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_VALUE, (float) card.value);
	}
	else if (communityCardCount == 3) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_ID, (float) card.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_SUIT, (float) card.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_VALUE, (float) card.value);
	}
	else if (communityCardCount == 4) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_ID, (float) card.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_SUIT, (float) card.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_VALUE, (float) card.value);
	}
	else if (communityCardCount == 5) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_ID, (float) card.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_SUIT, (float) card.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_VALUE, (float) card.value);
	}

}

void PokerState::replaceCommunityCard(unsigned int cardSlot, unsigned int cardId) {
	deck.releaseCard(communityCards[cardSlot].cardId);
	Deck::Card newCard = deck.drawCardById(cardId);
	communityCards[cardSlot] = newCard;

	if (cardSlot == 0) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_ID, (float) newCard.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_SUIT, (float) newCard.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_1_VALUE, (float) newCard.value);
	}
	else if (cardSlot == 1) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_ID, (float) newCard.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_SUIT, (float) newCard.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_2_VALUE, (float) newCard.value);
	}
	else if (cardSlot == 2) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_ID, (float) newCard.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_SUIT, (float) newCard.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_3_VALUE, (float) newCard.value);
	}
	else if (cardSlot == 3) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_ID, (float) newCard.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_SUIT, (float) newCard.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_4_VALUE, (float) newCard.value);
	}
	else if (cardSlot == 4) {
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_ID, (float) newCard.cardId);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_SUIT, (float) newCard.suit);
		stateVariables.setPokerStateVariableValue(StateVariableCollection::PokerStateVariable::COMMUNITY_CARD_5_VALUE, (float) newCard.value);
	}

}
