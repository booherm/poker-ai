#include "TournamentController.hpp"
#include <algorithm>
#include "Util.hpp"
#include <iostream>

void TournamentController::initialize(const std::string& databaseId, PythonManager* pythonManager, StrategyManager* strategyManager) {
	con.Open(databaseId, "poker_ai", "poker_ai");
	logger.initialize(con);
	pokerState.pythonManager = pythonManager;
	this->strategyManager = strategyManager;
}

void TournamentController::testAutomatedTournament(
	unsigned int evolutionTrialId,
	unsigned int tournamentCount,
	unsigned int playerCount,
	unsigned int buyInAmount,
	unsigned int initialSmallBlindValue,
	unsigned int doubleBlindsInterval,
	bool performStateLogging,
	bool performGeneralLogging
) {
	
	// setup dummy strategy IDs for tournament result logging
	std::vector<unsigned int> strategyIds;
	for (unsigned int i = 0; i < playerCount; i++) {
		//strategyIds.push_back(0);  // random move strategy
		strategyIds.push_back(i + 1);
	}

	for (unsigned int i = 1; i <= tournamentCount; i++) {
		playAutomatedTournament(
			evolutionTrialId,
			i, // tournament id
			strategyIds,
			playerCount,
			buyInAmount,
			initialSmallBlindValue,
			doubleBlindsInterval,
			performStateLogging,
			performGeneralLogging
		);
	}
}

void TournamentController::playAutomatedTournament(
	unsigned int evolutionTrialId,
	unsigned int tournamentId,
	const std::vector<unsigned int>& strategyIds,
	unsigned int playerCount,
	unsigned int buyInAmount,
	unsigned int initialSmallBlindValue,
	unsigned int doubleBlindsInterval,
	bool performStateLogging,
	bool performGeneralLogging
) {
	
	initializeTournament(
		tournamentId,
		TournamentMode::INTERNAL,
		evolutionTrialId,
		strategyIds,
		playerCount,
		buyInAmount,
		performStateLogging,
		performGeneralLogging
	);

	logger.log(0, "automated tournament " + std::to_string(tournamentId)  + " initialized");

	unsigned int maxSmallBlindValue = buyInAmount * pokerState.playerCount;
	pokerState.setSmallBlindValue(initialSmallBlindValue);
	do {

		// double blinds if a game is about to start and will be on a blind doubling interval
		if (doubleBlindsInterval != 0) {
			if (!pokerState.gameInProgress && (pokerState.currentGameNumber + 1) % doubleBlindsInterval == 0) {
				pokerState.setSmallBlindValue(pokerState.smallBlindValue * 2);
				if (pokerState.smallBlindValue > maxSmallBlindValue)
					pokerState.setSmallBlindValue(maxSmallBlindValue);
			}
		}

		stepPlay(PokerEnums::PlayerMove::AUTO, 0);

	} while (pokerState.tournamentInProgress && pokerState.currentGameNumber <= maxGamesInTournament);

	if (pokerState.currentGameNumber > maxGamesInTournament)
		logger.log(0, "maximum number of games in tournament exceeded");

	logger.log(0, "automated tournament " + std::to_string(tournamentId) + " complete");

}

unsigned int TournamentController::initNonAutomatedTournament(TournamentMode tournamentMode, unsigned int playerCount, unsigned int buyInAmount) {
	std::vector<unsigned int> emptyStrategyIdSet;
	return initializeTournament(0, tournamentMode, 0, emptyStrategyIdSet, playerCount, buyInAmount, true, true);
}

unsigned int TournamentController::stepPlay(unsigned int stateId, unsigned int smallBlindValue, PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount) {

	loadState(stateId);
	pokerState.setSmallBlindValue(smallBlindValue);
	stepPlay(playerMove, playerMoveAmount);

	pokerState.stateVariables.dumpData();

	return pokerState.currentStateId;
}

unsigned int TournamentController::getPreviousStateId(unsigned int stateId) const {

	unsigned int returnStateId;
	std::string procCall = "BEGIN :returnStateId := pkg_poker_ai.get_previous_state_id(";
	procCall.append("p_state_id => :stateId");
	procCall.append("); END;");

	ocilib::Statement st(con);
	st.Prepare(procCall);
	st.Bind("stateId", stateId, ocilib::BindInfo::In);
	st.Bind("returnStateId", returnStateId, ocilib::BindInfo::Out);
	st.ExecutePrepared();

	return returnStateId;
}

unsigned int TournamentController::getNextStateId(unsigned int stateId) const {

	unsigned int returnStateId;
	std::string procCall = "BEGIN :returnStateId := pkg_poker_ai.get_next_state_id(";
	procCall.append("p_state_id => :stateId");
	procCall.append("); END;");

	ocilib::Statement st(con);
	st.Prepare(procCall);
	st.Bind("stateId", stateId, ocilib::BindInfo::In);
	st.Bind("returnStateId", returnStateId, ocilib::BindInfo::Out);
	st.ExecutePrepared();

	return returnStateId;
}

