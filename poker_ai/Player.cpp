#include "Player.hpp"
#include <algorithm>
#include <map>
#include <unordered_map>
#include "Util.hpp"

static const unsigned int possibleHandCombinations[21][5]  = {
	{1, 2, 3, 4, 5},
	{1, 2, 3, 4, 6},
	{1, 2, 3, 4, 7},
	{1, 2, 3, 5, 6},
	{1, 2, 3, 5, 7},
	{1, 2, 3, 6, 7},
	{1, 2, 4, 5, 6},
	{1, 2, 4, 5, 7},
	{1, 2, 4, 6, 7},
	{1, 2, 5, 6, 7},
	{1, 3, 4, 5, 6},
	{1, 3, 4, 5, 7},
	{1, 3, 4, 6, 7},
	{1, 3, 5, 6, 7},
	{1, 4, 5, 6, 7},
	{2, 3, 4, 5, 6},
	{2, 3, 4, 5, 7},
	{2, 3, 4, 6, 7},
	{2, 3, 5, 6, 7},
	{2, 4, 5, 6, 7},
	{3, 4, 5, 6, 7}
};

void Player::initialize(
	oracle::occi::Connection* con,
	Logger* logger,
	PokerState* pokerState,
	std::vector<PlayerState>* playerStates,
	unsigned int seatNumber,
	Strategy* strategy,
	unsigned int playerId,
	unsigned int buyInAmount
) {

	this->con = con;
	this->logger = logger;
	this->pokerState = pokerState;
	this->playerStates = playerStates;

	thisPlayerState = &(playerStates->at(seatNumber - 1));
	thisPlayerState->initialize(seatNumber, &pokerState->stateVariables);
	thisPlayerState->setState(PokerEnums::State::NO_MOVE);
	thisPlayerState->setPlayerId(playerId);
	thisPlayerState->setAssumedStrategyId(0);
	thisPlayerState->setMoney(buyInAmount);
	thisPlayerState->setTournamentRank(0);
	resetGameState();

	if (strategy != nullptr) {
		strategyEvaluationDataProvider.initialize(seatNumber, &pokerState->stateVariables, strategy);
	}
}

void Player::load(
	oracle::occi::Connection* con,
	Logger* logger,
	PokerState* pokerState,
	std::vector<PlayerState>* playerStates,
	Strategy* strategy,
	oracle::occi::ResultSet* playerStateRs
) {

	this->con = con;
	this->logger = logger;
	this->pokerState = pokerState;
	this->playerStates = playerStates;

	// player attributes
	unsigned int seatNumber = playerStateRs->getUInt(2);
	thisPlayerState = &(playerStates->at(seatNumber - 1));
	thisPlayerState->initialize(seatNumber, &pokerState->stateVariables);
	clearHoleCards();
	int holeCard1 = playerStateRs->getUInt(6);
	if (holeCard1 != 0)
		pushHoleCard(pokerState->deck.drawCardById(holeCard1));
	int holeCard2 = playerStateRs->getUInt(7);
	if (holeCard2 != 0)
		pushHoleCard(pokerState->deck.drawCardById(holeCard2));
	bestHand.classification = (PokerEnums::HandClassification) playerStateRs->getUInt(8);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::BEST_HAND_CLASSIFICATION, seatNumber, (float) bestHand.classification);

	// occi assertion failure in debug build with resultset getString(), read char data as clob instead
	// bestHand.comparator = playerStateRs->getString(9);
	Util::clobToString(playerStateRs->getClob(82), bestHand.comparator);

	bestHand.cards.clear();
	int bestHandCard1 = playerStateRs->getUInt(10);
	if (bestHandCard1 != 0) {
		bestHand.cards.push_back(pokerState->deck.getCardById(bestHandCard1));
		bestHand.cards.push_back(pokerState->deck.getCardById(playerStateRs->getUInt(11)));
		bestHand.cards.push_back(pokerState->deck.getCardById(playerStateRs->getUInt(12)));
		bestHand.cards.push_back(pokerState->deck.getCardById(playerStateRs->getUInt(13)));
		bestHand.cards.push_back(pokerState->deck.getCardById(playerStateRs->getUInt(14)));
		bestHandRank = playerStateRs->getUInt(15);
	}
	else
		bestHandRank = 0;

	// player state
	thisPlayerState->setPlayerId(playerStateRs->getUInt(3));
	thisPlayerState->setAssumedStrategyId(playerStateRs->getUInt(5));
	thisPlayerState->setHandShowing(playerStateRs->getUInt(16) == 1);
	thisPlayerState->setPresentedBetOpportunity(playerStateRs->getUInt(17) == 1);
	thisPlayerState->setMoney(playerStateRs->getUInt(18));
	thisPlayerState->setState((PokerEnums::State) playerStateRs->getUInt(19));
	thisPlayerState->setGameRank(playerStateRs->getUInt(20));
	thisPlayerState->setEligibleToWinMoney(playerStateRs->getUInt(22));
	thisPlayerState->setTotalPotDeficit(playerStateRs->getUInt(23));
	thisPlayerState->setTotalPotContribution(playerStateRs->getUInt(24));
	thisPlayerState->setTournamentRank(playerStateRs->getUInt(21));
	thisPlayerState->setGamesPlayed(playerStateRs->getUInt(25));
	thisPlayerState->setMainPotsWon(playerStateRs->getUInt(26));
	thisPlayerState->setMainPotsSplit(playerStateRs->getUInt(27));
	thisPlayerState->setSidePotsWon(playerStateRs->getUInt(28));
	thisPlayerState->setSidePotsSplit(playerStateRs->getUInt(29));
	thisPlayerState->setAverageGameProfit(playerStateRs->getFloat(30));
	thisPlayerState->setFlopsSeen(playerStateRs->getUInt(31));
	thisPlayerState->setTurnsSeen(playerStateRs->getUInt(32));
	thisPlayerState->setRiversSeen(playerStateRs->getUInt(33));
	thisPlayerState->setPreFlopFolds(playerStateRs->getUInt(34));
	thisPlayerState->setFlopFolds(playerStateRs->getUInt(35));
	thisPlayerState->setTurnFolds(playerStateRs->getUInt(36));
	thisPlayerState->setRiverFolds(playerStateRs->getUInt(37));
	thisPlayerState->setTotalFolds(playerStateRs->getUInt(38));
	thisPlayerState->setPreFlopChecks(playerStateRs->getUInt(39));
	thisPlayerState->setFlopChecks(playerStateRs->getUInt(40));
	thisPlayerState->setTurnChecks(playerStateRs->getUInt(41));
	thisPlayerState->setRiverChecks(playerStateRs->getUInt(42));
	thisPlayerState->setTotalChecks(playerStateRs->getUInt(43));
	thisPlayerState->setPreFlopCalls(playerStateRs->getUInt(44));
	thisPlayerState->setFlopCalls(playerStateRs->getUInt(45));
	thisPlayerState->setTurnCalls(playerStateRs->getUInt(46));
	thisPlayerState->setRiverCalls(playerStateRs->getUInt(47));
	thisPlayerState->setTotalCalls(playerStateRs->getUInt(48));
	thisPlayerState->setPreFlopBets(playerStateRs->getUInt(49));
	thisPlayerState->setFlopBets(playerStateRs->getUInt(50));
	thisPlayerState->setTurnBets(playerStateRs->getUInt(51));
	thisPlayerState->setRiverBets(playerStateRs->getUInt(52));
	thisPlayerState->setTotalBets(playerStateRs->getUInt(53));
	thisPlayerState->setPreFlopTotalBetAmount(playerStateRs->getUInt(54));
	thisPlayerState->setFlopTotalBetAmount(playerStateRs->getUInt(55));
	thisPlayerState->setTurnTotalBetAmount(playerStateRs->getUInt(56));
	thisPlayerState->setRiverTotalBetAmount(playerStateRs->getUInt(57));
	thisPlayerState->setTotalBetAmount(playerStateRs->getUInt(58));
	thisPlayerState->setPreFlopAverageBetAmount(playerStateRs->getFloat(59));
	thisPlayerState->setFlopAverageBetAmount(playerStateRs->getFloat(60));
	thisPlayerState->setTurnAverageBetAmount(playerStateRs->getFloat(61));
	thisPlayerState->setRiverAverageBetAmount(playerStateRs->getFloat(62));
	thisPlayerState->setAverageBetAmount(playerStateRs->getFloat(63));
	thisPlayerState->setPreFlopRaises(playerStateRs->getUInt(64));
	thisPlayerState->setFlopRaises(playerStateRs->getUInt(65));
	thisPlayerState->setTurnRaises(playerStateRs->getUInt(66));
	thisPlayerState->setRiverRaises(playerStateRs->getUInt(67));
	thisPlayerState->setTotalRaises(playerStateRs->getUInt(68));
	thisPlayerState->setPreFlopTotalRaiseAmount(playerStateRs->getUInt(69));
	thisPlayerState->setFlopTotalRaiseAmount(playerStateRs->getUInt(70));
	thisPlayerState->setTurnTotalRaiseAmount(playerStateRs->getUInt(71));
	thisPlayerState->setRiverTotalRaiseAmount(playerStateRs->getUInt(72));
	thisPlayerState->setTotalRaiseAmount(playerStateRs->getUInt(73));
	thisPlayerState->setPreFlopAverageRaiseAmount(playerStateRs->getFloat(74));
	thisPlayerState->setFlopAverageRaiseAmount(playerStateRs->getFloat(75));
	thisPlayerState->setTurnAverageRaiseAmount(playerStateRs->getFloat(76));
	thisPlayerState->setRiverAverageRaiseAmount(playerStateRs->getFloat(77));
	thisPlayerState->setAverageRaiseAmount(playerStateRs->getFloat(78));
	thisPlayerState->setTimesAllIn(playerStateRs->getUInt(79));
	thisPlayerState->setTotalMoneyPlayed(playerStateRs->getUInt(80));
	thisPlayerState->setTotalMoneyWon(playerStateRs->getUInt(81));

	if (strategy != nullptr) {
		strategyEvaluationDataProvider.initialize(seatNumber, &pokerState->stateVariables, strategy);
	}
}

