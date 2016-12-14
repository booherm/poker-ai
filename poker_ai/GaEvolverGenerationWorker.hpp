#ifndef GAEVOLVERGENERATIONWORKER_HPP
#define GAEVOLVERGENERATIONWORKER_HPP

#include <boost/thread.hpp>
#include <windows.h>
#include "StrategyManager.hpp"
#include "Logger.hpp"
#include "Util.hpp"

class GaEvolverGenerationWorker {
public:

	GaEvolverGenerationWorker(
		DbConnectionManager* dbConnectionManager,
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
	void copyChromosomes(Strategy* source, Strategy* destination);
	void copyStrategyUnit(unsigned int strategyUnitId, Strategy* source, Strategy* destination);
	void mutateChromosome(unsigned int strategyUnitId, Strategy* strategy, float mutationRate);

	DbConnectionManager* dbConnectionManager;
	oracle::occi::Connection* con;
	unsigned int trialId;
	std::string workerId;
	Logger logger;
	boost::thread workerThread;
	StrategyManager* strategyManager;
	unsigned int currentGenerationNumber;
	bool loggingEnabled;
	bool generationCreationInProgress = false;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
