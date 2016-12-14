#ifndef STRATEGYMANAGER_HPP
#define STRATEGYMANAGER_HPP

#include "Strategy.hpp"
#include "DbConnectionManager.hpp"
#include <boost/thread.hpp>
#include <map>
#include <unordered_set>

class StrategyManager {
public:
	void initialize(DbConnectionManager* dbConnectionManager, PythonManager* pythonManager);
	Strategy* createStrategy();
	Strategy* getStrategy(unsigned int strategyId);
	unsigned int generateRandomStrategy(unsigned int trialId, unsigned int generation);
	void flushNonControlGenerations(unsigned int controlGeneration);
	void setStrategy(Strategy* strategy);
	void setGenerationLoaded(unsigned int generation);
	void loadGeneration(unsigned int trialId, unsigned int generation);
	void bounceDbConnection();
	~StrategyManager();

private:

	DbConnectionManager* dbConnectionManager;
	oracle::occi::Connection* con;
	Logger logger;
	PythonManager* pythonManager;
	std::map<unsigned int, Strategy*> strategies;
	std::unordered_set<unsigned int> loadedGenerations;
	boost::mutex strategiesMutex;
	boost::mutex generationsMutex;
	boost::mutex dbBounceMutex;

};

#endif