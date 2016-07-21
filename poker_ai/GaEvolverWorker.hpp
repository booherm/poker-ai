#ifndef GAEVOLVERWORKER_HPP
#define GAEVOLVERWORKER_HPP

#include <ocilib.hpp>
#include <boost/thread.hpp>
#include <windows.h>
#include "PythonManager.hpp"
#include "StrategyManager.hpp"
#include "Logger.hpp"

class GaEvolverWorker {
public:
	enum GaEvoloverWorkerType {
		TOURNAMENT_RUNNER = 0,
		GENERATION_RUNNER = 1
	};

	GaEvolverWorker(
		const std::string& databaseId,
		PythonManager* pythonManager,
		unsigned int trialId,
		const std::string& workerId,
		GaEvoloverWorkerType workerType,
		StrategyManager* strategyManager
	);
	~GaEvolverWorker();
	void startThread();
	void threadJoin();

private:
	void threadLoop();
	void generationRunnerThreadLoop();
	void createNextGeneration();
	void tournamentRunnerThreadLoop();

	bool verboseOutput = true;
	std::string databaseId;
	PythonManager* pythonManager;
	unsigned int trialId;
	std::string workerId;
	GaEvoloverWorkerType workerType;
	ocilib::Connection con;
	Logger logger;
	boost::thread workerThread;
	StrategyManager* strategyManager;
};

#endif