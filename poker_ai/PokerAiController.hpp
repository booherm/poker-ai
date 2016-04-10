#ifndef POKERAICONTROLLER_HPP
#define POKERAICONTROLLER_HPP

#include "PokerAiUiWindow.hpp"
#include "DbInterface.hpp"

class PokerAiController {
public:
	PokerAiController();
	~PokerAiController();
private:
	PokerAiUiWindow* uiWindow;
	DbInterface* dbInterface;

};

#endif