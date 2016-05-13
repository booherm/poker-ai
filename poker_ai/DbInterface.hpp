#ifndef DBINTERFACE_HPP
#define DBINTERFACE_HPP

#include <ocilib.hpp>
#include "json.hpp"

class DbInterface {
public:
	DbInterface();
	~DbInterface();
	void initTournament(unsigned int playerCount, unsigned int buyInAmount, unsigned int smallBlindAmount, unsigned int bigBlindAmount);
	void stepPlay(unsigned int smallBlindAmount, unsigned int bigBlindAmount, unsigned int playerMove, unsigned int playerMoveAmount);
	void getUiState(Json::Value& uiData);

private:

	ocilib::Connection con;
	unsigned int lastLogRecordNumber;

};

#endif
