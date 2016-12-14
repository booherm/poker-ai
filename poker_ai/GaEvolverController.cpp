#include "GaEvolverController.hpp"

GaEvolverController::GaEvolverController(
	DbConnectionManager* dbConnectionManager,
	PythonManager* pythonManager,
	StrategyManager* strategyManager
) {
	this->dbConnectionManager = dbConnectionManager;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
	con = dbConnectionManager->getConnection();
	logger.initialize(con);
}

void GaEvolverController::performEvolutionTrial(
	const std::string& machineId,
	unsigned int trialId,
	unsigned int controlGeneration,
	unsigned int startFromGenerationNumber,
	unsigned int generationSize,
	unsigned int maxGenerations,
	float crossoverRate,
	int crossoverPoint,
	unsigned int carryOverCount,
	float mutationRate,
	unsigned int playersPerTournament,
	unsigned int tournamentWorkerThreads,
	unsigned int tournamentPlayCount,
	unsigned int tournamentBuyIn,
	unsigned int initialSmallBlindValue,
	unsigned int doubleBlindsInterval
) {

	this->machineId = machineId;
	logger.log(0, machineId + ": begin evolution trial " + std::to_string(trialId));

	workerCount = tournamentWorkerThreads;
	unsigned int currentGeneration = startFromGenerationNumber == 0 ? 1 : startFromGenerationNumber;

	std::string procCall = "BEGIN pkg_ga_evolver.upsert_evolution_trial(";
	procCall.append("p_trial_id                  => :1, ");
	procCall.append("p_control_generation        => :2, ");
	procCall.append("p_generation_size           => :3, ");
	procCall.append("p_max_generations           => :4, ");
	procCall.append("p_crossover_rate            => :5, ");
	procCall.append("p_crossover_point           => :6, ");
	procCall.append("p_carry_over_count          => :7, ");
	procCall.append("p_mutation_rate             => :8, ");
	procCall.append("p_players_per_tournament    => :9, ");
	procCall.append("p_tournament_play_count     => :10, ");
	procCall.append("p_tournament_buy_in         => :11, ");
	procCall.append("p_initial_small_blind_value => :12, ");
	procCall.append("p_double_blinds_interval    => :13, ");
	procCall.append("p_current_generation        => :14");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);

	statement->setUInt(1, trialId);
	statement->setUInt(2, controlGeneration);
	statement->setUInt(3, generationSize);
	statement->setUInt(4, maxGenerations);
	statement->setFloat(5, crossoverRate);
	statement->setUInt(6, crossoverPoint);
	statement->setUInt(7, carryOverCount);
	statement->setFloat(8, mutationRate);
	statement->setUInt(9, playersPerTournament);
	statement->setUInt(10, tournamentPlayCount);
	statement->setUInt(11, tournamentBuyIn);
	statement->setUInt(12, initialSmallBlindValue);
	statement->setUInt(13, doubleBlindsInterval);
	statement->setUInt(14, currentGeneration);
	statement->execute();
	con->terminateStatement(statement);

	if (currentGeneration == 1) {
		createControlGeneration(trialId, playersPerTournament, generationSize);
		createInitialGeneration(trialId, generationSize);
	}

	// start generation conroller thread
	GaEvolverGenerationWorker* generationWorker = new GaEvolverGenerationWorker(
		dbConnectionManager,
		trialId,
		machineId + "_GENERATION_WORKER",
		strategyManager,
		currentGeneration,
		true
	);
	logger.log(0, machineId + ": starting generation worker thread");
	generationWorker->startThread();

	// start tournament worker threads
	logger.log(0, machineId + ": starting tournament worker threads");
	startTournamentWorkers(trialId, controlGeneration);

	// block until everyone is done
	joinTournamentWorkers();
	generationWorker->threadJoin();

	// cleanup worker threads
	for (unsigned int i = 0; i < tournamentWorkers.size(); i++) {
		delete tournamentWorkers[i];
	}
	delete generationWorker;

	logger.log(0, machineId + ": evolution trial " + std::to_string(trialId) + " complete");
}

void GaEvolverController::joinEvolutionTrial(const std::string& machineId, unsigned int trialId, unsigned int tournamentWorkerThreads) {

	logger.log(0, machineId + ": joining evolution trial " + std::to_string(trialId));
	this->machineId = machineId;

	// look up control generation
	std::string procCall = "BEGIN :1 := pkg_ga_evolver.get_control_generation(";
	procCall.append("p_trial_id => :2");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->registerOutParam(1, oracle::occi::OCCIUNSIGNED_INT);
	statement->setUInt(2, trialId);
	statement->execute();
	unsigned int controlGeneration = statement->getUInt(1);
	con->terminateStatement(statement);

	// start tournament worker threads
	workerCount = tournamentWorkerThreads;
	startTournamentWorkers(trialId, controlGeneration);

	// block until everyone is done
	joinTournamentWorkers();

	// cleanup worker threads
	for (unsigned int i = 0; i < tournamentWorkers.size(); i++) {
		delete tournamentWorkers[i];
	}

	logger.log(0, machineId + ": evolution trial " + std::to_string(trialId) + " complete");
}

void GaEvolverController::startTournamentWorkers(unsigned int trialId, unsigned int controlGeneration) {
	tournamentWorkers.resize(workerCount);
	for (unsigned int i = 0; i < workerCount; i++) {
		tournamentWorkers[i] = new GaEvolverTournamentWorker(
			dbConnectionManager,
			pythonManager,
			trialId,
			controlGeneration,
			machineId + "_TOURNAMENT_WORKER_THREAD_" + std::to_string(i),
			strategyManager,
			true
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
	dbConnectionManager->releaseConnection(con);
}

void GaEvolverController::createControlGeneration(unsigned int trialId, unsigned int playersPerTournament, unsigned int generationSize) {

	logger.log(0, machineId + ": creating control generation");

	unsigned int controlGenerationSize = (playersPerTournament - 1) * generationSize;
	for (unsigned int i = 0; i < controlGenerationSize; i++) {
		strategyManager->generateRandomStrategy(trialId, 0);
	}
	strategyManager->setGenerationLoaded(0);

}

void GaEvolverController::createInitialGeneration(unsigned int trialId, unsigned int generationSize) {

	logger.log(0, machineId + ": creating initial generation");

	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->generateRandomStrategy(trialId, 1);
	}
	strategyManager->setGenerationLoaded(1);

	// enqueue tournaments
	logger.log(0, machineId + ": enqueing tournaments");
	std::string procCall = "BEGIN pkg_ga_evolver.enqueue_tournaments(";
	procCall.append("p_trial_id => :1");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->execute();
	con->terminateStatement(statement);

}