bool Player::getIsActive() const {
	return !(thisPlayerState->state == PokerEnums::State::OUT_OF_TOURNAMENT);
}

PokerEnums::State Player::getState() const {
	return thisPlayerState->state;
}

std::string Player::getStateString() const {

	if (thisPlayerState->state == PokerEnums::State::NO_PLAYER)
		return "No Player";
	if (thisPlayerState->state == PokerEnums::State::NO_MOVE)
		return "No Move";
	if (thisPlayerState->state == PokerEnums::State::FOLDED)
		return "Folded";
	if (thisPlayerState->state == PokerEnums::State::CHECKED)
		return "Checked";
	if (thisPlayerState->state == PokerEnums::State::CALLED)
		return "Called";
	if (thisPlayerState->state == PokerEnums::State::MADE_BET)
		return "Bet";
	if (thisPlayerState->state == PokerEnums::State::RAISED)
		return "Raised";
	if (thisPlayerState->state == PokerEnums::State::OUT_OF_TOURNAMENT)
		return "Out of Tournament";
	if (thisPlayerState->state == PokerEnums::State::ALL_IN)
		return "All In";

	return "";
}

bool Player::getPresentedBetOpportunity() const {
	if (thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN)
		return thisPlayerState->presentedBetOpportunity;

	return true;
}

std::string Player::getBestHandComparator() const {
	return bestHand.comparator;
}

int Player::getMoney() const {
	return thisPlayerState->money;
}

void Player::getUiState(Json::Value& playerStateData) const {

	playerStateData["seat_number"] = thisPlayerState->seatNumber;
	if(thisPlayerState->playerId == 0)
		playerStateData["player_id"] = Json::Value::null;
	else
		playerStateData["player_id"] = thisPlayerState->playerId;
	if (holeCards.size() == 0) {
		playerStateData["hole_card_1"] = Json::Value::null;
		playerStateData["hole_card_2"] = Json::Value::null;
	}
	else {
		playerStateData["hole_card_1"] = holeCards[0].cardId;
		playerStateData["hole_card_2"] = holeCards[1].cardId;

	}
	if(bestHandRank == 0)
		playerStateData["best_hand_classification"] = Json::Value::null;
	else
		playerStateData["best_hand_classification"] = std::to_string(bestHandRank) + " - " + getHandClassificationString(bestHand.classification);

	if (bestHand.cards.size() == 0) {
		playerStateData["best_hand_card_1"] = Json::Value::null;
		playerStateData["best_hand_card_2"] = Json::Value::null;
		playerStateData["best_hand_card_3"] = Json::Value::null;
		playerStateData["best_hand_card_4"] = Json::Value::null;
		playerStateData["best_hand_card_5"] = Json::Value::null;
		playerStateData["best_hand_card_1_is_hole_card"] = Json::Value::null;
		playerStateData["best_hand_card_2_is_hole_card"] = Json::Value::null;
		playerStateData["best_hand_card_3_is_hole_card"] = Json::Value::null;
		playerStateData["best_hand_card_4_is_hole_card"] = Json::Value::null;
		playerStateData["best_hand_card_5_is_hole_card"] = Json::Value::null;
	}
	else {
		playerStateData["best_hand_card_1"] = bestHand.cards[0].cardId;
		playerStateData["best_hand_card_2"] = bestHand.cards[1].cardId;
		playerStateData["best_hand_card_3"] = bestHand.cards[2].cardId;
		playerStateData["best_hand_card_4"] = bestHand.cards[3].cardId;
		playerStateData["best_hand_card_5"] = bestHand.cards[4].cardId;
		playerStateData["best_hand_card_1_is_hole_card"] = bestHand.cards[0].cardId == holeCards[0].cardId || bestHand.cards[0].cardId == holeCards[1].cardId;
		playerStateData["best_hand_card_2_is_hole_card"] = bestHand.cards[1].cardId == holeCards[0].cardId || bestHand.cards[1].cardId == holeCards[1].cardId;
		playerStateData["best_hand_card_3_is_hole_card"] = bestHand.cards[2].cardId == holeCards[0].cardId || bestHand.cards[2].cardId == holeCards[1].cardId;
		playerStateData["best_hand_card_4_is_hole_card"] = bestHand.cards[3].cardId == holeCards[0].cardId || bestHand.cards[3].cardId == holeCards[1].cardId;
		playerStateData["best_hand_card_5_is_hole_card"] = bestHand.cards[4].cardId == holeCards[0].cardId || bestHand.cards[4].cardId == holeCards[1].cardId;

	}
	playerStateData["hand_showing"] = thisPlayerState->handShowing ? "Yes" : "No";
	playerStateData["strategy_id"] = strategyEvaluationDataProvider.getStrategyId();
	playerStateData["money"] = thisPlayerState->money;
	playerStateData["state"] = getStateString();
	if (thisPlayerState->gameRank == 0)
		playerStateData["game_rank"] = Json::Value::null;
	else
		playerStateData["game_rank"] = thisPlayerState->gameRank;
	if (thisPlayerState->tournamentRank == 0)
		playerStateData["tournament_rank"] = Json::Value::null;
	else
		playerStateData["tournament_rank"] = thisPlayerState->tournamentRank;
	playerStateData["total_pot_contribution"] = thisPlayerState->totalPotContribution;
	playerStateData["can_fold"] = getCanFold();
	playerStateData["can_check"] = getCanCheck();
	playerStateData["can_call"] = getCanCall();
	playerStateData["can_bet"] = getCanBet();
	playerStateData["can_raise"] = getCanRaise();

	StrategyEvaluationDataProvider::BetRaiseLimits betRaiseLimits = getBetRaiseLimits();
	playerStateData["min_bet_amount"] = betRaiseLimits.minBetRaiseAmount;
	playerStateData["max_bet_amount"] = betRaiseLimits.maxBetRaiseAmount;
	playerStateData["min_raise_amount"] = betRaiseLimits.minBetRaiseAmount;
	playerStateData["max_raise_amount"] = betRaiseLimits.maxBetRaiseAmount;
}

