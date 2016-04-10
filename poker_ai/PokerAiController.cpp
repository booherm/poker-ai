#include "PokerAiController.hpp"

PokerAiController::PokerAiController() {

	dbInterface = new DbInterface();

	uiWindow = new PokerAiUiWindow(dbInterface);
	uiWindow->threadStart();

	uiWindow->threadJoin();
}

PokerAiController::~PokerAiController() {
	delete uiWindow;
	delete dbInterface;
}