void TournamentController::getUiState(unsigned int stateId, Json::Value& uiData) {

	loadState(stateId);

	// tournament state
	Json::Value tournamentStateData(Json::objectValue);
	tournamentStateData["player_count"] = pokerState.playerCount;
	tournamentStateData["buy_in_amount"] = pokerState.buyInAmount;
	if (pokerState.currentGameNumber == 0)
		tournamentStateData["current_game_number"] = Json::Value::null;
	else
		tournamentStateData["current_game_number"] = pokerState.currentGameNumber;
	tournamentStateData["game_in_progress"] = pokerState.gameInProgress ? "Yes" : "No";
	tournamentStateData["current_state_id"] = pokerState.currentStateId;
	uiData["tournamentState"] = tournamentStateData;

	// game state
	Json::Value gameStateData(Json::objectValue);
	if(pokerState.smallBlindSeatNumber == 0)
		gameStateData["small_blind_seat_number"] = Json::Value::null;
	else
		gameStateData["small_blind_seat_number"] = pokerState.smallBlindSeatNumber;
	if (pokerState.bigBlindSeatNumber == 0)
		gameStateData["big_blind_seat_number"] = Json::Value::null;
	else
		gameStateData["big_blind_seat_number"] = pokerState.bigBlindSeatNumber;
	if (pokerState.turnSeatNumber == 0)
		gameStateData["turn_seat_number"] = Json::Value::null;
	else
		gameStateData["turn_seat_number"] = pokerState.turnSeatNumber;
	if (pokerState.smallBlindValue == 0)
		gameStateData["small_blind_value"] = Json::Value::null;
	else
		gameStateData["small_blind_value"] = pokerState.smallBlindValue;
	if (pokerState.bigBlindValue == 0)
		gameStateData["big_blind_value"] = Json::Value::null;
	else
		gameStateData["big_blind_value"] = pokerState.bigBlindValue;
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::NO_BETTING_ROUND)
		gameStateData["betting_round_number"] = Json::Value::null;
	else
		gameStateData["betting_round_number"] = getCurrentBettingRoundString();
	gameStateData["betting_round_in_progress"] = pokerState.bettingRoundInProgress ? "Yes" : "No";
	if (pokerState.lastToRaiseSeatNumber == 0)
		gameStateData["last_to_raise_seat_number"] = Json::Value::null;
	else
		gameStateData["last_to_raise_seat_number"] = pokerState.lastToRaiseSeatNumber;
	gameStateData["community_card_1"] = Json::Value::null;
	gameStateData["community_card_2"] = Json::Value::null;
	gameStateData["community_card_3"] = Json::Value::null;
	gameStateData["community_card_4"] = Json::Value::null;
	gameStateData["community_card_5"] = Json::Value::null;
	unsigned int communityCardCount = pokerState.communityCards.size();
	if (communityCardCount > 0) {
		gameStateData["community_card_1"] = pokerState.communityCards[0].cardId;
		gameStateData["community_card_2"] = pokerState.communityCards[1].cardId;
		gameStateData["community_card_3"] = pokerState.communityCards[2].cardId;

	}
	if(communityCardCount > 3)
		gameStateData["community_card_4"] = pokerState.communityCards[3].cardId;
	if (communityCardCount > 4)
		gameStateData["community_card_5"] = pokerState.communityCards[4].cardId;
	uiData["gameState"] = gameStateData;

	// players state
	Json::Value playerArray(Json::arrayValue);
	for (unsigned int i = 0; i < pokerState.playerCount; i++)
	{
		Json::Value playerStateData(Json::objectValue);
		players[i].getUiState(playerStateData);
		playerArray.append(playerStateData);
	}
	uiData["playerState"] = playerArray;

	// pots state
	Json::Value potsArray(Json::arrayValue);
	pokerState.potController.getUiState(potsArray);
	uiData["potState"] = potsArray;

	// status messages
	Json::Value statusMessageArray(Json::arrayValue);
	logger.getLogMessages(statusMessageArray);
	uiData["statusMessage"] = statusMessageArray;

}

TournamentController::~TournamentController() {
	con.Close();
	ocilib::Environment::Cleanup();
}

unsigned int TournamentController::getActivePlayerCount() const {

	unsigned int activePlayerCount = 0;
	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		PokerEnums::State playerState = players[i].getState();
		if (playerState != PokerEnums::State::OUT_OF_TOURNAMENT && playerState != PokerEnums::State::FOLDED)
			activePlayerCount++;
	}

	return activePlayerCount;
}

bool TournamentController::getIsActivePlayer(PokerEnums::State playerState, bool includeFoldedPlayers, bool includeAllInPlayers) const {
	if (playerState == PokerEnums::State::OUT_OF_TOURNAMENT)
		return false;
	if (!includeFoldedPlayers && playerState == PokerEnums::State::FOLDED)
		return false;
	if (!includeAllInPlayers && playerState == PokerEnums::State::ALL_IN)
		return false;

	return true;
}

std::string TournamentController::getCurrentBettingRoundString() const {

	if (pokerState.currentBettingRound == PokerEnums::BettingRound::PRE_FLOP)
		return "1 - Pre-Flop";
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::FLOP)
		return "2 - Flop";
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::TURN)
		return "3 - Turn";
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::RIVER)
		return "4 - River";
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::SHOWDOWN)
		return "5 - Showdown";

	return "";

}

bool TournamentController::getPlayersRemain() const {
	unsigned int remainingPlayers = 0;
	for (unsigned int i = 0; i < pokerState.playerCount && remainingPlayers < 2; i++) {
		if (players[i].getIsActive())
			remainingPlayers++;
	}

	return remainingPlayers > 1;
}

