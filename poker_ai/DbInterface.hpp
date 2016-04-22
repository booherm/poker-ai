#ifndef DBINTERFACE_HPP
#define DBINTERFACE_HPP

#include <ocilib.hpp>
#include "json.hpp"

class DbInterface {
public:
	DbInterface();
	~DbInterface();
	void test();
	void initTournament(unsigned int playerCount, unsigned int buyInAmount);
	void stepPlay(unsigned int smallBlindAmount, unsigned int bigBlindAmount);
	void getUiState(Json::Value& uiData);

private:

	ocilib::Connection con;
	unsigned int lastLogRecordNumber;

};

#endif
