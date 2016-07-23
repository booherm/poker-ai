#ifndef GAEVOLVERTOURNAMENTWORKER_HPP
#define GAEVOLVERTOURNAMENTWORKER_HPP

#include <boost/thread.hpp>
#include <windows.h>
#include "PythonManager.hpp"
#include "StrategyManager.hpp"

class GaEvolverTournamentWorker {
public:

	GaEvolverTournamentWorker(
		oracle::occi::StatelessConnectionPool* connectionPool,
		PythonManager* pythonManager,
		unsigned int trialId,
		const std::string& workerId,
		StrategyManager* strategyManager,
		bool loggingEnabled
	);
	void startThread();
	void threadJoin();

private:
	void threadLoop();

	oracle::occi::StatelessConnectionPool* connectionPool;
	PythonManager* pythonManager;
	unsigned int trialId;
	std::string workerId;
	boost::thread workerThread;
	StrategyManager* strategyManager;
	bool loggingEnabled;
};

#endif
