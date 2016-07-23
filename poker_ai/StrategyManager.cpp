#include "StrategyManager.hpp"

void StrategyManager::initialize(oracle::occi::StatelessConnectionPool* connectionPool, PythonManager* pythonManager) {
	this->connectionPool = connectionPool;
	this->pythonManager = pythonManager;
}

Strategy* StrategyManager::getStrategy(unsigned int strategyId) {

	Strategy* s;

	// look for strategy in the cache
	strategyManagerMutex.lock();
	unsigned int strategyCount = strategies.count(strategyId);

	if (strategyCount == 0) {
		// attempt load of strategy from database
		s = new Strategy;
		s->initialize(connectionPool, pythonManager, false);
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
	s->initialize(connectionPool, pythonManager, false);
	unsigned int strategyId = s->generateFromRandom(generation);
	strategyManagerMutex.lock();
	strategies[strategyId] = s;
	strategyManagerMutex.unlock();

	return strategyId;
}

void StrategyManager::flush() {

	// destruct strategies and clear out cache
	strategyManagerMutex.lock();
	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		delete it->second;
	}
	strategies.clear();
	strategyManagerMutex.unlock();

}

StrategyManager::~StrategyManager() {
	flush();
}