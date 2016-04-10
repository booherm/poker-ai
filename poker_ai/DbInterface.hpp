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
	void initGame(unsigned int smallBlindSeatNumber, unsigned int smallBlindAmount, unsigned int bigBlindAmount);
	void getPlayerState(Json::Value& playerState);

private:

	ocilib::Connection con;

};

#endif
