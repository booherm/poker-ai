#include "PotController.hpp"
#include <map>
#include <set>

void PotController::initialize(ocilib::Connection& con, Logger* logger, std::vector<PlayerState>* playerStates) {
	this->con = con;
	this->logger = logger;
	this->playerStates = playerStates;
	pots.clear();
}

void PotController::load(ocilib::Resultset& potStateRs, Logger* logger, ocilib::Resultset& potContributionStateRs) {
	this->logger = logger;

	pots.clear();
	while (potStateRs.Next()) {
		Pot pot;
		pot.potNumber = potStateRs.Get<unsigned int>("pot_number");
		pot.bettingRound = (PokerEnums::BettingRound) potStateRs.Get<unsigned int>("betting_round_number");
		pot.betValue = potStateRs.Get<unsigned int>("bet_value");
		pots.push_back(pot);
	}

	while (potContributionStateRs.Next()) {
		unsigned int seekingPotNumber = potContributionStateRs.Get<unsigned int>("pot_number");
		PokerEnums::BettingRound seekingBettingRound = (PokerEnums::BettingRound) potStateRs.Get<unsigned int>("betting_round_number");
		for (unsigned int i = 0; i < pots.size(); i++) {
			Pot* pot = &pots[i];
			if (pot->potNumber == seekingPotNumber && pot->bettingRound == seekingBettingRound) {
				PotContribution potContribution;
				potContribution.playerSeatNumber = potStateRs.Get<unsigned int>("player_seat_number");
				potContribution.contributionAmount = potStateRs.Get<unsigned int>("pot_contribution");
				pot->contributions.push_back(potContribution);
				break;
			}
		}
	}
}

bool PotController::getBetExists(PokerEnums::BettingRound bettingRound) const {

	for (unsigned int p = 0; p < pots.size(); p++) {
		if (pots[p].bettingRound == bettingRound)
			return true;
	}

	return false;
}

unsigned int PotController::getPotDeficit(unsigned int playerSeatNumber) const {

	unsigned int totalDeficit = 0;
	for (unsigned int p = 0; p < pots.size(); p++) {
		const Pot* pot = &pots[p];
		bool contributionFound = false;
		for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
			const PotContribution* potContribution = &pot->contributions[pc];
			if (potContribution->playerSeatNumber == playerSeatNumber) {
				totalDeficit += (pot->betValue - potContribution->contributionAmount);
				contributionFound = true;
				break;
			}
		}
		if (!contributionFound)
			totalDeficit += pot->betValue;
	}

	return totalDeficit;
}

std::vector<unsigned int> PotController::getPotIds() const {

	std::vector<unsigned int> potIds;
	unsigned int previousPotId = 0;
	for (unsigned int p = 0; p < pots.size(); p++) {
		unsigned int potId = pots[p].potNumber;
		if (potId != previousPotId)
			potIds.push_back(potId);
		previousPotId = potId;
	}

	return potIds;
}

std::vector<unsigned int> PotController::getPotContributors(unsigned int potId) const {

	std::set<unsigned int> contributorSeatNumbers;
	for (unsigned int p = 0; p < pots.size(); p++) {
		const Pot* pot = &pots[p];
		if (pot->potNumber == potId) {
			const std::vector<PotContribution>* potContributions = &pot->contributions;
			for (unsigned int pc = 0; pc < potContributions->size(); pc++) {
				contributorSeatNumbers.insert(potContributions->at(pc).playerSeatNumber);
			}
		}
	}

	std::vector<unsigned int> potContributors;
	for (std::set<unsigned int>::iterator it = contributorSeatNumbers.begin(); it != contributorSeatNumbers.end(); ++it) {
		potContributors.push_back(*it);
	}

	return potContributors;
}

unsigned int PotController::getPotValue(unsigned int potId) const {

	unsigned int potValue = 0;
	for (unsigned int p = 0; p < pots.size(); p++) {
		const Pot* pot = &pots[p];
		if (pot->potNumber == potId) {
			const std::vector<PotContribution>* potContributions = &pot->contributions;
			for (unsigned int pc = 0; pc < potContributions->size(); pc++) {
				potValue += potContributions->at(pc).contributionAmount;
			}
		}
	}

	return potValue;
}

unsigned int PotController::getTotalValue() const {

	unsigned int totalValue = 0;
	for (unsigned int p = 0; p < pots.size(); p++) {
		const Pot* pot = &pots[p];
		for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
			totalValue += pot->contributions[pc].contributionAmount;
		}
	}

	return totalValue;
}

