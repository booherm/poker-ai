#include "GaEvolverController.hpp"

GaEvolverController::GaEvolverController(const std::string& databaseId, PythonManager* pythonManager, StrategyManager* strategyManager) {
	this->databaseId = databaseId;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
	con.Open(databaseId, "poker_ai", "poker_ai");
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
	procCall.append("p_trial_id                  => :trialId, ");
	procCall.append("p_generation_size           => :generationSize, ");
	procCall.append("p_max_generations           => :maxGenerations, ");
	procCall.append("p_crossover_rate            => :crossoverRate, ");
	procCall.append("p_crossover_point           => :crossoverPoint, ");
	procCall.append("p_mutation_rate             => :mutationRate, ");
	procCall.append("p_players_per_tournament    => :playersPerTournament, ");
	procCall.append("p_tournament_play_count     => :tournamentPlayCount, ");
	procCall.append("p_tournament_buy_in         => :tournamentBuyIn, ");
	procCall.append("p_initial_small_blind_value => :initialSmallBlindValue, ");
	procCall.append("p_double_blinds_interval    => :doubleBlindsInterval, ");
	procCall.append("p_current_generation        => :currentGeneration");
	procCall.append("); END; ");

	ocilib::Statement st(con);
	st.Prepare(procCall);
	st.Bind("trialId", trialId, ocilib::BindInfo::In);
	st.Bind("generationSize", generationSize, ocilib::BindInfo::In);
	st.Bind("maxGenerations", maxGenerations, ocilib::BindInfo::In);
	st.Bind("crossoverRate", crossoverRate, ocilib::BindInfo::In);
	st.Bind("crossoverPoint", crossoverPoint, ocilib::BindInfo::In);
	st.Bind("mutationRate", mutationRate, ocilib::BindInfo::In);
	st.Bind("playersPerTournament", playersPerTournament, ocilib::BindInfo::In);
	st.Bind("tournamentPlayCount", tournamentPlayCount, ocilib::BindInfo::In);
	st.Bind("tournamentBuyIn", tournamentBuyIn, ocilib::BindInfo::In);
	st.Bind("initialSmallBlindValue", initialSmallBlindValue, ocilib::BindInfo::In);
	st.Bind("doubleBlindsInterval", doubleBlindsInterval, ocilib::BindInfo::In);
	st.Bind("currentGeneration", currentGeneration, ocilib::BindInfo::In);
	st.ExecutePrepared();

	if (currentGeneration == 1)
		createInitialGeneration(trialId, generationSize);

	// start generation conroller thread
	GaEvolverWorker* generationWorker = new GaEvolverWorker(
		databaseId,
		pythonManager,
		trialId,
		"GENERATION_WORKER",
		GaEvolverWorker::GaEvoloverWorkerType::GENERATION_RUNNER,
		strategyManager
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
	for (unsigned int i = 0; i < evolverWorkers.size(); i++) {
		delete evolverWorkers[i];
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
	for (unsigned int i = 0; i < evolverWorkers.size(); i++) {
		delete evolverWorkers[i];
	}

	logger.log(0, "evolution trial " + std::to_string(trialId) + " complete");
}

void GaEvolverController::startTournamentWorkers(unsigned int trialId) {
	evolverWorkers.resize(workerCount);
	for (unsigned int i = 0; i < workerCount; i++) {
		evolverWorkers[i] = new GaEvolverWorker(
			databaseId,
			pythonManager,
			trialId,
			"TOURNAMENT_WORKER_" + std::to_string(i),
			GaEvolverWorker::GaEvoloverWorkerType::TOURNAMENT_RUNNER,
			strategyManager
		);
		evolverWorkers[i]->startThread();
	}
}

void GaEvolverController::joinTournamentWorkers() {
	for (unsigned int i = 0; i < workerCount; i++) {
		evolverWorkers[i]->threadJoin();
	}
}

GaEvolverController::~GaEvolverController() {
	con.Close();
}

void GaEvolverController::createInitialGeneration(unsigned int trialId, unsigned int generationSize) {

	logger.log(0, "creating initial generation");

	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->generateRandomStrategy();
	}

	// enqueue tournaments
	logger.log(0, "enqueing tournaments");
	std::string procCall = "BEGIN pkg_ga_evolver.enqueue_tournaments(";
	procCall.append("p_trial_id => :trialId");
	procCall.append("); END; ");

	ocilib::Statement st(con);
	st.Prepare(procCall);
	st.Bind("trialId", trialId, ocilib::BindInfo::In);
	st.ExecutePrepared();

}