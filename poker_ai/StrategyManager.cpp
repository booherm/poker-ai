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

void StrategyManager::flush() {

	// destruct strategies and clear out cache
	strategyManagerMutex.lock();
	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		delete it->second;
	}
	strategies.clear();
	strategyManagerMutex.unlock();

}

void StrategyManager::setStrategy(Strategy* strategy) {
	strategyManagerMutex.lock();
	strategies[strategy->getStrategyId()] = strategy;
	strategyManagerMutex.unlock();
}


StrategyManager::~StrategyManager() {
	flush();
	connectionPool->releaseConnection(con);
}