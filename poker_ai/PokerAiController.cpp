#include "PokerAiController.hpp"
#include "DbConnectionManager.hpp"

PokerAiController::PokerAiController() {

	// init db
	//std::string userId = "C##POKER_AI_DEV"; // dev
	std::string userId = "C##POKER_AI"; // live
	DbConnectionManager* dbConnectionManager = new DbConnectionManager("ORACLENODE2", userId, "poker_ai");

	// init main components
	pythonManager = new PythonManager;
	strategyManager = new StrategyManager;
	strategyManager->initialize(dbConnectionManager, pythonManager);
	tournamentResultCollector = new TournamentResultCollector;
	tournamentResultCollector->initialize(dbConnectionManager);
	tournamentController = new TournamentController;
	tournamentController->initialize(dbConnectionManager, pythonManager, strategyManager, tournamentResultCollector);
	gaEvolverController = new GaEvolverController(dbConnectionManager, pythonManager, strategyManager);

	// init and start ui window
	uiWindow = new PokerAiUiWindow(tournamentController, gaEvolverController);
	uiWindow->threadStart();

	// block until the ui window closes
	uiWindow->threadJoin();

	// cleanup main components
	delete uiWindow;
	delete tournamentController;
	delete tournamentResultCollector;
	delete gaEvolverController;
	delete strategyManager;
	delete pythonManager;

	// cleanup db
	delete dbConnectionManager;
}
