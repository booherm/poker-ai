#ifndef POTCONTROLLER_HPP
#define POTCONTROLLER_HPP

#include <vector>
#include <ocilib.hpp>
#include "PokerEnumerations.hpp"
#include "PlayerState.hpp"
#include "json.hpp"
#include "Logger.hpp"

class PotController {
public:
	void initialize(ocilib::Connection& con, Logger* logger, std::vector<PlayerState>* playerStates);
	void load(ocilib::Resultset& potStateRs, Logger* logger, ocilib::Resultset& potContributionStateRs);

	bool getBetExists(PokerEnums::BettingRound bettingRound) const;
	unsigned int getPotDeficit(unsigned int playerSeatNumber) const;
	std::vector<unsigned int> getPotIds() const;
	std::vector<unsigned int> getPotContributors(unsigned int potId) const;
	unsigned int getPotValue(unsigned int potId) const;
	unsigned int getTotalValue() const;
	unsigned int getTotalPotContribution(unsigned int seatNumber) const;
	bool getUnevenPotsExist() const;
	void getUiState(Json::Value& potsArray) const;

	void contributeToPot(unsigned int seatNumber, unsigned int amount, PokerEnums::BettingRound bettingRound, unsigned int stateId);
	void issueApplicablePotRefunds(unsigned int stateId);
	void issueDefaultPotWins(unsigned int stateId);
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

	ocilib::Connection con;
	Logger* logger;
	std::vector<PlayerState>* playerStates;
	std::vector<Pot> pots;
};

#endif