void Player::issueWinnings(unsigned int winningsAmount, bool isMainPot, bool splittingPot) {

	thisPlayerState->setMoney(thisPlayerState->money + winningsAmount);
	thisPlayerState->setTotalMoneyWon(thisPlayerState->totalMoneyWon + winningsAmount);
	if (isMainPot) {
		if (splittingPot)
			thisPlayerState->setMainPotsSplit(thisPlayerState->mainPotsSplit + 1);
		else
			thisPlayerState->setMainPotsWon(thisPlayerState->mainPotsWon + 1);
	}
	else {
		if (splittingPot)
			thisPlayerState->setSidePotsSplit(thisPlayerState->sidePotsSplit + 1);
		else
			thisPlayerState->setSidePotsWon(thisPlayerState->sidePotsWon + 1);
	}

}

void Player::setBestHandRank(unsigned int rank) {
	bestHandRank = rank;
}

void Player::setHandShowing() {
	thisPlayerState->setHandShowing(true);
}

void Player::setPresentedBetOpportunity() {
	thisPlayerState->setPresentedBetOpportunity(true);
}

void Player::setHoleCards(Deck::Card holeCard1, Deck::Card holeCard2) {
	holeCards.clear();
	pushHoleCard(holeCard1);
	pushHoleCard(holeCard2);
}

void Player::setPlayerShowdownMuck() {
	// debug - decision procedure to determine whether or not to show hand
	thisPlayerState->setHandShowing(true);
}

std::string Player::calculateBestHand() {

	// return if incomplete hand
	unsigned int communityCardCount = pokerState->communityCards.size();
	if (communityCardCount == 0 || thisPlayerState->state == PokerEnums::State::FOLDED || thisPlayerState->state == PokerEnums::State::OUT_OF_TOURNAMENT)
		return "";

	// collect possible complete hands from current hole and community cards
	std::vector<Hand> handCombinations;
	for (unsigned int i = 0; i < 21; i++) {

		Hand hand;
		for (unsigned int j = 0; j < 5; j++) {
			unsigned int cardIndex = possibleHandCombinations[i][j] - 1;
			if (cardIndex <= 4) {
				// card index refers to a community card, 0 - 4
				if (cardIndex < communityCardCount)
					hand.cards.push_back(pokerState->communityCards[cardIndex]);
			}
			else {
				// card index refers to a hole card, 5 - 6
				hand.cards.push_back(holeCards[cardIndex - 5]);
			}
		}
		if (hand.cards.size() == 5)
			handCombinations.push_back(hand);
	}

	// complete hands have been determined, calculate hand attributes
	for (unsigned int i = 0; i < handCombinations.size(); i++) {
		handCombinations[i] = calculateHandAttributes(handCombinations[i].cards);
	}

	// sort by hand comparator
	std::sort(handCombinations.begin(), handCombinations.end(), [](Hand i, Hand j) {
		return i.comparator < j.comparator;
	});

	// pull out best hand
	bestHand = handCombinations[handCombinations.size() - 1];
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::BEST_HAND_CLASSIFICATION,
		thisPlayerState->seatNumber, (float) bestHand.classification);

	return bestHand.comparator;
}

PokerEnums::State Player::performPlayerMove(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount) {
	
	if (playerMove == PokerEnums::PlayerMove::AUTO) {
		performAutomaticPlayerMove();
	}
	else {
		performExplicitPlayerMove(playerMove, playerMoveAmount);
	}

	return thisPlayerState->state;
}

void Player::processGameResults(unsigned int tournamentRank) {

	if (thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT) {

		// update average game profit
		thisPlayerState->setGamesPlayed(thisPlayerState->gamesPlayed + 1);
		thisPlayerState->setAverageGameProfit(((float) ((int) thisPlayerState->totalMoneyWon - (int) thisPlayerState->totalMoneyPlayed)) / thisPlayerState->gamesPlayed);

		// mark as out of tournament if ran out of money
		if (thisPlayerState->money == 0) {
			thisPlayerState->setTournamentRank(tournamentRank);
			thisPlayerState->setState(PokerEnums::State::OUT_OF_TOURNAMENT);
			thisPlayerState->setPresentedBetOpportunity(false);
			logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " is out of tournament");
		}
	}

}

void Player::resetGameState() {
	clearHoleCards();
	bestHand.classification = PokerEnums::HandClassification::INCOMPLETE_HAND;
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::BEST_HAND_CLASSIFICATION,
		thisPlayerState->seatNumber, (float) bestHand.classification);
	bestHand.comparator = "";
	bestHand.cards.clear();
	bestHandRank = 0;
	thisPlayerState->setHandShowing(false);
	thisPlayerState->setPresentedBetOpportunity(false);
	thisPlayerState->setGameRank(0);
	thisPlayerState->setEligibleToWinMoney(0);
	thisPlayerState->setTotalPotDeficit(0);
	thisPlayerState->setTotalPotContribution(0);

	if (thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT)
		thisPlayerState->setState(PokerEnums::State::NO_MOVE);
}

void Player::resetBettingRoundState() {
	if (thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT && thisPlayerState->state != PokerEnums::State::FOLDED) {
		if (thisPlayerState->state != PokerEnums::State::ALL_IN) {
			thisPlayerState->setState(PokerEnums::State::NO_MOVE);
			thisPlayerState->setPresentedBetOpportunity(false);
		}

		if (pokerState->currentBettingRound == PokerEnums::BettingRound::FLOP) {
			thisPlayerState->setFlopsSeen(thisPlayerState->flopsSeen + 1);
		}
		else if (pokerState->currentBettingRound == PokerEnums::BettingRound::TURN) {
			thisPlayerState->setTurnsSeen(thisPlayerState->turnsSeen + 1);
		}
		else if (pokerState->currentBettingRound == PokerEnums::BettingRound::RIVER) {
			thisPlayerState->setRiversSeen(thisPlayerState->riversSeen + 1);
		}
	}
}