unsigned int TournamentController::getNextActiveSeatNumber(
	unsigned int relativeToSeatNumber,
	bool includeRelativeSeat,
	bool includeFoldedPlayers,
	bool includeAllInPlayers
) const {

	int startingSeat = relativeToSeatNumber;
	if (includeRelativeSeat)
		startingSeat--;

	// get the seat number of the next active player clockwise of relativeToSeatNumber
	for (unsigned int i = startingSeat; i < pokerState.playerCount; i++) {
		if (getIsActivePlayer(players[i].getState(), includeFoldedPlayers, includeAllInPlayers))
			return i + 1;
	}

	// no active players clockwise of relativeToSeatNumber up to the end of the player vector, circle back to seat 1
	for (int i = 0; i < startingSeat - 1; i++) {
		if (getIsActivePlayer(players[i].getState(), includeFoldedPlayers, includeAllInPlayers))
			return i + 1;
	}

	// no active player found
	return 0;
}

bool TournamentController::getNotAllPresentedBetOpportunity() const {

	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		if (!players[i].getPresentedBetOpportunity())
			return true;
	}

	return false;
}

void TournamentController::getNewStateId() {
	if (performStateLogging) {
		std::string procCall = "BEGIN :stateId := pkg_poker_ai.get_new_state_id; END;";
		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("stateId", pokerState.currentStateId, ocilib::BindInfo::Out);
		st.ExecutePrepared();
	}
	else
		pokerState.currentStateId = 0;

	logger.clearLogMessages();
}

void TournamentController::loadState(unsigned int stateId) {

	if (pokerState.currentStateId != stateId) {

		std::string procCall = "BEGIN pkg_poker_ai.select_state(";
		procCall.append("p_state_id               => :stateId, ");
		procCall.append("p_poker_state            => :pokerStateRs, ");
		procCall.append("p_player_state           => :playerStateRs, ");
		procCall.append("p_pot_state              => :potStateRs, ");
		procCall.append("p_pot_contribution_state => :potContributionStateRs, ");
		procCall.append("p_poker_ai_log           => :pokerAiLogRs");
		procCall.append("); END;");
		ocilib::Statement st(con);
		ocilib::Statement pokerStateBind(con);
		ocilib::Statement playerStateBind(con);
		ocilib::Statement potStateBind(con);
		ocilib::Statement potContributionStateBind(con);
		ocilib::Statement pokerAiLogBind(con);
		st.Prepare(procCall);
		st.Bind("stateId", stateId, ocilib::BindInfo::In);
		st.Bind("pokerStateRs", pokerStateBind, ocilib::BindInfo::Out);
		st.Bind("playerStateRs", playerStateBind, ocilib::BindInfo::Out);
		st.Bind("potStateRs", potStateBind, ocilib::BindInfo::Out);
		st.Bind("potContributionStateRs", potContributionStateBind, ocilib::BindInfo::Out);
		st.Bind("pokerAiLogRs", pokerAiLogBind, ocilib::BindInfo::Out);
		st.ExecutePrepared();

		ocilib::Resultset pokerStateRs = pokerStateBind.GetResultset();
		ocilib::Resultset playerStateRs = playerStateBind.GetResultset();
		ocilib::Resultset potStateRs = potStateBind.GetResultset();
		ocilib::Resultset potContributionStateRs = potContributionStateBind.GetResultset();
		ocilib::Resultset pokerAiLogRs = pokerAiLogBind.GetResultset();

		pokerStateRs.Next();
		tournamentId = pokerStateRs.Get<unsigned int>("tournament_id");
		tournamentMode = (TournamentMode) pokerStateRs.Get<unsigned int>("tournament_mode");
		evolutionTrialId = pokerStateRs.Get<unsigned int>("evolution_trial_id");
		pokerState.load(pokerStateRs);
		players.resize(pokerState.playerCount);
		playerStates.resize(pokerState.playerCount);
		for (unsigned int i = 0; i < pokerState.playerCount; i++) {
			playerStateRs.Next();
			unsigned int strategyId = playerStateRs.Get<unsigned int>("current_strategy_id");
			players[i].load(con, &logger, &pokerState, &playerStates, strategyManager->getStrategy(strategyId), playerStateRs);
		}

		pokerState.potController.load(potStateRs, &logger, &playerStates, potContributionStateRs, &pokerState.stateVariables);

		logger.clearLogMessages();
		while (pokerAiLogRs.Next()) {
			logger.loadMessage(pokerAiLogRs.Get<std::string>("message"));
		}
	}

}

unsigned int TournamentController::initializeTournament(
	unsigned int tournamentId,
	TournamentMode tournamentMode,
	unsigned int evolutionTrialId,
	const std::vector<unsigned int>& strategyIds,
	unsigned int playerCount,
	unsigned int buyInAmount,
	bool performStateLogging,
	bool performGeneralLogging
) {
	logger.setLoggingEnabled(performGeneralLogging);
	getNewStateId();

	std::string tournamentModeString = (tournamentMode == TournamentMode::INTERNAL ? "internal" : "external");
	logger.log(pokerState.currentStateId, "initializing " + tournamentModeString + " tournament, tournamentId = " + std::to_string(tournamentId));

	this->tournamentId = tournamentId;
	this->tournamentMode = tournamentMode;
	this->evolutionTrialId = evolutionTrialId;
	this->performStateLogging = performStateLogging;
	this->performGeneralLogging = performGeneralLogging;
	pokerState.clearStateVariables();
	pokerState.setPlayerCount(playerCount);
	pokerState.setBuyInAmount(buyInAmount);
	pokerState.setCurrentBettingRound(PokerEnums::BettingRound::NO_BETTING_ROUND);
	pokerState.clearCommunityCards();
	pokerState.setTournamentInProgress(true);
	pokerState.setCurrentGameNumber(0);
	pokerState.setGameInProgress(false);
	pokerState.setSmallBlindSeatNumber(0);
	pokerState.setBigBlindSeatNumber(0);
	pokerState.setTurnSeatNumber(0);
	pokerState.setLastToRaiseSeatNumber(0);
	pokerState.setMinRaiseAmount(0);
	pokerState.setSmallBlindValue(0);
	pokerState.setBigBlindValue(0);

	// initialize players
	players.clear();
	players.resize(playerCount);
	playerStates.resize(playerCount);
	for (unsigned int i = 0; i < playerCount; i++) {
		unsigned int strategyId = strategyIds.size() == playerCount ? strategyIds[i] : 0;
		players[i].initialize(con, &logger, &pokerState, &playerStates, i + 1, strategyManager->getStrategy(strategyId), 0, buyInAmount);
	}
	
	// initialize pot controller
	pokerState.potController.initialize(con, &logger, &playerStates, &pokerState.stateVariables);

	captureStateLog();

	return pokerState.currentStateId;
}