unsigned int PotController::getTotalPotContribution(unsigned int seatNumber) const {

	unsigned int totalContribution = 0;
	for (unsigned int p = 0; p < pots.size(); p++) {
		const Pot* pot = &pots[p];
		for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
			const PotContribution* potContribution = &pot->contributions[pc];
			if (potContribution->playerSeatNumber == seatNumber) {
				totalContribution += potContribution->contributionAmount;
				break;
			}
		}
	}

	return totalContribution;
}

bool PotController::getUnevenPotsExist() const {

	for (unsigned int i = 0; i < playerStates->size(); i++) {
		PlayerState* playerState = &playerStates->at(i);
		if (playerState->state != PokerEnums::State::OUT_OF_TOURNAMENT
			&& playerState->state != PokerEnums::State::FOLDED
			&& playerState->state != PokerEnums::State::ALL_IN
		){
			if (getPotDeficit(playerState->seatNumber) > 0)
				return true;
		}
	}

	return false;
}

void PotController::getUiState(Json::Value& potsArray) const {

	struct PotUiRecord {
		unsigned int potValue = 0;
		unsigned int bettingRound1BetValue = 0;
		unsigned int bettingRound2BetValue = 0;
		unsigned int bettingRound3BetValue = 0;
		unsigned int bettingRound4BetValue = 0;
		std::set<unsigned int> potMembers;
	};

	std::map<unsigned int, PotUiRecord> potUiRecords;

	for (unsigned int p = 0; p < pots.size(); p++) {

		const Pot* pot = &pots[p];
		PotUiRecord uiRec;

		if (potUiRecords.find(pot->potNumber) != potUiRecords.end())
			uiRec = potUiRecords[pot->potNumber];

		for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
			const PotContribution* potContribution = &pot->contributions[pc];
			uiRec.potValue += potContribution->contributionAmount;
			uiRec.potMembers.insert(potContribution->playerSeatNumber);

			if (pot->bettingRound == PokerEnums::BettingRound::PRE_FLOP)
				uiRec.bettingRound1BetValue += potContribution->contributionAmount;
			else if (pot->bettingRound == PokerEnums::BettingRound::FLOP)
				uiRec.bettingRound2BetValue += potContribution->contributionAmount;
			else if (pot->bettingRound == PokerEnums::BettingRound::TURN)
				uiRec.bettingRound3BetValue += potContribution->contributionAmount;
			else if (pot->bettingRound == PokerEnums::BettingRound::RIVER)
				uiRec.bettingRound4BetValue += potContribution->contributionAmount;
		}

		potUiRecords[pot->potNumber] = uiRec;
	}

	for (std::map<unsigned int, PotUiRecord>::iterator it = potUiRecords.begin(); it != potUiRecords.end(); ++it) {
		Json::Value potData(Json::objectValue);
		PotUiRecord uiRec = it->second;

		potData["pot_number"] = it->first;
		potData["pot_value"] = uiRec.potValue;
		if(uiRec.bettingRound1BetValue == 0)
			potData["betting_round_1_bet_value"] = Json::Value::null;
		else
			potData["betting_round_1_bet_value"] = uiRec.bettingRound1BetValue;
		if (uiRec.bettingRound2BetValue == 0)
			potData["betting_round_2_bet_value"] = Json::Value::null;
		else
			potData["betting_round_2_bet_value"] = uiRec.bettingRound2BetValue;
		if (uiRec.bettingRound3BetValue == 0)
			potData["betting_round_3_bet_value"] = Json::Value::null;
		else
			potData["betting_round_3_bet_value"] = uiRec.bettingRound3BetValue;
		if (uiRec.bettingRound4BetValue == 0)
			potData["betting_round_4_bet_value"] = Json::Value::null;
		else
			potData["betting_round_4_bet_value"] = uiRec.bettingRound4BetValue;

		std::string potMembersString = "";
		for (std::set<unsigned int>::iterator pmIt = uiRec.potMembers.begin(); pmIt != uiRec.potMembers.end(); ++pmIt) {
			if (pmIt != uiRec.potMembers.begin())
				potMembersString += " ";
			potMembersString += std::to_string(*pmIt);
		}
		potData["pot_members"] = potMembersString;

		potsArray.append(potData);
	}

}

