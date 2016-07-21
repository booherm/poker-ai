#include "StrategyManager.hpp"

void StrategyManager::initialize(const std::string& databaseId, PythonManager* pythonManager) {
	con.Open(databaseId, "poker_ai", "poker_ai");
	logger.initialize(con);
	this->pythonManager = pythonManager;
}

Strategy* StrategyManager::getStrategy(unsigned int strategyId) {

	Strategy* s;

	strategyManagerMutex.lock();
	unsigned int strategyCount = strategies.count(strategyId);

	if (strategyCount == 0) {
		logger.log(0, "Strategy manager is loading strategy " + std::to_string(strategyId));
		s = new Strategy;
		s->initialize(con, &logger, pythonManager, &randomNumberGenerator);
		s->loadById(strategyId);
		strategies[strategyId] = s;
	}
	else {
		logger.log(0, "Strategy manager returning cached strategy " + std::to_string(strategyId));
		s = strategies[strategyId];
	}

	strategyManagerMutex.unlock();

	return s;
}

unsigned int StrategyManager::generateRandomStrategy() {
	Strategy* s;
	s = new Strategy;
	s->initialize(con, &logger, pythonManager, &randomNumberGenerator);
	unsigned int strategyId = s->generateFromRandom();
	strategyManagerMutex.lock();
	strategies[strategyId] = s;
	strategyManagerMutex.unlock();

	return strategyId;
}

StrategyManager::~StrategyManager() {
	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		delete it->second;
	}
}