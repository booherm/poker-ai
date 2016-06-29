#ifndef TOURNAMENTSTEPPERDBINTERFACE_HPP
#define TOURNAMENTSTEPPERDBINTERFACE_HPP

#include <ocilib.hpp>
#include "json.hpp"

class TournamentStepperDbInterface {
public:
	TournamentStepperDbInterface(const std::string& databaseId);
	~TournamentStepperDbInterface();
	unsigned int initTournament(const std::string& tournamentMode, unsigned int playerCount, unsigned int buyInAmount);
	unsigned int stepPlay(unsigned int stateId, unsigned int smallBlindAmount, const std::string& playerMove, unsigned int playerMoveAmount);
	unsigned int editCard(unsigned int stateId, const std::string& cardType, unsigned int seatNumber, unsigned int cardSlot, unsigned int cardId);
	void getUiState(unsigned int stateId, Json::Value& uiData);
	unsigned int getPreviousStateId(unsigned int stateId);
	unsigned int getNextStateId(unsigned int stateId);

private:
	ocilib::Connection con;
};

#endif
