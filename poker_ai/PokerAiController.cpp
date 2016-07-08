#include "PokerAiController.hpp"

PokerAiController::PokerAiController() {

	srand((unsigned int) time(NULL));

	databaseId = "ORACLENODE1";
	ocilib::Environment::Initialize(ocilib::Environment::EnvironmentFlagsValues::Threaded);

	tournamentController = new TournamentController(databaseId);
	gaEvolverController = new GaEvolverController(databaseId);

	uiWindow = new PokerAiUiWindow(tournamentController, gaEvolverController);
	uiWindow->threadStart();

	uiWindow->threadJoin();
}

PokerAiController::~PokerAiController() {
	delete uiWindow;
	delete tournamentController;
	delete gaEvolverController;
}
