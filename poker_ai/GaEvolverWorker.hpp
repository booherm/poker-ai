#ifndef GAEVOLVERWORKER_HPP
#define GAEVOLVERWORKER_HPP

#include <ocilib.hpp>
#include <boost/thread.hpp>
#include <windows.h>

class GaEvolverWorker {
public:
	enum GaEvoloverWorkerType {
		TOURNAMENT_RUNNER = 0,
		GENERATION_RUNNER = 1
	};

	GaEvolverWorker(const std::string& databaseId, const std::string& trialId, const std::string& workerId, GaEvoloverWorkerType workerType);
	~GaEvolverWorker();
	void startThread();
	void threadJoin();

private:
	void threadLoop();
	void generationRunnerThreadLoop();
	void tournamentRunnerThreadLoop();

	std::string trialId;
	std::string workerId;
	GaEvoloverWorkerType workerType;
	ocilib::Connection con;
	boost::thread workerThread;
};

#endif