void Player::insertStateLog() {

	std::string procCall = "BEGIN pkg_poker_ai.insert_player_state_log(";
	procCall.append("p_state_id                    => :1, ");
	procCall.append("p_seat_number                 => :2, ");
	procCall.append("p_player_id                   => :3, ");
	procCall.append("p_current_strategy_id         => :4, ");
	procCall.append("p_assumed_strategy_id         => :5, ");
	procCall.append("p_hole_card_1                 => :6, ");
	procCall.append("p_hole_card_2                 => :7, ");
	procCall.append("p_best_hand_classification    => :8, ");
	procCall.append("p_best_hand_comparator        => :9, ");
	procCall.append("p_best_hand_card_1            => :10, ");
	procCall.append("p_best_hand_card_2            => :11, ");
	procCall.append("p_best_hand_card_3            => :12, ");
	procCall.append("p_best_hand_card_4            => :13, ");
	procCall.append("p_best_hand_card_5            => :14, ");
	procCall.append("p_best_hand_rank              => :15, ");
	procCall.append("p_hand_showing                => :16, ");
	procCall.append("p_presented_bet_opportunity   => :17, ");
	procCall.append("p_money                       => :18, ");
	procCall.append("p_state                       => :19, ");
	procCall.append("p_game_rank                   => :20, ");
	procCall.append("p_tournament_rank             => :21, ");
	procCall.append("p_eligible_to_win_money       => :22, ");
	procCall.append("p_total_pot_deficit           => :23, ");
	procCall.append("p_total_pot_contribution      => :24, ");
	procCall.append("p_games_played                => :25, ");
	procCall.append("p_main_pots_won               => :26, ");
	procCall.append("p_main_pots_split             => :27, ");
	procCall.append("p_side_pots_won               => :28, ");
	procCall.append("p_side_pots_split             => :29, ");
	procCall.append("p_average_game_profit         => :30, ");
	procCall.append("p_flops_seen                  => :31, ");
	procCall.append("p_turns_seen                  => :32, ");
	procCall.append("p_rivers_seen                 => :33, ");
	procCall.append("p_pre_flop_folds              => :34, ");
	procCall.append("p_flop_folds                  => :35, ");
	procCall.append("p_turn_folds                  => :36, ");
	procCall.append("p_river_folds                 => :37, ");
	procCall.append("p_total_folds                 => :38, ");
	procCall.append("p_pre_flop_checks             => :39, ");
	procCall.append("p_flop_checks                 => :40, ");
	procCall.append("p_turn_checks                 => :41, ");
	procCall.append("p_river_checks                => :42, ");
	procCall.append("p_total_checks                => :43, ");
	procCall.append("p_pre_flop_calls              => :44, ");
	procCall.append("p_flop_calls                  => :45, ");
	procCall.append("p_turn_calls                  => :46, ");
	procCall.append("p_river_calls                 => :47, ");
	procCall.append("p_total_calls                 => :48, ");
	procCall.append("p_pre_flop_bets               => :49, ");
	procCall.append("p_flop_bets                   => :50, ");
	procCall.append("p_turn_bets                   => :51, ");
	procCall.append("p_river_bets                  => :52, ");
	procCall.append("p_total_bets                  => :53, ");
	procCall.append("p_pre_flop_total_bet_amount   => :54, ");
	procCall.append("p_flop_total_bet_amount       => :55, ");
	procCall.append("p_turn_total_bet_amount       => :56, ");
	procCall.append("p_river_total_bet_amount      => :57, ");
	procCall.append("p_total_bet_amount            => :58, ");
	procCall.append("p_pre_flop_average_bet_amount => :59, ");
	procCall.append("p_flop_average_bet_amount     => :60, ");
	procCall.append("p_turn_average_bet_amount     => :61, ");
	procCall.append("p_river_average_bet_amount    => :62, ");
	procCall.append("p_average_bet_amount          => :63, ");
	procCall.append("p_pre_flop_raises             => :64, ");
	procCall.append("p_flop_raises                 => :65, ");
	procCall.append("p_turn_raises                 => :66, ");
	procCall.append("p_river_raises                => :67, ");
	procCall.append("p_total_raises                => :68, ");
	procCall.append("p_pre_flop_total_raise_amount => :69, ");
	procCall.append("p_flop_total_raise_amount     => :70, ");
	procCall.append("p_turn_total_raise_amount     => :71, ");
	procCall.append("p_river_total_raise_amount    => :72, ");
	procCall.append("p_total_raise_amount          => :73, ");
	procCall.append("p_pre_flop_average_raise_amt  => :74, ");
	procCall.append("p_flop_average_raise_amount   => :75, ");
	procCall.append("p_turn_average_raise_amount   => :76, ");
	procCall.append("p_river_average_raise_amount  => :77, ");
	procCall.append("p_average_raise_amount        => :78, ");
	procCall.append("p_times_all_in                => :79, ");
	procCall.append("p_total_money_played          => :80, ");
	procCall.append("p_total_money_won             => :81");
	procCall.append("); END;");
	oracle::occi::Statement* statement = con->createStatement(procCall);

	statement->setUInt(1, pokerState->currentStateId);
	statement->setUInt(2, thisPlayerState->seatNumber);
	if (thisPlayerState->playerId == 0)
		statement->setNull(3, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(3, thisPlayerState->playerId);
	unsigned int currentStrategyId = strategyEvaluationDataProvider.getStrategyId();
	if (currentStrategyId == 0)
		statement->setNull(4, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(4, currentStrategyId);
	if (thisPlayerState->assumedStrategyId == 0)
		statement->setNull(5, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(5, thisPlayerState->assumedStrategyId);
	if (holeCards.size() == 0) {
		statement->setNull(6, oracle::occi::OCCIUNSIGNED_INT);
		statement->setNull(7, oracle::occi::OCCIUNSIGNED_INT);
	}
	else {
		statement->setUInt(6, holeCards[0].cardId);
		statement->setUInt(7, holeCards[1].cardId);
	}
	if (bestHand.classification == PokerEnums::HandClassification::INCOMPLETE_HAND)
		statement->setNull(8, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(8, bestHand.classification);
	statement->setString(9, bestHand.comparator);
	if (bestHand.classification == PokerEnums::HandClassification::INCOMPLETE_HAND) {
		statement->setNull(10, oracle::occi::OCCIUNSIGNED_INT);
		statement->setNull(11, oracle::occi::OCCIUNSIGNED_INT);
		statement->setNull(12, oracle::occi::OCCIUNSIGNED_INT);
		statement->setNull(13, oracle::occi::OCCIUNSIGNED_INT);
		statement->setNull(14, oracle::occi::OCCIUNSIGNED_INT);
	}
	else {
		statement->setUInt(10, bestHand.cards[0].cardId);
		statement->setUInt(11, bestHand.cards[1].cardId);
		statement->setUInt(12, bestHand.cards[2].cardId);
		statement->setUInt(13, bestHand.cards[3].cardId);
		statement->setUInt(14, bestHand.cards[4].cardId);
	}
	if (bestHandRank == 0)
		statement->setNull(15, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(15, bestHandRank);
	statement->setUInt(16, thisPlayerState->handShowing ? 1 : 0);
	statement->setUInt(17, thisPlayerState->presentedBetOpportunity ? 1 : 0);
	statement->setUInt(18, thisPlayerState->money);
	statement->setUInt(19, thisPlayerState->state);
	if (thisPlayerState->gameRank == 0)
		statement->setNull(20, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(20, thisPlayerState->gameRank);
	if (thisPlayerState->tournamentRank == 0)
		statement->setNull(21, oracle::occi::OCCIUNSIGNED_INT);
	else
		statement->setUInt(21, thisPlayerState->tournamentRank);
	statement->setUInt(22, thisPlayerState->eligibleToWinMoney);
	statement->setUInt(23, thisPlayerState->totalPotDeficit);
	statement->setUInt(24, thisPlayerState->totalPotContribution);
	statement->setUInt(25, thisPlayerState->gamesPlayed);
	statement->setUInt(26, thisPlayerState->mainPotsWon);
	statement->setUInt(27, thisPlayerState->mainPotsSplit);
	statement->setUInt(28, thisPlayerState->sidePotsWon);
	statement->setUInt(29, thisPlayerState->sidePotsSplit);
	if (thisPlayerState->gamesPlayed == 0)
		statement->setNull(30, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(30, thisPlayerState->averageGameProfit);
	statement->setUInt(31, thisPlayerState->flopsSeen);
	statement->setUInt(32, thisPlayerState->turnsSeen);
	statement->setUInt(33, thisPlayerState->riversSeen);
	statement->setUInt(34, thisPlayerState->preFlopFolds);
	statement->setUInt(35, thisPlayerState->flopFolds);
	statement->setUInt(36, thisPlayerState->turnFolds);
	statement->setUInt(37, thisPlayerState->riverFolds);
	statement->setUInt(38, thisPlayerState->totalFolds);
	statement->setUInt(39, thisPlayerState->preFlopChecks);
	statement->setUInt(40, thisPlayerState->flopChecks);
	statement->setUInt(41, thisPlayerState->turnChecks);
	statement->setUInt(42, thisPlayerState->riverChecks);
	statement->setUInt(43, thisPlayerState->totalChecks);
	statement->setUInt(44, thisPlayerState->preFlopCalls);
	statement->setUInt(45, thisPlayerState->flopCalls);
	statement->setUInt(46, thisPlayerState->turnCalls);
	statement->setUInt(47, thisPlayerState->riverCalls);
	statement->setUInt(48, thisPlayerState->totalCalls);
	statement->setUInt(49, thisPlayerState->preFlopBets);
	statement->setUInt(50, thisPlayerState->flopBets);
	statement->setUInt(51, thisPlayerState->turnBets);
	statement->setUInt(52, thisPlayerState->riverBets);
	statement->setUInt(53, thisPlayerState->totalBets);
	statement->setUInt(54, thisPlayerState->preFlopTotalBetAmount);
	statement->setUInt(55, thisPlayerState->flopTotalBetAmount);
	statement->setUInt(56, thisPlayerState->turnTotalBetAmount);
	statement->setUInt(57, thisPlayerState->riverTotalBetAmount);
	statement->setUInt(58, thisPlayerState->totalBetAmount);
	if (thisPlayerState->preFlopBets == 0)
		statement->setNull(59, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(59, thisPlayerState->preFlopAverageBetAmount);
	if (thisPlayerState->flopBets == 0)
		statement->setNull(60, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(60, thisPlayerState->flopAverageBetAmount);
	if (thisPlayerState->turnBets == 0)
		statement->setNull(61, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(61, thisPlayerState->turnAverageBetAmount);
	if (thisPlayerState->riverBets == 0)
		statement->setNull(62, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(62, thisPlayerState->riverAverageBetAmount);
	if (thisPlayerState->totalBets == 0)
		statement->setNull(63, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(63, thisPlayerState->averageBetAmount);
	statement->setUInt(64, thisPlayerState->preFlopRaises);
	statement->setUInt(65, thisPlayerState->flopRaises);
	statement->setUInt(66, thisPlayerState->turnRaises);
	statement->setUInt(67, thisPlayerState->riverRaises);
	statement->setUInt(68, thisPlayerState->totalRaises);
	statement->setUInt(69, thisPlayerState->preFlopTotalRaiseAmount);
	statement->setUInt(70, thisPlayerState->flopTotalRaiseAmount);
	statement->setUInt(71, thisPlayerState->turnTotalRaiseAmount);
	statement->setUInt(72, thisPlayerState->riverTotalRaiseAmount);
	statement->setUInt(73, thisPlayerState->totalRaiseAmount);
	if (thisPlayerState->preFlopRaises == 0)
		statement->setNull(74, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(74, thisPlayerState->preFlopAverageRaiseAmount);
	if (thisPlayerState->flopRaises == 0)
		statement->setNull(75, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(75, thisPlayerState->flopAverageRaiseAmount);
	if (thisPlayerState->turnRaises == 0)
		statement->setNull(76, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(76, thisPlayerState->turnAverageRaiseAmount);
	if (thisPlayerState->riverRaises == 0)
		statement->setNull(77, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(77, thisPlayerState->riverAverageRaiseAmount);
	if (thisPlayerState->totalRaises == 0)
		statement->setNull(78, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(78, thisPlayerState->averageRaiseAmount);
	statement->setUInt(79, thisPlayerState->timesAllIn);
	statement->setUInt(80, thisPlayerState->totalMoneyPlayed);
	statement->setUInt(81, thisPlayerState->totalMoneyWon);
	statement->execute();
	con->terminateStatement(statement);

}

void Player::captureTournamentResults(unsigned int tournamentId, unsigned int evolutionTrialId) {

	unsigned int currentStrategyId = strategyEvaluationDataProvider.getStrategyId();
	if (currentStrategyId == 0)
		return;

	std::string procCall = "BEGIN pkg_poker_ai.insert_tournament_result(";
	procCall.append("p_strategy_id                 => :1, ");
	procCall.append("p_tournament_id               => :2, ");
	procCall.append("p_evolution_trial_id          => :3, ");
	procCall.append("p_tournament_rank             => :4, ");
	procCall.append("p_games_played                => :5, ");
	procCall.append("p_main_pots_won               => :6, ");
	procCall.append("p_main_pots_split             => :7, ");
	procCall.append("p_side_pots_won               => :8, ");
	procCall.append("p_side_pots_split             => :9, ");
	procCall.append("p_average_game_profit         => :10, ");
	procCall.append("p_flops_seen                  => :11, ");
	procCall.append("p_turns_seen                  => :12, ");
	procCall.append("p_rivers_seen                 => :13, ");
	procCall.append("p_pre_flop_folds              => :14, ");
	procCall.append("p_flop_folds                  => :15, ");
	procCall.append("p_turn_folds                  => :16, ");
	procCall.append("p_river_folds                 => :17, ");
	procCall.append("p_total_folds                 => :18, ");
	procCall.append("p_pre_flop_checks             => :19, ");
	procCall.append("p_flop_checks                 => :20, ");
	procCall.append("p_turn_checks                 => :21, ");
	procCall.append("p_river_checks                => :22, ");
	procCall.append("p_total_checks                => :23, ");
	procCall.append("p_pre_flop_calls              => :24, ");
	procCall.append("p_flop_calls                  => :25, ");
	procCall.append("p_turn_calls                  => :26, ");
	procCall.append("p_river_calls                 => :27, ");
	procCall.append("p_total_calls                 => :28, ");
	procCall.append("p_pre_flop_bets               => :29, ");
	procCall.append("p_flop_bets                   => :30, ");
	procCall.append("p_turn_bets                   => :31, ");
	procCall.append("p_river_bets                  => :32, ");
	procCall.append("p_total_bets                  => :33, ");
	procCall.append("p_pre_flop_total_bet_amount   => :34, ");
	procCall.append("p_flop_total_bet_amount       => :35, ");
	procCall.append("p_turn_total_bet_amount       => :36, ");
	procCall.append("p_river_total_bet_amount      => :37, ");
	procCall.append("p_total_bet_amount            => :38, ");
	procCall.append("p_pre_flop_average_bet_amount => :39, ");
	procCall.append("p_flop_average_bet_amount     => :40, ");
	procCall.append("p_turn_average_bet_amount     => :41, ");
	procCall.append("p_river_average_bet_amount    => :42, ");
	procCall.append("p_average_bet_amount          => :43, ");
	procCall.append("p_pre_flop_raises             => :44, ");
	procCall.append("p_flop_raises                 => :45, ");
	procCall.append("p_turn_raises                 => :46, ");
	procCall.append("p_river_raises                => :47, ");
	procCall.append("p_total_raises                => :48, ");
	procCall.append("p_pre_flop_total_raise_amount => :49, ");
	procCall.append("p_flop_total_raise_amount     => :50, ");
	procCall.append("p_turn_total_raise_amount     => :51, ");
	procCall.append("p_river_total_raise_amount    => :52, ");
	procCall.append("p_total_raise_amount          => :53, ");
	procCall.append("p_pre_flop_average_raise_amt  => :54, ");
	procCall.append("p_flop_average_raise_amount   => :55, ");
	procCall.append("p_turn_average_raise_amount   => :56, ");
	procCall.append("p_river_average_raise_amount  => :57, ");
	procCall.append("p_average_raise_amount        => :58, ");
	procCall.append("p_times_all_in                => :59, ");
	procCall.append("p_total_money_played          => :60, ");
	procCall.append("p_total_money_won             => :61");
	procCall.append("); END;");
	oracle::occi::Statement* statement = con->createStatement(procCall);

	statement->setUInt(1, currentStrategyId);
	statement->setUInt(2, tournamentId);
	statement->setUInt(3, evolutionTrialId);
	statement->setUInt(4, thisPlayerState->tournamentRank);
	statement->setUInt(5, thisPlayerState->gamesPlayed);
	statement->setUInt(6, thisPlayerState->mainPotsWon);
	statement->setUInt(7, thisPlayerState->mainPotsSplit);
	statement->setUInt(8, thisPlayerState->sidePotsWon);
	statement->setUInt(9, thisPlayerState->sidePotsSplit);
	if (thisPlayerState->gamesPlayed == 0)
		statement->setNull(10, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(10, thisPlayerState->averageGameProfit);
	statement->setUInt(11, thisPlayerState->flopsSeen);
	statement->setUInt(12, thisPlayerState->turnsSeen);
	statement->setUInt(13, thisPlayerState->riversSeen);
	statement->setUInt(14, thisPlayerState->preFlopFolds);
	statement->setUInt(15, thisPlayerState->flopFolds);
	statement->setUInt(16, thisPlayerState->turnFolds);
	statement->setUInt(17, thisPlayerState->riverFolds);
	statement->setUInt(18, thisPlayerState->totalFolds);
	statement->setUInt(19, thisPlayerState->preFlopChecks);
	statement->setUInt(20, thisPlayerState->flopChecks);
	statement->setUInt(21, thisPlayerState->turnChecks);
	statement->setUInt(22, thisPlayerState->riverChecks);
	statement->setUInt(23, thisPlayerState->totalChecks);
	statement->setUInt(24, thisPlayerState->preFlopCalls);
	statement->setUInt(25, thisPlayerState->flopCalls);
	statement->setUInt(26, thisPlayerState->turnCalls);
	statement->setUInt(27, thisPlayerState->riverCalls);
	statement->setUInt(28, thisPlayerState->totalCalls);
	statement->setUInt(29, thisPlayerState->preFlopBets);
	statement->setUInt(30, thisPlayerState->flopBets);
	statement->setUInt(31, thisPlayerState->turnBets);
	statement->setUInt(32, thisPlayerState->riverBets);
	statement->setUInt(33, thisPlayerState->totalBets);
	statement->setUInt(34, thisPlayerState->preFlopTotalBetAmount);
	statement->setUInt(35, thisPlayerState->flopTotalBetAmount);
	statement->setUInt(36, thisPlayerState->turnTotalBetAmount);
	statement->setUInt(37, thisPlayerState->riverTotalBetAmount);
	statement->setUInt(38, thisPlayerState->totalBetAmount);
	if (thisPlayerState->preFlopBets == 0)
		statement->setNull(39, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(39, thisPlayerState->preFlopAverageBetAmount);
	if (thisPlayerState->flopBets == 0)
		statement->setNull(40, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(40, thisPlayerState->flopAverageBetAmount);
	if (thisPlayerState->turnBets == 0)
		statement->setNull(41, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(41, thisPlayerState->turnAverageBetAmount);
	if (thisPlayerState->riverBets == 0)
		statement->setNull(42, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(42, thisPlayerState->riverAverageBetAmount);
	if (thisPlayerState->totalBets == 0)
		statement->setNull(43, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(43, thisPlayerState->averageBetAmount);
	statement->setUInt(44, thisPlayerState->preFlopRaises);
	statement->setUInt(45, thisPlayerState->flopRaises);
	statement->setUInt(46, thisPlayerState->turnRaises);
	statement->setUInt(47, thisPlayerState->riverRaises);
	statement->setUInt(48, thisPlayerState->totalRaises);
	statement->setUInt(49, thisPlayerState->preFlopTotalRaiseAmount);
	statement->setUInt(50, thisPlayerState->flopTotalRaiseAmount);
	statement->setUInt(51, thisPlayerState->turnTotalRaiseAmount);
	statement->setUInt(52, thisPlayerState->riverTotalRaiseAmount);
	statement->setUInt(53, thisPlayerState->totalRaiseAmount);
	if (thisPlayerState->preFlopRaises == 0)
		statement->setNull(54, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(54, thisPlayerState->preFlopAverageRaiseAmount);
	if (thisPlayerState->flopRaises == 0)
		statement->setNull(55, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(55, thisPlayerState->flopAverageRaiseAmount);
	if (thisPlayerState->turnRaises == 0)
		statement->setNull(56, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(56, thisPlayerState->turnAverageRaiseAmount);
	if (thisPlayerState->riverRaises == 0)
		statement->setNull(57, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(57, thisPlayerState->riverAverageRaiseAmount);
	if (thisPlayerState->totalRaises == 0)
		statement->setNull(58, oracle::occi::OCCIFLOAT);
	else
		statement->setFloat(58, thisPlayerState->averageRaiseAmount);
	statement->setUInt(59, thisPlayerState->timesAllIn);
	statement->setUInt(60, thisPlayerState->totalMoneyPlayed);
	statement->setUInt(61, thisPlayerState->totalMoneyWon);
	statement->execute();
	con->terminateStatement(statement);

}

inline bool Player::getCanFold() const {

	bool canFold = thisPlayerState->seatNumber == pokerState->turnSeatNumber
		&& pokerState->bettingRoundInProgress
		&& thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN;

	if (canFold && !pokerState->allowFoldWhenCanCheck && getCanCheck())
		return false;
	
	return canFold;
}

inline bool Player::getCanCheck() const {

	return thisPlayerState->seatNumber == pokerState->turnSeatNumber
		&& pokerState->bettingRoundInProgress
		&& thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN
		&& thisPlayerState->totalPotDeficit == 0;

}

inline bool Player::getCanCall() const {

	return thisPlayerState->seatNumber == pokerState->turnSeatNumber
		&& pokerState->bettingRoundInProgress
		&& thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN
		&& thisPlayerState->totalPotDeficit > 0;

}

bool Player::getCanBet() const {

	bool playerStateOk = thisPlayerState->seatNumber == pokerState->turnSeatNumber
		&& pokerState->bettingRoundInProgress
		&& thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN
		&& !pokerState->potController.getBetExists(pokerState->currentBettingRound)
		&& thisPlayerState->totalPotDeficit == 0;

	if (playerStateOk) {
		// at least one peer player must be able to respond to the bet
		for (unsigned int i = 0; i < pokerState->playerCount; i++) {
			PlayerState* ps = &playerStates->at(i);
			if (ps->seatNumber != thisPlayerState->seatNumber
				&& ps->state != PokerEnums::State::OUT_OF_TOURNAMENT
				&& ps->state != PokerEnums::State::FOLDED
				&& ps->state != PokerEnums::State::ALL_IN
				) {
				return true;
			}
		}
	}

	return false;
}

bool Player::getCanRaise() const {

	bool playerStateOk = thisPlayerState->seatNumber == pokerState->turnSeatNumber
		&& pokerState->bettingRoundInProgress
		&& thisPlayerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
		&& thisPlayerState->state != PokerEnums::State::FOLDED
		&& thisPlayerState->state != PokerEnums::State::ALL_IN
		&& pokerState->potController.getBetExists(pokerState->currentBettingRound)
		&& ((thisPlayerState->money - thisPlayerState->totalPotDeficit) > 0);

	if (playerStateOk) {
		// at least one peer player must be able to respond to the raise
		for (unsigned int i = 0; i < pokerState->playerCount; i++) {
			PlayerState* ps = &playerStates->at(i);
			if (ps->seatNumber != thisPlayerState->seatNumber
				&& ps->state != PokerEnums::State::OUT_OF_TOURNAMENT
				&& ps->state != PokerEnums::State::FOLDED
				&& ps->state != PokerEnums::State::ALL_IN
				) {
				return true;
			}
		}
	}

	return false;
}

StrategyEvaluationDataProvider::BetRaiseLimits Player::getBetRaiseLimits() const {

	StrategyEvaluationDataProvider::BetRaiseLimits betRaiseLimits;

	// determine max amount of money among peers
	int maxPeerMoney = -1;
	for (unsigned int i = 0; i < pokerState->playerCount; i++) {
		PlayerState* ps = &playerStates->at(i);
		if (ps->seatNumber != thisPlayerState->seatNumber
			&& ps->state != PokerEnums::State::OUT_OF_TOURNAMENT
			&& ps->state != PokerEnums::State::FOLDED
			) {
			int peerMoney = ps->money - ps->totalPotDeficit;
			if (peerMoney > maxPeerMoney)
				maxPeerMoney = peerMoney;
		}
	}

	// determine this players remaining money after covering pot deficits
	int remainingMoney = thisPlayerState->money - thisPlayerState->totalPotDeficit;
	if (remainingMoney < 0)
		remainingMoney = 0;

	// determine min raise amount
	if (remainingMoney >= (int) pokerState->minRaiseAmount)
		betRaiseLimits.minBetRaiseAmount = (int) pokerState->minRaiseAmount > maxPeerMoney ? maxPeerMoney : pokerState->minRaiseAmount;
	else
		betRaiseLimits.minBetRaiseAmount = remainingMoney > maxPeerMoney ? maxPeerMoney : remainingMoney;

	// determine max raise amount
	betRaiseLimits.maxBetRaiseAmount = remainingMoney < maxPeerMoney ? remainingMoney : maxPeerMoney;

	return betRaiseLimits;
}

std::string Player::getHandClassificationString(PokerEnums::HandClassification classification) const {

	if (classification == PokerEnums::HandClassification::INCOMPLETE_HAND)
		return "Incomplete Hand";
	else if (classification == PokerEnums::HandClassification::HIGH_CARD)
		return "High Card";
	else if (classification == PokerEnums::HandClassification::ONE_PAIR)
		return "One Pair";
	else if (classification == PokerEnums::HandClassification::TWO_PAIR)
		return "Two Pair";
	else if (classification == PokerEnums::HandClassification::THREE_OF_A_KIND)
		return "Three of a Kind";
	else if (classification == PokerEnums::HandClassification::STRAIGHT)
		return "Straight";
	else if (classification == PokerEnums::HandClassification::FLUSH)
		return "Flush";
	else if (classification == PokerEnums::HandClassification::FULL_HOUSE)
		return "Full House";
	else if (classification == PokerEnums::HandClassification::FOUR_OF_A_KIND)
		return "Four of a Kind";
	else if (classification == PokerEnums::HandClassification::STRAIGHT_FLUSH)
		return "Straight Flush";
	else if (classification == PokerEnums::HandClassification::ROYAL_FLUSH)
		return "Royal Flush";

	return "";
}

void Player::clearHoleCards() {
	holeCards.clear();
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_ID, thisPlayerState->seatNumber, 0);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_ID, thisPlayerState->seatNumber, 0);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_SUIT, thisPlayerState->seatNumber, 0);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_SUIT, thisPlayerState->seatNumber, 0);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_VALUE, thisPlayerState->seatNumber, 0);
	pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_VALUE, thisPlayerState->seatNumber, 0);
}

void Player::pushHoleCard(const Deck::Card& card) {
	holeCards.push_back(card);
	if (holeCards.size() == 1) {
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_ID, thisPlayerState->seatNumber, (float) card.cardId);
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_SUIT, thisPlayerState->seatNumber, (float) card.suit);
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_1_VALUE, thisPlayerState->seatNumber, (float) card.value);
	}
	else {
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_ID, thisPlayerState->seatNumber, (float) card.cardId);
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_SUIT, thisPlayerState->seatNumber, (float) card.suit);
		pokerState->stateVariables.setPrivatePlayerStateVariableValue(StateVariableCollection::PrivatePlayerStateVariable::HOLE_CARD_2_VALUE, thisPlayerState->seatNumber, (float) card.value);
	}
}

Player::Hand Player::calculateHandAttributes(std::vector<Deck::Card> cards) {

	// input cards will be analyzed and stored in seperate collection with additional attributes used for classification and sorting
	struct CardAttributes {
		Deck::Card card;
		unsigned int valueOccurences;
	};
	std::vector<CardAttributes> analyzedCards;

	// gather attributes for hand analysis
	std::unordered_map<Deck::Suit, bool> distinctSuits;
	std::unordered_map<unsigned int, bool> distinctValues;
	unsigned int highCardValue = 0;
	for (unsigned int i = 0; i < 5; i++) {

		// initialize analyzed card structure
		CardAttributes cardAttributes;
		cardAttributes.card = cards[i];
		cardAttributes.valueOccurences = 1;

		// check prior analyzed cards for additional occurences of this card's value, update if found
		for (unsigned int j = 0; j < analyzedCards.size(); j++) {
			CardAttributes* analyzedCard = &analyzedCards[j];
			if (analyzedCard->card.value == cardAttributes.card.value) {
				analyzedCard->valueOccurences++;
				cardAttributes.valueOccurences++;
			}
		}

		// capture distict suits
		distinctSuits[cardAttributes.card.suit] = true;

		// capture distinct values
		distinctValues[cardAttributes.card.value] = true;

		// capture highest card value
		if (cardAttributes.card.value > highCardValue)
			highCardValue = cardAttributes.card.value;

		// store analyzed card
		analyzedCards.push_back(cardAttributes);
	}
	unsigned int distinctSuitCount = distinctSuits.size();
	unsigned int distinctValueCount = distinctValues.size();

	// determine max number of value occurences
	unsigned int maxValueOccurences = 0;
	for (unsigned int i = 0; i < analyzedCards.size(); i++) {
		unsigned int valueOccurences = analyzedCards[i].valueOccurences;
		if (valueOccurences > maxValueOccurences)
			maxValueOccurences = valueOccurences;
	}

	// determine if hand is a straight
	std::sort(cards.begin(), cards.end(), [](Deck::Card left, Deck::Card right) {return left.value < right.value;});
	unsigned int straightCardCount;
	for (straightCardCount = 0; straightCardCount < 4; straightCardCount++) {
		if (cards[straightCardCount].value + 1 != cards[straightCardCount + 1].value) {
			break;
		}
	}
	bool isStraight = straightCardCount == 4;
	bool straightAceLow = false;
	if (!isStraight) {
		// may be a straight with ace low
		if (cards[0].value == 2 && cards[1].value == 3 && cards[2].value == 4 && cards[3].value == 5 && cards[4].value == 14) {
			isStraight = true;
			straightAceLow = true;
		}
	}

	// classify hand
	Hand hand;
	if (isStraight && distinctSuitCount == 1 && highCardValue == 14)
		hand.classification = PokerEnums::HandClassification::ROYAL_FLUSH;
	else if (isStraight && distinctSuitCount == 1)
		hand.classification = PokerEnums::HandClassification::STRAIGHT_FLUSH;
	else if (maxValueOccurences == 4)
		hand.classification = PokerEnums::HandClassification::FOUR_OF_A_KIND;
	else if (maxValueOccurences == 3 && distinctValueCount == 2)
		hand.classification = PokerEnums::HandClassification::FULL_HOUSE;
	else if (distinctSuitCount == 1)
		hand.classification = PokerEnums::HandClassification::FLUSH;
	else if (isStraight)
		hand.classification = PokerEnums::HandClassification::STRAIGHT;
	else if (maxValueOccurences == 3)
		hand.classification = PokerEnums::HandClassification::THREE_OF_A_KIND;
	else if (maxValueOccurences == 2 && distinctValueCount == 3)
		hand.classification = PokerEnums::HandClassification::TWO_PAIR;
	else if (maxValueOccurences == 2)
		hand.classification = PokerEnums::HandClassification::ONE_PAIR;
	else
		hand.classification = PokerEnums::HandClassification::HIGH_CARD;

	// sort the cards according to the hand's classification
	if (hand.classification == PokerEnums::HandClassification::HIGH_CARD
		|| hand.classification == PokerEnums::HandClassification::ONE_PAIR
		|| hand.classification == PokerEnums::HandClassification::TWO_PAIR
		|| hand.classification == PokerEnums::HandClassification::THREE_OF_A_KIND
		|| hand.classification == PokerEnums::HandClassification::FULL_HOUSE
		|| hand.classification == PokerEnums::HandClassification::FOUR_OF_A_KIND
	) {

		// sort the analyzed cards by value occurence descending, then card value descending, then suit descending
		std::sort(analyzedCards.begin(), analyzedCards.end(), [](CardAttributes left, CardAttributes right) {
			if (left.valueOccurences == right.valueOccurences) {
				if (left.card.value == right.card.value)
					return left.card.suit > right.card.suit;
				else
					return left.card.value > right.card.value;
			}
			else
				return left.valueOccurences > right.valueOccurences;
		});

	}
	else if (hand.classification == PokerEnums::HandClassification::STRAIGHT
		|| hand.classification == PokerEnums::HandClassification::STRAIGHT_FLUSH
		|| hand.classification == PokerEnums::HandClassification::ROYAL_FLUSH
	) {

		if (straightAceLow) {
			// find the ace and change the value to indicate low value
			for (unsigned int i = 0; i < analyzedCards.size(); i++) {
				Deck::Card* card = &analyzedCards[i].card;
				if (card->value == 14) {
					card->value = 1;
					break;
				}
			}
		}

		// sort the cards by value ascending
		std::sort(analyzedCards.begin(), analyzedCards.end(), [](CardAttributes left, CardAttributes right) {
			return left.card.value < right.card.value;
		});

	}
	else if (hand.classification == PokerEnums::HandClassification::FLUSH) {

		// sort the cards by value descending
		std::sort(analyzedCards.begin(), analyzedCards.end(), [](CardAttributes left, CardAttributes right) {
			return left.card.value > right.card.value;
		});

	}

	// set cards in hand in sorted order and build comparator string including card values for tie breaking
	hand.comparator = "";
	for (unsigned int i = 0; i < 5; i++) {
		hand.cards.push_back(analyzedCards[i].card);
		hand.comparator += "_" + Util::zeroPadNumber(analyzedCards[i].card.value);
	}
	hand.comparator = Util::zeroPadNumber(hand.classification) + hand.comparator;

	return hand;
}

void Player::performAutomaticPlayerMove() {

	std::vector<PokerEnums::PlayerMove> possiblePlayerMoves;
	bool calculateBetRaiseLimits = false;
	if (getCanFold())
		possiblePlayerMoves.push_back(PokerEnums::PlayerMove::FOLD);
	if (getCanCheck())
		possiblePlayerMoves.push_back(PokerEnums::PlayerMove::CHECK);
	if (getCanCall())
		possiblePlayerMoves.push_back(PokerEnums::PlayerMove::CALL);
	if (getCanBet()) {
		possiblePlayerMoves.push_back(PokerEnums::PlayerMove::BET);
		calculateBetRaiseLimits = true;
	}
	if (getCanRaise()) {
		possiblePlayerMoves.push_back(PokerEnums::PlayerMove::RAISE);
		calculateBetRaiseLimits = true;
	}

	if (possiblePlayerMoves.size() == 1) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " must check");
		performExplicitPlayerMove(PokerEnums::PlayerMove::CHECK, 0);
	}
	else if (true || strategyEvaluationDataProvider.getStrategyId() == 0) {   /// debug, eliminate python
		// perform random move
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " is performing random move");

		unsigned int randomPlayerMoveIndex = pokerState->randomNumberGenerator.getRandomUnsignedInt(0, possiblePlayerMoves.size() - 1);
		PokerEnums::PlayerMove playerMove = possiblePlayerMoves[randomPlayerMoveIndex];
		unsigned int playerMoveAmount = 0;

		if (playerMove == PokerEnums::PlayerMove::BET || playerMove == PokerEnums::PlayerMove::RAISE) {
			StrategyEvaluationDataProvider::BetRaiseLimits betRaiseLimits = getBetRaiseLimits();
			playerMoveAmount = pokerState->randomNumberGenerator.getRandomUnsignedInt(betRaiseLimits.minBetRaiseAmount, betRaiseLimits.maxBetRaiseAmount);
		}
		
		performExplicitPlayerMove(playerMove, playerMoveAmount);
	}
	else {
		// use current strategy
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " is deriving move from strategy procedure");

		StrategyEvaluationDataProvider::BetRaiseLimits betRaiseLimits;
		if (calculateBetRaiseLimits)
			betRaiseLimits = getBetRaiseLimits();

		PythonManager::PlayerMoveResult moveResult = strategyEvaluationDataProvider.executeDecisionProcedure(&possiblePlayerMoves, &betRaiseLimits);
		performExplicitPlayerMove(moveResult.move, moveResult.moveAmount);
	}

}

void Player::performExplicitPlayerMove(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount) {

	if (playerMove == PokerEnums::PlayerMove::FOLD) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " folds");
		thisPlayerState->setState(PokerEnums::State::FOLDED);
		thisPlayerState->updateStatFold(pokerState->currentBettingRound);
		pokerState->potController.issueApplicablePotRefunds(pokerState->currentStateId);
		pokerState->potController.issueDefaultPotWins(pokerState->currentStateId);
		pokerState->potController.calculateDeficitsAndPotentials();
	}
	else if (playerMove == PokerEnums::PlayerMove::CHECK) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " checks");
		if(thisPlayerState->state != PokerEnums::State::ALL_IN)
			thisPlayerState->setState(PokerEnums::State::CHECKED);
		thisPlayerState->updateStatCheck(pokerState->currentBettingRound);
	}
	else if (playerMove == PokerEnums::PlayerMove::CALL) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " calls");

		int potDeficit = thisPlayerState->totalPotDeficit;
		unsigned int contributionAmount = thisPlayerState->money < potDeficit ? thisPlayerState->money : potDeficit;
		pokerState->potController.contributeToPot(thisPlayerState->seatNumber, contributionAmount, pokerState->currentBettingRound, pokerState->currentStateId);

		if (thisPlayerState->state != PokerEnums::State::ALL_IN)
			thisPlayerState->setState(PokerEnums::State::CALLED);
		thisPlayerState->updateStatCall(pokerState->currentBettingRound);
	}
	else if (playerMove == PokerEnums::PlayerMove::BET) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " bets " + std::to_string(playerMoveAmount));
		pokerState->potController.contributeToPot(thisPlayerState->seatNumber, playerMoveAmount, pokerState->currentBettingRound, pokerState->currentStateId);
		if (thisPlayerState->state != PokerEnums::State::ALL_IN)
			thisPlayerState->setState(PokerEnums::State::MADE_BET);
		thisPlayerState->updateStatBet(pokerState->currentBettingRound, playerMoveAmount);

		pokerState->setLastToRaiseSeatNumber(thisPlayerState->seatNumber);
		pokerState->setMinRaiseAmount(playerMoveAmount < pokerState->minRaiseAmount ? (playerMoveAmount + pokerState->minRaiseAmount) : playerMoveAmount);
	}
	else if (playerMove == PokerEnums::PlayerMove::RAISE) {
		logger->log(pokerState->currentStateId, "player at seat " + std::to_string(thisPlayerState->seatNumber) + " raises " + std::to_string(playerMoveAmount));

		int potDeficit = thisPlayerState->totalPotDeficit;
		pokerState->potController.contributeToPot(thisPlayerState->seatNumber, potDeficit + playerMoveAmount, pokerState->currentBettingRound, pokerState->currentStateId);

		if (thisPlayerState->state != PokerEnums::State::ALL_IN)
			thisPlayerState->setState(PokerEnums::State::RAISED);
		thisPlayerState->updateStatRaise(pokerState->currentBettingRound, playerMoveAmount);

		pokerState->setLastToRaiseSeatNumber(thisPlayerState->seatNumber);
		pokerState->setMinRaiseAmount(playerMoveAmount < pokerState->minRaiseAmount ? (playerMoveAmount + pokerState->minRaiseAmount) : playerMoveAmount);
	}

}