void TournamentController::initializeGame() {

	logger.log(pokerState.currentStateId, "initializing game start");

	pokerState.potController.initialize(con, &logger, &playerStates, &pokerState.stateVariables);
	pokerState.deck.initialize(&pokerState.randomNumberGenerator);
	for (unsigned int i = 0; i < pokerState.playerCount; i++)
		players[i].resetGameState();

	pokerState.setBigBlindSeatNumber(getNextActiveSeatNumber(pokerState.smallBlindSeatNumber, false, true, true));
	pokerState.setTurnSeatNumber(getNextActiveSeatNumber(pokerState.bigBlindSeatNumber, false, true, true));
	logger.log(pokerState.currentStateId, "small blind = " + std::to_string(pokerState.smallBlindSeatNumber)
		+ ", big blind = " + std::to_string(pokerState.bigBlindSeatNumber)
		+ ", UTG = " + std::to_string(pokerState.turnSeatNumber));

	pokerState.setCurrentBettingRound(PokerEnums::BettingRound::PRE_FLOP);
	pokerState.setBettingRoundInProgress(false);
	pokerState.setBigBlindValue(pokerState.smallBlindValue * 2);
	pokerState.setMinRaiseAmount(pokerState.bigBlindValue);
	pokerState.setLastToRaiseSeatNumber(0);
	pokerState.clearCommunityCards();

	logger.log(pokerState.currentStateId, "game initialized");
}

void TournamentController::advanceBettingRound() {
	if (pokerState.currentBettingRound == PokerEnums::BettingRound::PRE_FLOP)
		pokerState.setCurrentBettingRound(PokerEnums::BettingRound::FLOP);
	else if (pokerState.currentBettingRound == PokerEnums::BettingRound::FLOP)
		pokerState.setCurrentBettingRound(PokerEnums::BettingRound::TURN);
	else if (pokerState.currentBettingRound == PokerEnums::BettingRound::TURN)
		pokerState.setCurrentBettingRound(PokerEnums::BettingRound::RIVER);
	else if (pokerState.currentBettingRound == PokerEnums::BettingRound::RIVER)
		pokerState.setCurrentBettingRound(PokerEnums::BettingRound::SHOWDOWN);
}

void TournamentController::calculateBestHands() {

	// create structure for holding best hands associated with player
	struct BestHand {
		unsigned int playerIndex;
		std::string bestHandComparator;
	};
	std::vector<BestHand> bestHands;

	// calculate and collect best hands
	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		BestHand bestHand;
		bestHand.playerIndex = i;
		bestHand.bestHandComparator = players[i].calculateBestHand();
		if(bestHand.bestHandComparator != "")
			bestHands.push_back(bestHand);
	}

	// sort best hands to assign rank among players
	std::sort(bestHands.begin(), bestHands.end(), [](BestHand left, BestHand right) {
		return left.bestHandComparator > right.bestHandComparator;
	});

	// assign rank to hand
	unsigned int rank = 1;
	players[bestHands[0].playerIndex].setBestHandRank(rank);
	for (unsigned int i = 1; i < bestHands.size(); i++) {
		BestHand* playerBestHand = &bestHands[i];
		if (playerBestHand->bestHandComparator != bestHands[i - 1].bestHandComparator)
			rank++;
		players[playerBestHand->playerIndex].setBestHandRank(rank);
	}

}

