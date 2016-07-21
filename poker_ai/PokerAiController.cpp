#include "PokerAiController.hpp"

PokerAiController::PokerAiController() {

	srand((unsigned int) time(NULL));

	databaseId = "ORACLENODE1";
	ocilib::Environment::Initialize(ocilib::Environment::EnvironmentFlagsValues::Threaded);

	pythonManager = new PythonManager;
	strategyManager = new StrategyManager;
	strategyManager->initialize(databaseId, pythonManager);

	tournamentController = new TournamentController;
	tournamentController->initialize(databaseId, pythonManager, strategyManager);
	gaEvolverController = new GaEvolverController(databaseId, pythonManager, strategyManager);

	uiWindow = new PokerAiUiWindow(tournamentController, gaEvolverController);
	uiWindow->threadStart();

	uiWindow->threadJoin();
}

PokerAiController::~PokerAiController() {
	delete uiWindow;
	delete tournamentController;
	delete gaEvolverController;
	delete strategyManager;
	delete pythonManager;
}
