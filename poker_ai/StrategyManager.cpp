#include "StrategyManager.hpp"

void StrategyManager::initialize(DbConnectionManager* dbConnectionManager, PythonManager* pythonManager) {
	this->dbConnectionManager = dbConnectionManager;
	this->pythonManager = pythonManager;
	con = dbConnectionManager->getConnection();
}

Strategy* StrategyManager::createStrategy() {
	Strategy* s = new Strategy;
	s->initialize(con, pythonManager, false);

	return s;
}

Strategy* StrategyManager::getStrategy(unsigned int strategyId) {

	Strategy* s;

	// look for strategy in the cache
	strategiesMutex.lock();
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

	strategiesMutex.unlock();

	return s;
}

unsigned int StrategyManager::generateRandomStrategy(unsigned int trialId, unsigned int generation) {

	Strategy* s;
	s = new Strategy;
	s->initialize(con, pythonManager, false);
	s->setTrialId(trialId);
	unsigned int strategyId = s->generateFromRandom(generation);
	strategiesMutex.lock();
	strategies[strategyId] = s;
	strategiesMutex.unlock();

	return strategyId;
}

void StrategyManager::flushNonControlGenerations(unsigned int controlGeneration) {

	strategiesMutex.lock();
	generationsMutex.lock();

	std::vector<unsigned int> toDelete;
	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		if (it->second->getGeneration() != controlGeneration) {
			toDelete.push_back(it->second->getStrategyId());
			delete it->second;
		}
	}
	for (unsigned int i = 0; i < toDelete.size(); i++)
		strategies.erase(toDelete[i]);

	toDelete.clear();
	for (std::unordered_set<unsigned int>::iterator it = loadedGenerations.begin(); it != loadedGenerations.end(); ++it) {
		toDelete.push_back(*it);
	}
	for (unsigned int i = 0; i < toDelete.size(); i++)
		loadedGenerations.erase(toDelete[i]);

	generationsMutex.unlock();
	strategiesMutex.unlock();

}

void StrategyManager::setStrategy(Strategy* strategy) {
	strategiesMutex.lock();
	strategies[strategy->getStrategyId()] = strategy;
	strategiesMutex.unlock();
}

void StrategyManager::setGenerationLoaded(unsigned int generation) {
	generationsMutex.lock();
	loadedGenerations.insert(generation);
	generationsMutex.unlock();
}

StrategyManager::~StrategyManager() {

	strategiesMutex.lock();
	generationsMutex.lock();

	for (std::map<unsigned int, Strategy*>::iterator it = strategies.begin(); it != strategies.end(); ++it) {
		delete it->second;
	}
	strategies.clear();
	loadedGenerations.clear();

	generationsMutex.unlock();
	strategiesMutex.unlock();

	dbConnectionManager->releaseConnection(con);
}

void StrategyManager::loadGeneration(unsigned int trialId, unsigned int generation) {

	generationsMutex.lock();
	if (loadedGenerations.find(generation) == loadedGenerations.end()) {

		std::string procCall = "BEGIN pkg_ga_evolver.select_generation(";
		procCall.append("p_trial_id   => :1, ");
		procCall.append("p_generation => :2, ");
		procCall.append("p_result_set => :3");
		procCall.append("); END;");

		oracle::occi::Statement* statement = con->createStatement(procCall);
		statement->setUInt(1, trialId);
		statement->setUInt(2, generation);
		statement->registerOutParam(3, oracle::occi::OCCICURSOR);
		statement->setPrefetchRowCount(100);
		statement->execute();
		oracle::occi::ResultSet* resultSet = statement->getCursor(3);

		strategiesMutex.lock();
		while (resultSet->next()) {

			// look for strategy in the cache
			unsigned int strategyId = resultSet->getUInt(1);
			unsigned int strategyCount = strategies.count(strategyId);

			if (strategyCount == 0) {
				// attempt load of strategy from database
				Strategy* s = createStrategy();
				s->loadById(strategyId);
				strategies[strategyId] = s;
			}

		}
		strategiesMutex.unlock();

		statement->closeResultSet(resultSet);
		con->terminateStatement(statement);

		loadedGenerations.insert(generation);
	}
	generationsMutex.unlock();

}

void StrategyManager::bounceDbConnection() {

	dbBounceMutex.lock();
	if (!dbConnectionManager->testConnection(con)) {
		dbConnectionManager->releaseConnection(con);
		con = dbConnectionManager->getConnection();
	}
	dbBounceMutex.unlock();

};