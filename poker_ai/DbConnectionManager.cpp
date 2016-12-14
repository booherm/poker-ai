#include "DbConnectionManager.hpp"
#include <iostream>

DbConnectionManager::DbConnectionManager(const std::string& databaseId, const std::string& userId, const std::string& password) {
	this->databaseId = databaseId;
	this->userId = userId;
	this->password = password;

	// init occi environment
	env = oracle::occi::Environment::createEnvironment(oracle::occi::Environment::THREADED_MUTEXED);
	initializePool();
}

oracle::occi::Connection* DbConnectionManager::getConnection() {

	getConnectionMutex.lock();
	oracle::occi::Connection* con = nullptr;
	unsigned int connectionAttempt = 0;
	unsigned int maxConnectionAttempts = 10;

	while (connectionAttempt < maxConnectionAttempts) {
		connectionAttempt++;

		try {
			con = connectionPool->getConnection();
			if(testConnection(con))
				break;
			else {
				throw oracle::occi::SQLExceptionCreate(-20000);
			}
		}
		catch (oracle::occi::SQLException e) {
			std::cout << "SQL Exception: " << e.what() << std::endl;
			
			try{
				env->terminateStatelessConnectionPool(connectionPool);
			}
			catch (...) {
				// could not terminate connection pool, let it go
			}

			initializePool();
		}

	}

	if (connectionAttempt == maxConnectionAttempts) {
		throw std::exception("max db connection attempts exceeded");
	}

	getConnectionMutex.unlock();

	return con;
}

void DbConnectionManager::releaseConnection(oracle::occi::Connection* connection) {
	connectionPool->releaseConnection(connection);
}

bool DbConnectionManager::testConnection(oracle::occi::Connection* connection) {
	
	bool success;

	try {
		std::string procCall = "BEGIN :1 := pkg_ga_evolver.test_connection; END;";
		oracle::occi::Statement* statement = connection->createStatement();
		statement->setSQL(procCall);
		statement->registerOutParam(1, oracle::occi::OCCIINT);
		statement->execute();
		int result = statement->getInt(1);
		connection->terminateStatement(statement);
		success = true;
	}
	catch (oracle::occi::SQLException e) {
		std::cout << "Connect test failed: " << e.what() << std::endl;
		success = false;
	}

	return success;
}

DbConnectionManager::~DbConnectionManager() {
	env->terminateStatelessConnectionPool(connectionPool);
	oracle::occi::Environment::terminateEnvironment(env);
}

void DbConnectionManager::initializePool() {
	// init connection pool
	connectionPool = env->createStatelessConnectionPool(userId, password, databaseId, 50, 5, 5, oracle::occi::StatelessConnectionPool::HOMOGENEOUS);
}