void PotController::contributeToPot(unsigned int seatNumber, unsigned int amount, PokerEnums::BettingRound bettingRound, unsigned int stateId) {

	logger->log(stateId, "player at seat " + std::to_string(seatNumber) + " contributes " + std::to_string(amount) + " to the pot");

	// determine highest pot number for the current betting round
	int overallHighestPotNumber = -1;
	int bettingRoundHighestPotNumber = -1;
	for (unsigned int i = 0; i < pots.size(); i++) {
		Pot* pot = &pots[i];
		if (pot->bettingRound == bettingRound && (int) pot->potNumber > bettingRoundHighestPotNumber)
			bettingRoundHighestPotNumber = pot->potNumber;
		if ((int) pot->potNumber > overallHighestPotNumber)
			overallHighestPotNumber = pot->potNumber;
	}
	if (overallHighestPotNumber == -1)
		overallHighestPotNumber = 1;

	if (bettingRoundHighestPotNumber == -1) {
		// create initial pot for round
		PotContribution potContribution;
		potContribution.playerSeatNumber = seatNumber;
		potContribution.contributionAmount = amount;

		Pot newPot;
		newPot.potNumber = overallHighestPotNumber;
		newPot.bettingRound = bettingRound;
		newPot.betValue = amount;
		newPot.contributions.push_back(potContribution);
		pots.push_back(newPot);
	}
	else {

		// starting from the lowest pot number for this betting round, put in money to cover any deficits

		unsigned int totalPotContribution = amount;
		unsigned int originalPotsSize = pots.size();
		for (unsigned int p = 0; p < originalPotsSize && totalPotContribution != 0; p++) {
			Pot* pot = &pots[p];
			if (pot->bettingRound == bettingRound) {

				PotContribution* playerContributionFound = nullptr;
				unsigned int deficit;
				for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
					PotContribution* potContribution = &pot->contributions[pc];
					if (potContribution->playerSeatNumber == seatNumber) {
						playerContributionFound = potContribution;
						deficit = pot->betValue - potContribution->contributionAmount;
						break;
					}
				}

				if (playerContributionFound == nullptr || deficit != 0) {

					// contribute to the pot
					unsigned int thisPotContribution;
					if (pot->potNumber != bettingRoundHighestPotNumber) {
						// the player is contributing either the total pot deficit or as much remaining money as they have
						thisPotContribution = totalPotContribution < deficit ? totalPotContribution : deficit;
					}
					else {
						// on the highest pot number, contribute all of remaining money from the total contribution
						thisPotContribution = totalPotContribution;
					}

					if (playerContributionFound == nullptr) {
						PotContribution potContribution;
						potContribution.playerSeatNumber = seatNumber;
						potContribution.contributionAmount = thisPotContribution;
						pot->contributions.push_back(potContribution);
						playerContributionFound = &pot->contributions[pot->contributions.size() - 1];
					}
					else {
						playerContributionFound->contributionAmount += thisPotContribution;
					}

					// take this pot contribution away from total amount being contributed
					totalPotContribution -= thisPotContribution;

					// on the highest pot, need to possibly split pots or increase pot bet
					if (pot->potNumber == bettingRoundHighestPotNumber) {

						if (playerContributionFound->contributionAmount < pot->betValue) {
							// player is going all in and cannot cover the current bet, need to split pot
							Pot newPot;
							newPot.potNumber = bettingRoundHighestPotNumber + 1;
							newPot.bettingRound = bettingRound;
							newPot.betValue = pot->betValue - playerContributionFound->contributionAmount;
							pots.push_back(newPot);

							// move balance of all other players in pot to new pot
							for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
								PotContribution* potContribution = &pot->contributions[pc];
								if (potContribution->playerSeatNumber != seatNumber && potContribution->contributionAmount > playerContributionFound->contributionAmount) {
									PotContribution newPotContribution;
									newPotContribution.playerSeatNumber = potContribution->playerSeatNumber;
									newPotContribution.contributionAmount = potContribution->contributionAmount - playerContributionFound->contributionAmount;
									newPot.contributions.push_back(newPotContribution);
									potContribution->contributionAmount = playerContributionFound->contributionAmount;
								}
							}

							// update the bet value on the old highest pot number to the contribution of the player going all in
							pot->betValue = playerContributionFound->contributionAmount;
						}
						else if (playerContributionFound->contributionAmount > pot->betValue) {
							// player is increasing the bet value.  If any other contributors to this pot are all in, need to split pot
							bool sidePotNeeded = false;
							for (unsigned int pc = 0; pc < pot->contributions.size(); pc++) {
								PotContribution* potContribution = &pot->contributions[pc];
								if (potContribution->playerSeatNumber != seatNumber && playerStates->at(potContribution->playerSeatNumber - 1).state == PokerEnums::State::ALL_IN) {
									sidePotNeeded = true;
									break;
								}
							}

							if (sidePotNeeded) {
								// create new pot
								unsigned int potBalance = playerContributionFound->contributionAmount - pot->betValue;
								Pot newPot;
								newPot.potNumber = bettingRoundHighestPotNumber + 1;
								newPot.bettingRound = bettingRound;
								newPot.betValue = potBalance;
								pots.push_back(newPot);

								// move balance of player's contribution into new pot
								PotContribution newPotContribution;
								newPotContribution.playerSeatNumber = seatNumber;
								newPotContribution.contributionAmount = potBalance;
								newPot.contributions.push_back(newPotContribution);
								
								// update the player contribution on the old highest pot number to the contribution of the player going all in
								playerContributionFound->contributionAmount = pot->betValue;
							}
							else {
								// new pot not needed, just increase bet value of highest pot
								pot->betValue = playerContributionFound->contributionAmount;
							}
						}
					}
				}
			}
		}
	}

	// remove money from player's stack and flag all in state when needed
	PlayerState* playerState = &playerStates->at(seatNumber - 1);
	playerState->money -= amount;
	playerState->totalMoneyPlayed += amount;
	if (playerState->money == 0) {
		playerState->state = PokerEnums::State::ALL_IN;
		playerState->timesAllIn++;
	}

	issueApplicablePotRefunds(stateId);
}