void TournamentController::captureStateLog() {
	if (performStateLogging) {

		std::string procCall = "BEGIN pkg_poker_ai.prepare_state_log(p_state_id => :stateId); END;";
		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("stateId", pokerState.currentStateId, ocilib::BindInfo::In);
		st.ExecutePrepared();

		procCall = "BEGIN pkg_poker_ai.insert_poker_state_log(";
		procCall.append("p_state_id                  => :stateId, ");
		procCall.append("p_tournament_id             => :tournamentId, ");
		procCall.append("p_tournament_mode           => :tournamentMode, ");
		procCall.append("p_evolution_trial_id        => :evolutionTrialId, ");
		procCall.append("p_player_count              => :playerCount, ");
		procCall.append("p_buy_in_amount             => :buyInAmount, ");
		procCall.append("p_tournament_in_progress    => :tournamentInProgress, ");
		procCall.append("p_current_game_number       => :currentGameNumber, ");
		procCall.append("p_game_in_progress          => :gameInProgress, ");
		procCall.append("p_small_blind_seat_number   => :smallBlindSeatNumber, ");
		procCall.append("p_big_blind_seat_number     => :bigBlindSeatNumber, ");
		procCall.append("p_turn_seat_number          => :turnSeatNumber, ");
		procCall.append("p_small_blind_value         => :smallBlindValue, ");
		procCall.append("p_big_blind_value           => :bigBlindValue, ");
		procCall.append("p_betting_round_number      => :bettingRoundNumber, ");
		procCall.append("p_betting_round_in_progress => :bettingRoundInProgress, ");
		procCall.append("p_last_to_raise_seat_number => :lastToRaiseSeatNumber, ");
		procCall.append("p_min_raise_amount          => :minRaiseAmount, ");
		procCall.append("p_community_card_1          => :communityCard1, ");
		procCall.append("p_community_card_2          => :communityCard2, ");
		procCall.append("p_community_card_3          => :communityCard3, ");
		procCall.append("p_community_card_4          => :communityCard4, ");
		procCall.append("p_community_card_5          => :communityCard5");
		procCall.append("); END;");
		st.Prepare(procCall);
		st.Bind("stateId", pokerState.currentStateId, ocilib::BindInfo::In);
		st.Bind("tournamentId", tournamentId, ocilib::BindInfo::In);
		if (tournamentId == 0)
			st.GetBind("tournamentId").SetDataNull(true, 1);
		unsigned int tournamentModeBind = (unsigned int) tournamentMode;
		st.Bind("tournamentMode", tournamentModeBind, ocilib::BindInfo::In);
		st.Bind("evolutionTrialId", evolutionTrialId, ocilib::BindInfo::In);
		if (evolutionTrialId == 0)
			st.GetBind("evolutionTrialId").SetDataNull(true, 1);
		st.Bind("playerCount", pokerState.playerCount, ocilib::BindInfo::In);
		st.Bind("buyInAmount", pokerState.buyInAmount, ocilib::BindInfo::In);
		unsigned int tournamentInProgress = pokerState.tournamentInProgress ? 1 : 0;
		st.Bind("tournamentInProgress", tournamentInProgress, ocilib::BindInfo::In);
		st.Bind("currentGameNumber", pokerState.currentGameNumber, ocilib::BindInfo::In);
		if (pokerState.currentGameNumber == 0)
			st.GetBind("currentGameNumber").SetDataNull(true, 1);
		unsigned int gameInProgress = pokerState.gameInProgress ? 1 : 0;
		st.Bind("gameInProgress", gameInProgress, ocilib::BindInfo::In);
		st.Bind("smallBlindSeatNumber", pokerState.smallBlindSeatNumber, ocilib::BindInfo::In);
		if (pokerState.smallBlindSeatNumber == 0)
			st.GetBind("smallBlindSeatNumber").SetDataNull(true, 1);
		st.Bind("bigBlindSeatNumber", pokerState.bigBlindSeatNumber, ocilib::BindInfo::In);
		if (pokerState.bigBlindSeatNumber == 0)
			st.GetBind("bigBlindSeatNumber").SetDataNull(true, 1);
		st.Bind("turnSeatNumber", pokerState.turnSeatNumber, ocilib::BindInfo::In);
		if (pokerState.turnSeatNumber == 0)
			st.GetBind("turnSeatNumber").SetDataNull(true, 1);
		st.Bind("smallBlindValue", pokerState.smallBlindValue, ocilib::BindInfo::In);
		if (pokerState.smallBlindValue == 0)
			st.GetBind("smallBlindValue").SetDataNull(true, 1);
		st.Bind("bigBlindValue", pokerState.bigBlindValue, ocilib::BindInfo::In);
		if (pokerState.bigBlindValue == 0)
			st.GetBind("bigBlindValue").SetDataNull(true, 1);
		unsigned int currentBettingRound = (unsigned int) pokerState.currentBettingRound;
		st.Bind("bettingRoundNumber", currentBettingRound, ocilib::BindInfo::In);
		if (pokerState.currentBettingRound == PokerEnums::BettingRound::NO_BETTING_ROUND)
			st.GetBind("bettingRoundNumber").SetDataNull(true, 1);
		unsigned int bettingRoundInProgress = pokerState.bettingRoundInProgress ? 1 : 0;
		st.Bind("bettingRoundInProgress", bettingRoundInProgress, ocilib::BindInfo::In);
		st.Bind("lastToRaiseSeatNumber", pokerState.lastToRaiseSeatNumber, ocilib::BindInfo::In);
		if (pokerState.lastToRaiseSeatNumber == 0)
			st.GetBind("lastToRaiseSeatNumber").SetDataNull(true, 1);
		st.Bind("minRaiseAmount", pokerState.minRaiseAmount, ocilib::BindInfo::In);
		if (pokerState.minRaiseAmount == 0)
			st.GetBind("minRaiseAmount").SetDataNull(true, 1);
		unsigned int communityCardCount = pokerState.communityCards.size();
		int nullCard = -1;
		if (communityCardCount > 0) {
			st.Bind("communityCard1", pokerState.communityCards[0].cardId, ocilib::BindInfo::In);
			st.Bind("communityCard2", pokerState.communityCards[1].cardId, ocilib::BindInfo::In);
			st.Bind("communityCard3", pokerState.communityCards[2].cardId, ocilib::BindInfo::In);
		}
		else {
			st.Bind("communityCard1", nullCard, ocilib::BindInfo::In);
			st.Bind("communityCard2", nullCard, ocilib::BindInfo::In);
			st.Bind("communityCard3", nullCard, ocilib::BindInfo::In);
			st.GetBind("communityCard1").SetDataNull(true, 1);
			st.GetBind("communityCard2").SetDataNull(true, 1);
			st.GetBind("communityCard3").SetDataNull(true, 1);
		}
		if (communityCardCount > 3) {
			st.Bind("communityCard4", pokerState.communityCards[3].cardId, ocilib::BindInfo::In);
		}
		else {
			st.Bind("communityCard4", nullCard, ocilib::BindInfo::In);
			st.GetBind("communityCard4").SetDataNull(true, 1);
		}
		if (communityCardCount > 4) {
			st.Bind("communityCard5", pokerState.communityCards[4].cardId, ocilib::BindInfo::In);
		}
		else {
			st.Bind("communityCard5", nullCard, ocilib::BindInfo::In);
			st.GetBind("communityCard5").SetDataNull(true, 1);
		}
		st.ExecutePrepared();

		for (unsigned int i = 0; i < pokerState.playerCount; i++) {
			players[i].insertStateLog();
		}

		pokerState.potController.insertStateLog(pokerState.currentStateId);

		con.Commit();
	}
}

