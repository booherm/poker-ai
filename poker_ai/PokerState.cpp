#include "PokerState.hpp"

void PokerState::load(ocilib::Resultset& pokerStateRs) {
	
	// tournament attributes
	currentStateId = pokerStateRs.Get<unsigned int>("state_id");
	playerCount = pokerStateRs.Get<unsigned int>("player_count");
	buyInAmount = pokerStateRs.Get<unsigned int>("buy_in_amount");
	tournamentInProgress = pokerStateRs.Get<unsigned int>("tournament_in_progress") == 1;
	currentGameNumber = pokerStateRs.Get<unsigned int>("current_game_number");
	gameInProgress = pokerStateRs.Get<unsigned int>("game_in_progress") == 1;

	// game attributes
	smallBlindSeatNumber = pokerStateRs.Get<unsigned int>("small_blind_seat_number");
	bigBlindSeatNumber = pokerStateRs.Get<unsigned int>("big_blind_seat_number");
	turnSeatNumber = pokerStateRs.Get<unsigned int>("turn_seat_number");
	smallBlindValue = pokerStateRs.Get<unsigned int>("small_blind_value");
	bigBlindValue = pokerStateRs.Get<unsigned int>("big_blind_value");
	currentBettingRound = (PokerEnums::BettingRound) pokerStateRs.Get<unsigned int>("betting_round_number");
	bettingRoundInProgress = pokerStateRs.Get<unsigned int>("betting_round_in_progress") == 1;
	lastToRaiseSeatNumber = pokerStateRs.Get<unsigned int>("last_to_raise_seat_number");
	minRaiseAmount = pokerStateRs.Get<unsigned int>("min_raise_amount");

	// community cards
	communityCards.clear();
	int communityCard1 = pokerStateRs.Get<int>("community_card_1");
	if (communityCard1 != 0) {
		communityCards.push_back(deck.getCardById(communityCard1));
		communityCards.push_back(deck.getCardById(pokerStateRs.Get<int>("community_card_2")));
		communityCards.push_back(deck.getCardById(pokerStateRs.Get<int>("community_card_3")));
	}
	int communityCard4 = pokerStateRs.Get<int>("community_card_4");
	if (communityCard4 != 0)
		communityCards.push_back(deck.getCardById(communityCard4));
	int communityCard5 = pokerStateRs.Get<int>("community_card_5");
	if (communityCard5 != 0)
		communityCards.push_back(deck.getCardById(communityCard5));

}
