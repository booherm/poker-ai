#include "GaEvolverWorker.hpp"

GaEvolverWorker::GaEvolverWorker(const std::string& databaseId, const std::string& trialId, const std::string& workerId, GaEvoloverWorkerType workerType) {

	this->trialId = trialId;
	this->workerId = workerId;
	this->workerType = workerType;

	con.Open(databaseId, "poker_ai", "poker_ai");
}

void GaEvolverWorker::startThread() {

	workerThread = boost::thread(&GaEvolverWorker::threadLoop, this);
}

void GaEvolverWorker::threadLoop() {

	if(workerType == TOURNAMENT_RUNNER) {
		tournamentRunnerThreadLoop();
	}
	else {
		generationRunnerThreadLoop();
	}
}

void GaEvolverWorker::generationRunnerThreadLoop() {
	try
	{
		ocilib::Statement st(con);
		int result;
		std::string resultString;

		std::string procCall = "BEGIN :result := pkg_ga_evolver.step_generation(";
		procCall.append("p_trial_id  => :trialId");
		procCall.append("); END; ");

		st.Prepare(procCall);
		ocilib::ostring trialIdOstring(trialId);
		st.Bind("trialId", trialIdOstring, static_cast<unsigned int>(trialIdOstring.size()), ocilib::BindInfo::In);
		st.Bind("result", result, ocilib::BindInfo::Out);

		do {
			st.ExecutePrepared();

			if (result == -1) {
				resultString = "-1: stop, no work to perform";
				std::cout << this->workerId << " stepping generation call returned - " << resultString << std::endl;
			}
			else if (result == 0) {
				resultString = "0: tournament runner work remains";
			}
			else{
				resultString = std::to_string(result) + ": generation created";
				std::cout << this->workerId << " stepping generation call returned - " << resultString << std::endl;
			}

			Sleep(1000);
		} while (result != -1);
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void GaEvolverWorker::tournamentRunnerThreadLoop() {
	try
	{
		ocilib::Statement st(con);
		int result;
		std::string resultString;

		std::string procCall = "BEGIN :result := pkg_ga_evolver.step_tournament_work(";
		procCall.append("p_trial_id  => :trialId, ");
		procCall.append("p_worker_id => :workerId");
		procCall.append("); END; ");

		st.Prepare(procCall);
		ocilib::ostring trialIdOstring(trialId);
		st.Bind("trialId", trialIdOstring, static_cast<unsigned int>(trialIdOstring.size()), ocilib::BindInfo::In);
		ocilib::ostring workerIdOstring(workerId);
		st.Bind("workerId", workerIdOstring, static_cast<unsigned int>(workerIdOstring.size()), ocilib::BindInfo::In);
		st.Bind("result", result, ocilib::BindInfo::Out);

		do {
			st.ExecutePrepared();

			if (result == -1){
				resultString = "-1: stop, no work to perform";
				std::cout << this->workerId << " stepping tournament work returned - " << resultString << std::endl;
			}
			else if (result == 0) {
				resultString = "0: played tournament";
				std::cout << this->workerId << " stepping tournament work returned - " << resultString << std::endl;
			}
			else if (result == 1) {
				resultString = "1: empty queue";
			}

			Sleep(1000);
		} while (result != -1);
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void GaEvolverWorker::threadJoin() {
	workerThread.join();
}

GaEvolverWorker::~GaEvolverWorker() {
	con.Close();
}