#include "GaEvolverController.hpp"

GaEvolverController::GaEvolverController(oracle::occi::StatelessConnectionPool* connectionPool, PythonManager* pythonManager, StrategyManager* strategyManager) {
	this->connectionPool = connectionPool;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
	con = connectionPool->getConnection();
	logger.initialize(con);
}

void GaEvolverController::performEvolutionTrial(
	unsigned int trialId,
	unsigned int startFromGenerationNumber,
	unsigned int generationSize,
	unsigned int maxGenerations,
	float crossoverRate,
	int crossoverPoint,
	float mutationRate,
	unsigned int playersPerTournament,
	unsigned int tournamentWorkerThreads,
	unsigned int tournamentPlayCount,
	unsigned int tournamentBuyIn,
	unsigned int initialSmallBlindValue,
	unsigned int doubleBlindsInterval
) {

	logger.log(0, "begin evolution trial " + std::to_string(trialId));

	workerCount = tournamentWorkerThreads;
	unsigned int currentGeneration = startFromGenerationNumber == 0 ? 1 : startFromGenerationNumber;

	std::string procCall = "BEGIN pkg_ga_evolver.insert_evolution_trial(";
	procCall.append("p_trial_id                  => :1, ");
	procCall.append("p_generation_size           => :2, ");
	procCall.append("p_max_generations           => :3, ");
	procCall.append("p_crossover_rate            => :4, ");
	procCall.append("p_crossover_point           => :5, ");
	procCall.append("p_mutation_rate             => :6, ");
	procCall.append("p_players_per_tournament    => :7, ");
	procCall.append("p_tournament_play_count     => :8, ");
	procCall.append("p_tournament_buy_in         => :9, ");
	procCall.append("p_initial_small_blind_value => :10, ");
	procCall.append("p_double_blinds_interval    => :11, ");
	procCall.append("p_current_generation        => :12");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);

	statement->setUInt(1, trialId);
	statement->setUInt(2, generationSize);
	statement->setUInt(3, maxGenerations);
	statement->setFloat(4, crossoverRate);
	statement->setUInt(5, crossoverPoint);
	statement->setFloat(6, mutationRate);
	statement->setUInt(7, playersPerTournament);
	statement->setUInt(8, tournamentPlayCount);
	statement->setUInt(9, tournamentBuyIn);
	statement->setUInt(10, initialSmallBlindValue);
	statement->setUInt(11, doubleBlindsInterval);
	statement->setUInt(12, currentGeneration);
	statement->execute();
	con->terminateStatement(statement);

	if (currentGeneration == 1)
		createInitialGeneration(trialId, generationSize);

	// start generation conroller thread
	GaEvolverGenerationWorker* generationWorker = new GaEvolverGenerationWorker(
		connectionPool,
		trialId,
		"GENERATION_WORKER",
		strategyManager,
		currentGeneration,
		false
	);
	logger.log(0, "starting generation worker thread");
	generationWorker->startThread();

	// start tournament worker threads
	logger.log(0, "starting tournament worker threads");
	startTournamentWorkers(trialId);

	// block until everyone is done
	joinTournamentWorkers();
	generationWorker->threadJoin();

	// cleanup worker threads
	for (unsigned int i = 0; i < tournamentWorkers.size(); i++) {
		delete tournamentWorkers[i];
	}
	delete generationWorker;

	logger.log(0, "evolution trial " + std::to_string(trialId) + " complete");
}

void GaEvolverController::joinEvolutionTrial(unsigned int trialId, unsigned int tournamentWorkerThreads) {

	logger.log(0, "joining evolution trial " + std::to_string(trialId));

	// start tournament worker threads
	workerCount = tournamentWorkerThreads;
	startTournamentWorkers(trialId);

	// block until everyone is done
	joinTournamentWorkers();

	// cleanup worker threads
	for (unsigned int i = 0; i < tournamentWorkers.size(); i++) {
		delete tournamentWorkers[i];
	}

	logger.log(0, "evolution trial " + std::to_string(trialId) + " complete");
}

void GaEvolverController::startTournamentWorkers(unsigned int trialId) {
	tournamentWorkers.resize(workerCount);
	for (unsigned int i = 0; i < workerCount; i++) {
		tournamentWorkers[i] = new GaEvolverTournamentWorker(
			connectionPool,
			pythonManager,
			trialId,
			"TOURNAMENT_WORKER_" + std::to_string(i),
			strategyManager,
			false
		);
		tournamentWorkers[i]->startThread();
	}
}

void GaEvolverController::joinTournamentWorkers() {
	for (unsigned int i = 0; i < workerCount; i++) {
		tournamentWorkers[i]->threadJoin();
	}
}

GaEvolverController::~GaEvolverController() {
	connectionPool->releaseConnection(con);
}

void GaEvolverController::createInitialGeneration(unsigned int trialId, unsigned int generationSize) {

	logger.log(0, "creating initial generation");

	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->generateRandomStrategy(1);
	}

	// enqueue tournaments
	logger.log(0, "enqueing tournaments");
	std::string procCall = "BEGIN pkg_ga_evolver.enqueue_tournaments(";
	procCall.append("p_trial_id => :1");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->execute();
	con->terminateStatement(statement);
}