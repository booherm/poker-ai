#ifndef DBINTERFACE_HPP
#define DBINTERFACE_HPP

#include <ocilib.hpp>
#include "json.hpp"

class DbInterface {
public:
	DbInterface();
	~DbInterface();
	void initTournament(const std::string& tournamentMode, unsigned int playerCount, unsigned int buyInAmount);
	void stepPlay(unsigned int smallBlindAmount, const std::string& playerMove, unsigned int playerMoveAmount);
	void loadState(unsigned int stateId);
	void loadPreviousState(unsigned int stateId);
	void loadNextState(unsigned int stateId);
	void editCard(const std::string& cardType, unsigned int seatNumber, unsigned int cardSlot, unsigned int cardId);
	void getUiState(Json::Value& uiData);

private:
	ocilib::Connection con;
};

#endif