void TournamentController::captureTournamentResults() {
	if (tournamentId != 0) {
		for (unsigned int i = 0; i < pokerState.playerCount; i++) {
			players[i].captureTournamentResults(tournamentId, evolutionTrialId);
		}
		con.Commit();
	}
}

void TournamentController::dealCommunityCards() {

	if (pokerState.currentBettingRound == PokerEnums::BettingRound::FLOP) {
		for (unsigned int i = 0; i < 3; i++)
			pokerState.pushCommunityCard(pokerState.deck.drawRandomCard());
	}
	else
		pokerState.pushCommunityCard(pokerState.deck.drawRandomCard());

}

void TournamentController::dealHoleCards() {

	if (tournamentMode == TournamentMode::INTERNAL) {
		for (unsigned int i = 0; i < players.size(); i++) {
			if (players[i].getIsActive()) {
				players[i].setHoleCards(pokerState.deck.drawRandomCard(), pokerState.deck.drawRandomCard());
			}
		}
	}
	else {
		for (unsigned int i = 0; i < players.size(); i++) {
			if (players[i].getIsActive()) {
				players[i].setHoleCards(pokerState.deck.getUnknownCard(), pokerState.deck.getUnknownCard());
			}
		}
	}
}

void TournamentController::postBlinds() {

	logger.log(pokerState.currentStateId, "posting blinds");

	// post small blind
	int smallBlindPlayerMoney = players[pokerState.smallBlindSeatNumber - 1].getMoney();
	int smallBlindPostAmount = (smallBlindPlayerMoney < (int) pokerState.smallBlindValue) ? smallBlindPlayerMoney : pokerState.smallBlindValue;
	pokerState.potController.contributeToPot(pokerState.smallBlindSeatNumber, smallBlindPostAmount, pokerState.currentBettingRound, pokerState.currentStateId);
	playerStates[pokerState.smallBlindSeatNumber - 1].updateStatBet(PokerEnums::BettingRound::PRE_FLOP, smallBlindPostAmount);

	// post big blind
	int bigBlindPlayerMoney = players[pokerState.bigBlindSeatNumber - 1].getMoney();
	int bigBlindPostAmount = (bigBlindPlayerMoney < (int) pokerState.bigBlindValue) ? bigBlindPlayerMoney : pokerState.bigBlindValue;
	pokerState.potController.contributeToPot(pokerState.bigBlindSeatNumber, bigBlindPostAmount, pokerState.currentBettingRound, pokerState.currentStateId);
	int postDifference = bigBlindPostAmount - smallBlindPostAmount;
	if(postDifference > 0)
		playerStates[pokerState.smallBlindSeatNumber - 1].updateStatRaise(PokerEnums::BettingRound::PRE_FLOP, postDifference);
}

