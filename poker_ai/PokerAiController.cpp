#include "PokerAiController.hpp"
#include <occi.h>

PokerAiController::PokerAiController() {

	// init db
	oracle::occi::Environment* env = oracle::occi::Environment::createEnvironment(oracle::occi::Environment::THREADED_MUTEXED);

	oracle::occi::StatelessConnectionPool* connectionPool = env->createStatelessConnectionPool("C##POKER_AI", "poker_ai",
		"ORACLENODE2", 50, 5, 5, oracle::occi::StatelessConnectionPool::HOMOGENEOUS);

	// debug
	//oracle::occi::StatelessConnectionPool* connectionPool = env->createStatelessConnectionPool("POKER_AI", "poker_ai",
//		"ORACLENODE", 50, 5, 5, oracle::occi::StatelessConnectionPool::HOMOGENEOUS);

	// init main components
	pythonManager = new PythonManager;
	strategyManager = new StrategyManager;
	strategyManager->initialize(connectionPool, pythonManager);
	tournamentController = new TournamentController;
	tournamentController->initialize(connectionPool, pythonManager, strategyManager);
	gaEvolverController = new GaEvolverController(connectionPool, pythonManager, strategyManager);

	// init and start ui window
	uiWindow = new PokerAiUiWindow(tournamentController, gaEvolverController);
	uiWindow->threadStart();

	// block until the ui window closes
	uiWindow->threadJoin();

	// cleanup main components
	delete uiWindow;
	delete tournamentController;
	delete gaEvolverController;
	delete strategyManager;
	delete pythonManager;

	// cleanup db
	env->terminateStatelessConnectionPool(connectionPool);
	oracle::occi::Environment::terminateEnvironment(env);
}
