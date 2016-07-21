#ifndef STRATEGYMANAGER_HPP
#define STRATEGYMANAGER_HPP

#include "Strategy.hpp"
#include <boost/thread.hpp>
#include <map>

class StrategyManager {
public:
	void initialize(const std::string& databaseId, PythonManager* pythonManager);
	Strategy* getStrategy(unsigned int strategyId);
	unsigned int generateRandomStrategy();
	~StrategyManager();

private:
	ocilib::Connection con;
	Logger logger;
	PythonManager* pythonManager;
	Util::RandomNumberGenerator randomNumberGenerator;
	std::map<unsigned int, Strategy*> strategies;
	boost::mutex strategyManagerMutex;

};

#endif