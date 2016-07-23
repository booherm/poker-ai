#ifndef POTCONTROLLER_HPP
#define POTCONTROLLER_HPP

#include <vector>
#include "PokerEnumerations.hpp"
#include "PlayerState.hpp"
#include "json.hpp"
#include "Logger.hpp"
#include "StateVariableCollection.hpp"

class PotController {
public:
	void initialize(oracle::occi::Connection* con, Logger* logger, std::vector<PlayerState>* playerStates, StateVariableCollection* stateVariables);
	void load(
		oracle::occi::ResultSet* potStateRs,
		Logger* logger,
		std::vector<PlayerState>* playerStates,
		oracle::occi::ResultSet* potContributionStateRs,
		StateVariableCollection* stateVariables
	);
	bool getBetExists(PokerEnums::BettingRound bettingRound) const;
	unsigned int getEligibleToWinMoney(unsigned int playerSeatNumber) const;
	std::vector<unsigned int> getPotIds() const;
	std::vector<unsigned int> getPotContributors(unsigned int potId) const;
	unsigned int getPotValue(unsigned int potId) const;
	unsigned int getTotalValue() const;
	bool getUnevenPotsExist() const;
	void getUiState(Json::Value& potsArray) const;

	void contributeToPot(unsigned int seatNumber, unsigned int amount, PokerEnums::BettingRound bettingRound, unsigned int stateId);
	void issueApplicablePotRefunds(unsigned int stateId);
	void issueDefaultPotWins(unsigned int stateId);
	void calculateDeficitsAndPotentials();
	void insertStateLog(unsigned int stateId);

private:

	struct PotContribution {
		unsigned int playerSeatNumber;
		unsigned int contributionAmount;
	};

	struct Pot {
		unsigned int potNumber;
		PokerEnums::BettingRound bettingRound;
		unsigned int betValue;
		std::vector<PotContribution> contributions;
	};

	unsigned int getPotDeficit(unsigned int playerSeatNumber) const;

	oracle::occi::Connection* con;
	Logger* logger;
	StateVariableCollection* stateVariables;
	std::vector<PlayerState>* playerStates;
	std::vector<Pot> pots;
};

#endif