void TournamentController::processGameResults() {
	
	// collect players participating in the showdown
	std::vector<unsigned int> activePlayers;
	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		PokerEnums::State state = players[i].getState();
		if (state != PokerEnums::State::OUT_OF_TOURNAMENT && state != PokerEnums::State::FOLDED) {
			activePlayers.push_back(i + 1);
		}
	}

	if (activePlayers.size() == 1) {
		// everyone but one player folded
		players[activePlayers[0] - 1].issueWinnings(pokerState.potController.getTotalValue(), true, false);
	}
	else {
		// compare players
		struct GameResult {
			unsigned int seatNumber;
			unsigned int showOrder;
			unsigned int potNumber;
			std::string bestHand;
		};

		// last player to bet or raise on the river round must show first.  If no one, first player in showdown clockwise from small blind, including small blind
		unsigned int firstToShowSeatNumber;
		if(pokerState.lastToRaiseSeatNumber == 0 || players[pokerState.lastToRaiseSeatNumber - 1].getState() == PokerEnums::State::FOLDED)
			firstToShowSeatNumber = getNextActiveSeatNumber(pokerState.smallBlindSeatNumber, true, false, true);
		else
			firstToShowSeatNumber = pokerState.lastToRaiseSeatNumber;

		// determine show order
		unsigned int firstToShowIndex;
		for (unsigned int i = 0; i < activePlayers.size(); i++) {
			if (activePlayers[i] == firstToShowSeatNumber) {
				firstToShowIndex = i;
				break;
			}
		}
		std::vector<unsigned int> showOrder;
		for (unsigned int i = firstToShowIndex; i < activePlayers.size(); i++) {
			showOrder.push_back(activePlayers[i]);
		}
		for (unsigned int i = 0; i < firstToShowIndex; i++) {
			showOrder.push_back(activePlayers[i]);
		}

		// process hand showing/mucking choices
		std::vector<unsigned int> seatsToProcess;
		for (unsigned int i = 0; i < showOrder.size(); i++) {
			if (i == 0) {
				// first player has to show
				unsigned int playerSeat = showOrder[i];
				players[playerSeat - 1].setHandShowing();
				seatsToProcess.push_back(playerSeat);
				logger.log(pokerState.currentStateId, "player at seat " + std::to_string(playerSeat) + " shows hand");
			}
			else {
				// all other players have the opportunity to muck
				unsigned int playerSeat = showOrder[i];
				players[playerSeat - 1].setPlayerShowdownMuck();
				if (playerStates[playerSeat - 1].handShowing) {
					seatsToProcess.push_back(playerSeat);
					logger.log(pokerState.currentStateId, "player at seat " + std::to_string(playerSeat) + " shows hand");
				}
				else {
					logger.log(pokerState.currentStateId, "player at seat " + std::to_string(playerSeat) + " mucks hand");
				}
			}
		}

		struct PlayerRank {
			unsigned int playerSeatNumber;
			std::string bestHandComparator;
		};

		// for all players showing hands, determine which pots they win
		std::vector<unsigned int> potIds = pokerState.potController.getPotIds();
		for (unsigned int p = 0; p < potIds.size(); p++) {
			unsigned int potId = potIds[p];
			bool isMainPot = potId == 1;

			// determine contributors to this pot that are eligible to win the pot
			std::vector<unsigned int> potContributors = pokerState.potController.getPotContributors(potId);
			std::vector<unsigned int> eligibleToWinPlayers;
			for (unsigned int pc = 0; pc < potContributors.size(); pc++) {
				unsigned int playerSeatNumber = potContributors[pc];
				if (playerStates[playerSeatNumber - 1].handShowing)
					eligibleToWinPlayers.push_back(playerSeatNumber);
			}

			// gather best hands of eligible players
			std::vector<PlayerRank> playerRanks;
			for (unsigned int ep = 0; ep < eligibleToWinPlayers.size(); ep++) {
				unsigned int eligiblePlayerSeatNumber = eligibleToWinPlayers[ep];
				PlayerRank pr{ eligiblePlayerSeatNumber, players[eligiblePlayerSeatNumber - 1].getBestHandComparator() };
				playerRanks.push_back(pr);
			}

			// sort best hands
			std::sort(playerRanks.begin(), playerRanks.end(), [](PlayerRank i, PlayerRank j) {
				return i.bestHandComparator > j.bestHandComparator;
			});

			// determine hand winner(s)
			bool splittingPot = false;
			std::vector<unsigned int> winners;
			winners.push_back(playerRanks[0].playerSeatNumber);
			std::string winningComparator = playerRanks[0].bestHandComparator;
			for (unsigned int w = 1; w < playerRanks.size(); w++) {
				if (playerRanks[w].bestHandComparator == winningComparator) {
					winners.push_back(playerRanks[w].playerSeatNumber);
					splittingPot = true;
				}
			}

			// calculate winning amounts
			unsigned int winnerCount = winners.size();
			unsigned int potValue = pokerState.potController.getPotValue(potId);
			unsigned int perPlayerAmount = potValue / winnerCount;
			bool oddSplit = perPlayerAmount != (float) potValue / winnerCount;
			unsigned oddSplitBalance = 0;
			unsigned int oddSplitRecipient = 0;
			if (oddSplit) {
				oddSplitBalance = potValue - (perPlayerAmount * winnerCount);

				// the first player in the set of winning players for this pot clockwise of the small blind (including the small blind)
				// receives the odd split balance
				for (unsigned int snIndex = pokerState.smallBlindSeatNumber - 1; snIndex < pokerState.playerCount; snIndex++) {
					// look for this seat number in the set of winners
					for (unsigned int winnerSeatNumberIndex = 0; winnerSeatNumberIndex < winners.size(); winnerSeatNumberIndex++) {
						if (snIndex + 1 == winners[winnerSeatNumberIndex]) {
							oddSplitRecipient = snIndex + 1;
							break;
						}
					}
				}

				if (oddSplitRecipient == 0) {
					// no winners clockwise of small blind seat number up to the end of the player vector, circle back to seat 1
					for (unsigned int snIndex = 0; snIndex < pokerState.smallBlindSeatNumber - 1; snIndex++) {
						for (unsigned int winnerSeatNumberIndex = 0; winnerSeatNumberIndex < winners.size(); winnerSeatNumberIndex++) {
							if (snIndex + 1 == winners[winnerSeatNumberIndex]) {
								oddSplitRecipient = snIndex + 1;
								break;
							}
						}
					}
				}

				logger.log(pokerState.currentStateId, "odd split occurred, odd split balance recipient seat = " + std::to_string(oddSplitRecipient));

			}

			// distribute winnings
			for (unsigned int w = 0; w < winnerCount; w++) {
				unsigned int winnerSeatNumber = winners[w];
				unsigned int distributionAmount;
				if (oddSplit && winnerSeatNumber == oddSplitRecipient)
					distributionAmount = perPlayerAmount + oddSplitBalance;
				else
					distributionAmount = perPlayerAmount;

				logger.log(pokerState.currentStateId, "player at seat " + std::to_string(winnerSeatNumber) + " wins "
					+ std::to_string(distributionAmount) + " from pot " + std::to_string(potId)
					+ (splittingPot ? " (split pot)" : ""));
				players[winnerSeatNumber - 1].issueWinnings(distributionAmount, isMainPot, splittingPot);
			}
		}
	}

	// determine tournament rank for anyone that ran out of money
	unsigned int tournamentRank = 0;
	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		if (players[i].getIsActive())
			tournamentRank++;
	}

	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		players[i].processGameResults(tournamentRank);
	}

	pokerState.setGameInProgress(false);
	pokerState.setBettingRoundInProgress(false);

	logger.log(pokerState.currentStateId, "game over");
}

