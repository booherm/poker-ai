#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <string>
#include <vector>
#include <occi.h>
#include "PokerEnumerations.hpp"
#include "PokerState.hpp"
#include "Deck.hpp"
#include "PlayerState.hpp"
#include "json.hpp"
#include "Logger.hpp"
#include "Strategy.hpp"
#include "StrategyEvaluationDataProvider.hpp"

class Player {
public:

	void initialize(
		oracle::occi::Connection* con,
		Logger* logger,
		PokerState* pokerState,
		std::vector<PlayerState>* playerStates,
		unsigned int seatNumber,
		Strategy* strategy,
		const std::string& playerId,
		unsigned int buyInAmount
	);
	void load(
		oracle::occi::Connection* con,
		Logger* logger,
		PokerState* pokerState,
		std::vector<PlayerState>* playerStates,
		Strategy* strategy,
		oracle::occi::ResultSet* playerStateRs
	);
	bool getIsActive() const;
	PokerEnums::State getState() const;
	std::string getStateString() const;
	bool getPresentedBetOpportunity() const;
	std::string getBestHandComparator() const;
	int getMoney() const;
	unsigned int getStrategyGeneration() const;
	unsigned int getStrategyId() const;
	void getUiState(Json::Value& playerStateData) const;
	void issueWinnings(unsigned int winningsAmount, bool isMainPot, bool splittingPot);
	void setBestHandRank(unsigned int rank);
	void setHandShowing();
	void setPresentedBetOpportunity();
	void setHoleCards(Deck::Card holeCard1, Deck::Card holeCard2);
	void replaceHoleCard(unsigned int cardSlot, unsigned int cardId);
	void setPlayerShowdownMuck();
	void setStrategy(Strategy* strategy);
	std::string calculateBestHand();
	PokerEnums::State performPlayerMove(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount);
	void processGameResults(unsigned int tournamentRank);
	void resetGameState();
	void resetBettingRoundState();
	void insertStateLog();

private:
	struct Hand {
		std::vector<Deck::Card> cards;
		PokerEnums::HandClassification classification;
		std::string comparator;
	};

	inline bool getCanFold() const;
	inline bool getCanCheck() const;
	inline bool getCanCall() const;
	bool getCanBet() const;
	bool getCanRaise() const;
	StrategyEvaluationDataProvider::BetRaiseLimits Player::getBetRaiseLimits() const;
	std::string getHandClassificationString(PokerEnums::HandClassification classification) const;
	void clearHoleCards();
	void pushHoleCard(const Deck::Card& card);
	Hand Player::calculateHandAttributes(std::vector<Deck::Card> cards);
	void performAutomaticPlayerMove();
	void performExplicitPlayerMove(PokerEnums::PlayerMove playerMove, unsigned int playerMoveAmount);

	oracle::occi::Connection* con;
	Logger* logger;
	PokerState* pokerState;
	std::vector<PlayerState>* playerStates;
	PlayerState* thisPlayerState;
	StrategyEvaluationDataProvider strategyEvaluationDataProvider;
	std::vector<Deck::Card> holeCards;
	Hand bestHand;
	unsigned int bestHandRank;

};

#endif
