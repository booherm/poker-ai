#include "PokerAiController.hpp"

PokerAiController::PokerAiController() {

	databaseId = "ORACLENODE1";
	tournamentStepperDbInterface = new TournamentStepperDbInterface(databaseId);
	gaEvolverController = new GaEvolverController(databaseId);

	uiWindow = new PokerAiUiWindow(tournamentStepperDbInterface, gaEvolverController);
	uiWindow->threadStart();

	uiWindow->threadJoin();
}

PokerAiController::~PokerAiController() {
	delete uiWindow;
	delete tournamentStepperDbInterface;
	delete gaEvolverController;
}
