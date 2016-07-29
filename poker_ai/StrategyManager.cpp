#include "StrategyManager.hpp"

void StrategyManager::initialize(oracle::occi::StatelessConnectionPool* connectionPool, PythonManager* pythonManager) {
	this->connectionPool = connectionPool;
	this->pythonManager = pythonManager;
	con = connectionPool->getConnection();
}

Strategy* StrategyManager::createStrategy() {
	Strategy* s = new Strategy;
	s->initialize(con, pythonManager, false);

	return s;
}

Strategy* StrategyManager::getStrategy(unsigned int strategyId) {

	Strategy* s;

	// look for strategy in the cache
	strategyManagerMutex.lock();
	unsigned int strategyCount = strategies.count(strategyId);

	if (strategyCount == 0) {
		// attempt load of strategy from database
		s = createStrategy();
		s->loadById(strategyId);
		strategies[strategyId] = s;
	}
	else {
		// cached copy found
		s = strategies[strategyId];
	}

	strategyManagerMutex.unlock();

	return s;
}

unsigned int StrategyManager::generateRandomStrategy(unsigned int generation) {

	Strategy* s;
	s = new Strategy;
	s->initialize(con, pythonManager, false);
	unsigned int strategyId = s->generateFromRandom(generation);
	strategyManagerMutex.lock();
	strategies[strategyId] = s;
	strategyManagerMutex.unlock();

	return strategyId;
}

void StrategyManager::flush(int generation) {

	// destruct strategies and clear from cache

	strategyManagerMutex.lock();

	if (generation == -1) {
		for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
			delete it->second;
		}
		strategies.clear();
	}
	else {
		std::vector<unsigned int> toDelete;
		for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
			if (it->second->getGeneration() == generation) {
				toDelete.push_back(it->second->getStrategyId());
				delete it->second;
			}
		}
		for (unsigned int i = 0; i < toDelete.size(); i++)
			strategies.erase(toDelete[i]);
	}

	strategyManagerMutex.unlock();

}

void StrategyManager::flushNonControlGenerations() {

	strategyManagerMutex.lock();

	std::vector<unsigned int> toDelete;
	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		if (it->second->getGeneration() != 0) {
			toDelete.push_back(it->second->getStrategyId());
			delete it->second;
		}
	}
	for (unsigned int i = 0; i < toDelete.size(); i++)
		strategies.erase(toDelete[i]);

	strategyManagerMutex.unlock();

}

void StrategyManager::setStrategy(Strategy* strategy) {
	strategyManagerMutex.lock();
	strategies[strategy->getStrategyId()] = strategy;
	strategyManagerMutex.unlock();
}


StrategyManager::~StrategyManager() {
	flush(-1);
	connectionPool->releaseConnection(con);
}