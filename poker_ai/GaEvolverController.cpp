#include "GaEvolverController.hpp"

GaEvolverController::GaEvolverController(const std::string& databaseId) {
	this->databaseId = databaseId;
	con.Open(databaseId, "poker_ai", "poker_ai");
}

void GaEvolverController::performEvolutionTrial(
	const std::string& trialId,
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

	workerCount = tournamentWorkerThreads;

	try
	{
		std::string procCall = "BEGIN pkg_ga_evolver.init_evolution_trial(";
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
		procCall.append("p_double_blinds_interval    => :doubleBlindsInterval");
		procCall.append("); END; ");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		ocilib::ostring trialIdOstring(trialId);
		st.Bind("trialId", trialIdOstring, static_cast<unsigned int>(trialIdOstring.size()), ocilib::BindInfo::In);
		st.Bind("generationSize", generationSize, ocilib::BindInfo::In);
		st.Bind("maxGenerations", maxGenerations, ocilib::BindInfo::In);
		st.Bind("crossoverRate", crossoverRate, ocilib::BindInfo::In);
		st.Bind("crossoverPoint", crossoverPoint, ocilib::BindInfo::In);
		if (crossoverPoint == -1)
			st.GetBind("crossoverPoint").SetDataNull(true, 1);
		st.Bind("mutationRate", mutationRate, ocilib::BindInfo::In);
		if(mutationRate == -1)
			st.GetBind("mutationRate").SetDataNull(true, 1);
		st.Bind("playersPerTournament", playersPerTournament, ocilib::BindInfo::In);
		st.Bind("tournamentPlayCount", tournamentPlayCount, ocilib::BindInfo::In);
		st.Bind("tournamentBuyIn", tournamentBuyIn, ocilib::BindInfo::In);
		st.Bind("initialSmallBlindValue", initialSmallBlindValue, ocilib::BindInfo::In);
		st.Bind("doubleBlindsInterval", doubleBlindsInterval, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}

	startTournamentWorkers(trialId);

	GaEvolverWorker* generationWorker = new GaEvolverWorker(databaseId, trialId, "GENERATION_WORKER", GaEvolverWorker::GaEvoloverWorkerType::GENERATION_RUNNER);
	generationWorker->startThread();

	joinTournamentWorkers();
	generationWorker->threadJoin();

	for (unsigned int i = 0; i < evolverWorkers.size(); i++) {
		delete evolverWorkers[i];
	}

	delete generationWorker;
}

void GaEvolverController::startTournamentWorkers(const std::string& trialId) {
	evolverWorkers.resize(workerCount);
	for (unsigned int i = 0; i < workerCount; i++) {
		evolverWorkers[i] = new GaEvolverWorker(databaseId, trialId, "TOURNAMENT_WORKER_" + std::to_string(i), GaEvolverWorker::GaEvoloverWorkerType::TOURNAMENT_RUNNER);
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