void PotController::issueApplicablePotRefunds(unsigned int stateId) {

	// if there are any pots that only have one contributor and all the other active players are all in, refund to the
	// pot contributor and delete the pot
	struct PotRefund {
		unsigned int potNumber;
		unsigned int soleContributorSeatNumber;
		unsigned int potValue;
	};

	std::vector<PotRefund> potsToRefund;
	std::vector<unsigned int> potIds = getPotIds();
	for (unsigned int p = 0; p < potIds.size(); p++) {
		unsigned int potId = potIds[p];
		std::vector<unsigned int> potContributors = getPotContributors(potId);
		if (potContributors.size() == 1) {

			PotRefund refund;
			refund.soleContributorSeatNumber = potContributors[0];
			unsigned int activePeerPlayerCount = 0;
			unsigned int allInPeerPlayerCount = 0;

			for (unsigned int ps = 0; ps < playerStates->size(); ps++) {
				PlayerState* playerState = &playerStates->at(ps);
				if (playerState->seatNumber != refund.soleContributorSeatNumber) {
					if (playerState->state != PokerEnums::State::OUT_OF_TOURNAMENT && playerState->state != PokerEnums::State::FOLDED)
						activePeerPlayerCount++;
					if (playerState->state == PokerEnums::State::ALL_IN)
						allInPeerPlayerCount++;
				}
			}

			if (activePeerPlayerCount == allInPeerPlayerCount) {
				refund.potNumber = potId;
				refund.potValue = getPotValue(potId);
				potsToRefund.push_back(refund);
			}
		}
	}

	for (unsigned int i = 0; i < potsToRefund.size(); i++) {
		PotRefund* refund = &potsToRefund[i];

		logger->log(stateId, "refunding " + std::to_string(refund->potValue) + " back to player at seat "
			+ std::to_string(refund->soleContributorSeatNumber) + " from pot " + std::to_string(refund->potNumber));
		PlayerState* ps = &playerStates->at(refund->soleContributorSeatNumber - 1);
		if (ps->state == PokerEnums::State::ALL_IN)
			ps->state = PokerEnums::State::RAISED;
		ps->money += refund->potValue;
		ps->totalMoneyPlayed -= refund->potValue;
		
		for (int j = pots.size() - 1; j >= 0; j--) {
			if (pots[j].potNumber == refund->potNumber)
				pots.erase(pots.begin() + j);
		}
	}
}

