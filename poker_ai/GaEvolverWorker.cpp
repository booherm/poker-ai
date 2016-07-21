#include "GaEvolverWorker.hpp"
#include "TournamentController.hpp"
#include <string>

GaEvolverWorker::GaEvolverWorker(
	const std::string& databaseId,
	PythonManager* pythonManager,
	unsigned int trialId,
	const std::string& workerId,
	GaEvoloverWorkerType workerType,
	StrategyManager* strategyManager
) {
	this->databaseId = databaseId;
	this->trialId = trialId;
	this->workerId = workerId;
	this->workerType = workerType;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
}

void GaEvolverWorker::startThread() {
	workerThread = boost::thread(&GaEvolverWorker::threadLoop, this);
}

void GaEvolverWorker::threadLoop() {

	con.Open(databaseId, "poker_ai", "poker_ai");
	logger.initialize(con);

	if(workerType == TOURNAMENT_RUNNER) {
		tournamentRunnerThreadLoop();
	}
	else {
		generationRunnerThreadLoop();
	}
}

void GaEvolverWorker::generationRunnerThreadLoop() {

	ocilib::Statement st(con);
	int result;
	std::string resultString;

	std::string procCall = "BEGIN :result := pkg_ga_evolver.step_generation(";
	procCall.append("p_trial_id => :trialId");
	procCall.append("); END; ");

	st.Prepare(procCall);
	st.Bind("trialId", trialId, ocilib::BindInfo::In);
	st.Bind("result", result, ocilib::BindInfo::Out);

	do {
		st.ExecutePrepared();

		resultString = workerId + " stepping generation call returned ";

		if (result == -1) {
			resultString += "-1: stop, no work to perform";
			logger.log(0, resultString);
		}
		else if (result == 0 && verboseOutput) {
			resultString += "0: tournament runner work remains";
			logger.log(0, resultString);
		}
		else {
			resultString += "1: create next generation";
			logger.log(0, resultString);
			createNextGeneration();
		}
		
		Sleep(1000);
	} while (result != -1);

}

void GaEvolverWorker::createNextGeneration() {


	// new generation production work.... needs to increment evolution_trial.current_generation
	logger.log(0, "creating new generation...");

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

void GaEvolverWorker::tournamentRunnerThreadLoop() {

	TournamentController tournamentController;
	tournamentController.initialize(databaseId, pythonManager, strategyManager);

	ocilib::Statement st(con);
	ocilib::Statement tournamentWorkBind(con);
	ocilib::Statement tournamentWorkStrategiesBind(con);
	int result;
	std::string resultString;

	std::string procCall = "BEGIN :result := pkg_ga_evolver.select_tournament_work(";
	procCall.append("p_trial_id                   => :trialId, ");
	procCall.append("p_tournament_work            => :tournamentWork, ");
	procCall.append("p_tournament_work_strategies => :tournamentWorkStrategies");
	procCall.append("); END; ");

	st.Prepare(procCall);
	st.Bind("trialId", trialId, ocilib::BindInfo::In);
	st.Bind("tournamentWork", tournamentWorkBind, ocilib::BindInfo::Out);
	st.Bind("tournamentWorkStrategies", tournamentWorkStrategiesBind, ocilib::BindInfo::Out);
	st.Bind("result", result, ocilib::BindInfo::Out);

	do {
		st.ExecutePrepared();

		resultString = workerId + " selecting tournament work returned ";
		if (result == -1){
			resultString += "-1: stop, no work to perform";
			logger.log(0, resultString);
		}
		else if (result == 0) {
			resultString += "0: play tournament";
			logger.log(0, resultString);
			
			ocilib::Resultset tournamentWorkRs = tournamentWorkBind.GetResultset();
			ocilib::Resultset tournamentWorkStrategiesRs = tournamentWorkStrategiesBind.GetResultset();
			tournamentWorkRs.Next();

			std::vector<unsigned int> strategyIds;
			while (tournamentWorkStrategiesRs.Next()) {
				strategyIds.push_back(tournamentWorkStrategiesRs.Get<unsigned int>("strategy_id"));
			}

			unsigned int tournamentId = tournamentWorkRs.Get<unsigned int>("tournament_id");
			logger.log(0, "begin playing tournament " + std::to_string(tournamentId));
			tournamentController.playAutomatedTournament(
				trialId,
				tournamentId,
				strategyIds,
				tournamentWorkRs.Get<unsigned int>("player_count"),
				tournamentWorkRs.Get<unsigned int>("tournament_buy_in"),
				tournamentWorkRs.Get<unsigned int>("initial_small_blind_value"),
				tournamentWorkRs.Get<unsigned int>("double_blinds_interval"),
				false,
				false
			);
			logger.log(0, "end playing tournament " + std::to_string(tournamentId));

		}
		else if (result == 1) {
			resultString += "1: empty queue, wait for more";
			if(verboseOutput)
				logger.log(0, resultString);
		}

		Sleep(1000);
	} while (result != -1);

}

void GaEvolverWorker::threadJoin() {
	workerThread.join();
}

GaEvolverWorker::~GaEvolverWorker() {
	con.Close();
}
