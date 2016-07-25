#ifndef GAEVOLVERGENERATIONWORKER_HPP
#define GAEVOLVERGENERATIONWORKER_HPP

#include <boost/thread.hpp>
#include <windows.h>
#include <occi.h>
#include "StrategyManager.hpp"
#include "Logger.hpp"
#include "Util.hpp"

class GaEvolverGenerationWorker {
public:

	GaEvolverGenerationWorker(
		oracle::occi::StatelessConnectionPool* connectionPool,
		unsigned int trialId,
		const std::string& workerId,
		StrategyManager* strategyManager,
		unsigned int initialGenerationNumber,
		bool loggingEnabled
	);
	void startThread();
	void threadJoin();

private:
	void threadLoop();
	void updateStrategyFitness();
	void createNextGeneration();
	void performCrossover(Strategy* parentA, Strategy* parentB, unsigned int crossoverPoint, Strategy* childA, Strategy* childB);
	void copyChromosome(Strategy* source, Strategy* destination);
	void mutateChromosome(Strategy* strategy, float mutationRate);

	oracle::occi::StatelessConnectionPool* connectionPool;
	oracle::occi::Connection* con;
	unsigned int trialId;
	std::string workerId;
	Logger logger;
	boost::thread workerThread;
	StrategyManager* strategyManager;
	unsigned int currentGenerationNumber;
	bool loggingEnabled;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