void TournamentController::processTournamentResults() {

	// mark final tournament winner
	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		PlayerState* playerState = &playerStates[i];
		if (playerState->state != PokerEnums::State::OUT_OF_TOURNAMENT) {
			playerState->setTournamentRank(1);
			playerState->setState(PokerEnums::State::OUT_OF_TOURNAMENT);
			break;
		}
	}

	pokerState.setTournamentInProgress(false);
	captureTournamentResults();

	logger.log(pokerState.currentStateId, "tournament over");
}

void TournamentController::resetPlayerBettingRoundState() {
	logger.log(pokerState.currentStateId, "resetting players betting round state");

	for (unsigned int i = 0; i < pokerState.playerCount; i++) {
		players[i].resetBettingRoundState();
	}
}

void TournamentController::stepPlay(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount) {

	getNewStateId();

	if (getPlayersRemain()) {
		if (!pokerState.gameInProgress) {
			// start a new game
			if (pokerState.currentGameNumber == 0)
				pokerState.setSmallBlindSeatNumber(1);
			else {
				logger.log(pokerState.currentStateId, "advancing small blind seat");
				pokerState.setSmallBlindSeatNumber(getNextActiveSeatNumber(pokerState.smallBlindSeatNumber, false, true, true));
			}

			initializeGame();
			pokerState.setCurrentGameNumber(pokerState.currentGameNumber + 1);
			pokerState.setGameInProgress(true);
		}
		else {
			// game is currently in progress
			if (!pokerState.bettingRoundInProgress) {

				// no betting round currently in progress, start a new betting round or enter showdown
				pokerState.setMinRaiseAmount(pokerState.bigBlindValue);

				if (pokerState.currentBettingRound == PokerEnums::BettingRound::PRE_FLOP) {
					postBlinds();
					dealHoleCards();
					pokerState.setTurnSeatNumber(getNextActiveSeatNumber(pokerState.bigBlindSeatNumber, false, false, false));
				}
				else if (pokerState.currentBettingRound < PokerEnums::BettingRound::SHOWDOWN) {
					resetPlayerBettingRoundState();
					pokerState.setTurnSeatNumber(getNextActiveSeatNumber(pokerState.smallBlindSeatNumber, true, false, false));
					dealCommunityCards();
					calculateBestHands();
				}
				else {
					// showdown
					processGameResults();
				}

				// indicate betting round in progress
				if (pokerState.currentBettingRound != PokerEnums::BettingRound::SHOWDOWN) {

					// if no players can make a move, explicitly state that to the log and increment the betting round
					if (pokerState.turnSeatNumber == 0) {
						logger.log(pokerState.currentStateId, "no players can make a move");
						logger.log(pokerState.currentStateId, "betting round over");
						pokerState.setBettingRoundInProgress(false);
						advanceBettingRound();
					}
					else
						pokerState.setBettingRoundInProgress(true);
				}
				else {
					// showdown processing complete, reset betting round state
					pokerState.setBettingRoundInProgress(false);
					pokerState.setCurrentBettingRound(PokerEnums::BettingRound::PRE_FLOP);
				}
			}
			else {

				// betting round is in progress, let player make move
				if (pokerState.turnSeatNumber != 0) {
					Player* turnPlayer = &players[pokerState.turnSeatNumber - 1];
					turnPlayer->setPresentedBetOpportunity();
					PokerEnums::State newPlayerState = turnPlayer->performPlayerMove(playerMove, playerMoveAmount);
					if (newPlayerState == PokerEnums::State::FOLDED) {
						pokerState.potController.issueApplicablePotRefunds(pokerState.currentStateId);
						pokerState.potController.issueDefaultPotWins(pokerState.currentStateId);
						pokerState.potController.calculateDeficitsAndPotentials();
					}
				}

				if (getActivePlayerCount() <= 1) {
					// all players folded but one
					processGameResults();
				}
				else {
					// if the pots aren't even excluding all-in players, allow betting to continue
					bool unevenPot = pokerState.potController.getUnevenPotsExist();
					bool betOpportunityNotPresented = false;
					if (!unevenPot) {
						// check if anyone has not been presented an opportunity to bet
						betOpportunityNotPresented = getNotAllPresentedBetOpportunity();
					}

					if (unevenPot || betOpportunityNotPresented) {
						// betting continues, advance player turn
						pokerState.setTurnSeatNumber(getNextActiveSeatNumber(pokerState.turnSeatNumber, false, false, false));
					}
					else {
						// betting round over
						logger.log(pokerState.currentStateId, "betting round over");
						pokerState.setBettingRoundInProgress(false);
						advanceBettingRound();
					}
				}
			}
		}
	}
	else {
		// only one active player remains, process tournament results
		processTournamentResults();
	}

	captureStateLog();
}
