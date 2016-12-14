#ifndef TOURNAMENTCONTROLLER_HPP
#define TOURNAMENTCONTROLLER_HPP

#include <string>
#include <vector>
#include "PokerEnumerations.hpp"
#include "Player.hpp"
#include "PokerState.hpp"
#include "StrategyManager.hpp"
#include "TournamentResultCollector.hpp"
#include "json.hpp"
#include "Logger.hpp"

class TournamentController {
public:
	enum TournamentMode {
		INTERNAL = 0,
		EXTERNAL = 1
	};

	void initialize(
		DbConnectionManager* dbConnectionManager,
		PythonManager* pythonManager,
		StrategyManager* strategyManager,
		TournamentResultCollector* tournamentResultCollector
	);
	void testAutomatedTournament(
		unsigned int evolutionTrialId,
		unsigned int tournamentCount,
		unsigned int playerCount,
		unsigned int buyInAmount,
		unsigned int initialSmallBlindValue,
		unsigned int doubleBlindsInterval,
		bool performStateLogging,
		bool performGeneralLogging
	);
	void playAutomatedTournament(
		unsigned int evolutionTrialId,
		unsigned int tournamentId,
		const std::vector<unsigned int>& strategyIds,
		unsigned int playerCount,
		unsigned int buyInAmount,
		unsigned int initialSmallBlindValue,
		unsigned int doubleBlindsInterval,
		bool performStateLogging,
		bool performGeneralLogging
	);
	unsigned int initNonAutomatedTournament(TournamentMode tournamentMode, unsigned int playerCount, unsigned int buyInAmount);
	unsigned int stepPlay(unsigned int stateId, unsigned int smallBlindValue, PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount);
	unsigned int editCard(unsigned int stateId, const std::string& cardType, unsigned int seatNumber, unsigned int cardSlot, unsigned int cardId);
	void updatePlayerId(unsigned int seatNumber, const std::string& playerId);
	void updatePlayerStrategyId(unsigned int seatNumber, unsigned int strategyId);
	unsigned int getPreviousStateId(unsigned int stateId) const;
	unsigned int getNextStateId(unsigned int stateId) const;
	void getUiState(unsigned int stateId, Json::Value& uiData);
	TournamentController::~TournamentController();

private:
	unsigned int getActivePlayerCount() const;
	bool getIsActivePlayer(PokerEnums::State playerState, bool includeFoldedPlayers, bool includeAllInPlayers) const;
	std::string getCurrentBettingRoundString() const;
	bool TournamentController::getPlayersRemain() const;
	unsigned int getNextActiveSeatNumber(unsigned int relativeToSeatNumber, bool includeRelativeSeat, bool includeFoldedPlayers, bool includeAllInPlayers) const;
	bool getNotAllPresentedBetOpportunity() const;
	void getNewStateId();

	bool loadState(unsigned int stateId);
	unsigned int initializeTournament(
		unsigned int tournamentId,
		TournamentMode tournamentMode,
		unsigned int evolutionTrialId,
		const std::vector<unsigned int>& strategyIds,
		unsigned int playerCount,
		unsigned int buyInAmount,
		bool performStateLogging,
		bool performGeneralLogging
	);
	void initializeGame();
	void advanceBettingRound();
	void calculateBestHands();
	void captureStateLog();
	void captureTournamentResults();
	void dealCommunityCards();
	void dealHoleCards();
	void postBlinds();
	void processGameResults();
	void processTournamentResults();
	void resetPlayerBettingRoundState();
	void stepPlay(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount);

	// tournament attributes
	unsigned int tournamentId;
	TournamentMode tournamentMode;
	unsigned int evolutionTrialId;
	bool performStateLogging;
	bool performGeneralLogging;
	const unsigned int maxGamesInTournament = 10000;
	PokerState pokerState;
	std::vector<Player> players;
	std::vector<PlayerState> playerStates;
	StrategyManager* strategyManager;
	TournamentResultCollector* tournamentResultCollector;
	Logger logger;

	DbConnectionManager* dbConnectionManager;
	oracle::occi::Connection* con;

};

#endif
