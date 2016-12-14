#ifndef GAEVOLVERTOURNAMENTWORKER_HPP
#define GAEVOLVERTOURNAMENTWORKER_HPP

#include <boost/thread.hpp>
#include <windows.h>
#include "PythonManager.hpp"
#include "StrategyManager.hpp"
#include "TournamentResultCollector.hpp"

class GaEvolverTournamentWorker {
public:

	GaEvolverTournamentWorker(
		DbConnectionManager* dbConnectionManager,
		PythonManager* pythonManager,
		unsigned int trialId,
		unsigned int controlGeneration,
		const std::string& workerId,
		StrategyManager* strategyManager,
		bool loggingEnabled
	);
	void startThread();
	void threadJoin();

private:
	void threadLoop();

	DbConnectionManager* dbConnectionManager;
	TournamentResultCollector* tournamentResultCollector;
	PythonManager* pythonManager;
	unsigned int trialId;
	unsigned int controlGeneration;
	std::string workerId;
	boost::thread workerThread;
	StrategyManager* strategyManager;
	bool loggingEnabled;
};

#endif
