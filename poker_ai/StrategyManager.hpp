#ifndef STRATEGYMANAGER_HPP
#define STRATEGYMANAGER_HPP

#include "Strategy.hpp"
#include <occi.h>
#include <boost/thread.hpp>
#include <map>

class StrategyManager {
public:
	void initialize(oracle::occi::StatelessConnectionPool* connectionPool, PythonManager* pythonManager);
	Strategy* createStrategy();
	Strategy* getStrategy(unsigned int strategyId);
	unsigned int generateRandomStrategy(unsigned int generation);
	void flush();
	void setStrategy(Strategy* strategy);
	~StrategyManager();

private:
	oracle::occi::StatelessConnectionPool* connectionPool;
	oracle::occi::Connection* con;
	Logger logger;
	PythonManager* pythonManager;
	std::map<unsigned int, Strategy*> strategies;
	boost::mutex strategyManagerMutex;

};

#endif