void PotController::issueDefaultPotWins(unsigned int stateId) {

	// if all non - all in players but one player fold on a given pot, by default the non - folded contributor wins the pot
	struct DefaultPotWin {
		unsigned int potNumber;
		unsigned int winnerSeatNumber;
		unsigned int potValue;
	};

	std::vector<DefaultPotWin> defaultPotWins;
	std::vector<unsigned int> potIds = getPotIds();

	for (unsigned int p = 0; p < potIds.size(); p++) {
		unsigned int potId = potIds[p];
		std::vector<unsigned int> potContributors = getPotContributors(potId);

		unsigned int foldedPlayerCount = 0;
		unsigned int totalPlayerCount = 0;
		unsigned int soleNonFoldedSeatNumber;
		for (unsigned int pc = 0; pc < potContributors.size(); pc++) {
			unsigned int playerSeatNumber = potContributors[pc];
			if (playerStates->at(playerSeatNumber - 1).state == PokerEnums::State::FOLDED)
				foldedPlayerCount++;
			else
				soleNonFoldedSeatNumber = playerSeatNumber;

			totalPlayerCount++;
		}

		if (totalPlayerCount - foldedPlayerCount == 1) {

			// determine if there are any other players that are eligible to compete for this pot
			bool eligibleCompetitorsExist = false;
			for (unsigned int ps = 0; ps < playerStates->size(); ps++) {
				if (ps + 1 != soleNonFoldedSeatNumber) {
					PokerEnums::State playerState = playerStates->at(ps).state;
					if (playerState != PokerEnums::State::OUT_OF_TOURNAMENT
						&& playerState != PokerEnums::State::ALL_IN
						&& playerState != PokerEnums::State::FOLDED) {
						eligibleCompetitorsExist = true;
						break;
					}
				}
			}

			if (!eligibleCompetitorsExist) {
				DefaultPotWin dpw;
				dpw.potNumber = potId;
				dpw.winnerSeatNumber = soleNonFoldedSeatNumber;
				dpw.potValue = getPotValue(potId);
				defaultPotWins.push_back(dpw);
			}
		}
	}

	for (unsigned int i = 0; i < defaultPotWins.size(); i++) {
		DefaultPotWin* dpw = &defaultPotWins[i];

		logger->log(stateId, "by default, player at seat " + std::to_string(dpw->winnerSeatNumber) + " wins "
			+ std::to_string(dpw->potValue) + " from pot " + std::to_string(dpw->potNumber));

		PlayerState* ps = &playerStates->at(dpw->winnerSeatNumber - 1);
		if (ps->state == PokerEnums::State::ALL_IN)
			ps->state = PokerEnums::State::RAISED;
		ps->money += dpw->potValue;
		ps->totalMoneyWon += dpw->potValue;

		for (int j = pots.size() - 1; j >= 0; j--) {
			if (pots[j].potNumber == dpw->potNumber)
				pots.erase(pots.begin() + j);
		}
	}

}

void PotController::insertStateLog(unsigned int stateId) {

	std::string potProcCall = "BEGIN pkg_poker_ai.insert_pot_log(";
	potProcCall.append("p_state_id             => :stateId, ");
	potProcCall.append("p_pot_number           => :potNumber, ");
	potProcCall.append("p_betting_round_number => :bettingRoundNumber, ");
	potProcCall.append("p_bet_value            => :betValue");
	potProcCall.append("); END;");
	ocilib::Statement potSt(con);

	std::string potContributionProcCall = "BEGIN pkg_poker_ai.insert_pot_contribution_log(";
	potContributionProcCall.append("p_state_id             => :stateId, ");
	potContributionProcCall.append("p_pot_number           => :potNumber, ");
	potContributionProcCall.append("p_betting_round_number => :bettingRoundNumber, ");
	potContributionProcCall.append("p_player_seat_number   => :playerSeatNumber, ");
	potContributionProcCall.append("p_pot_contribution     => :potContribution");
	potContributionProcCall.append("); END;");
	ocilib::Statement potContributionSt(con);

	for (unsigned int i = 0; i < pots.size(); i++) {
		Pot* pot = &pots[i];
		potSt.Prepare(potProcCall);
		potSt.Bind("stateId", stateId, ocilib::BindInfo::In);
		potSt.Bind("potNumber", pot->potNumber, ocilib::BindInfo::In);
		unsigned int bettingRoundNumber = (unsigned int) pot->bettingRound;
		potSt.Bind("bettingRoundNumber", bettingRoundNumber, ocilib::BindInfo::In);
		potSt.Bind("betValue", pot->betValue, ocilib::BindInfo::In);
		potSt.ExecutePrepared();

		for (unsigned int j = 0; j < pot->contributions.size(); j++) {
			PotContribution* potContribution = &pot->contributions[j];
			potContributionSt.Prepare(potContributionProcCall);
			potContributionSt.Bind("stateId", stateId, ocilib::BindInfo::In);
			potContributionSt.Bind("potNumber", pot->potNumber, ocilib::BindInfo::In);
			potContributionSt.Bind("bettingRoundNumber", bettingRoundNumber, ocilib::BindInfo::In);
			potContributionSt.Bind("playerSeatNumber", potContribution->playerSeatNumber, ocilib::BindInfo::In);
			potContributionSt.Bind("potContribution", potContribution->contributionAmount, ocilib::BindInfo::In);
			potContributionSt.ExecutePrepared();
		}
	}
	
}
