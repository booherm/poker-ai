#ifndef DBCONNECTIONMANAGER_HPP
#define DBCONNECTIONMANAGER_HPP

#include <occi.h>
#include <boost/thread.hpp>

class DbConnectionManager {
public:

	DbConnectionManager(const std::string& databaseId, const std::string& userId, const std::string& password);
	oracle::occi::Connection* getConnection();
	void releaseConnection(oracle::occi::Connection* connection);
	bool testConnection(oracle::occi::Connection* connection);
	~DbConnectionManager();

private:
	void initializePool();

	boost::mutex getConnectionMutex;
	std::string databaseId;
	std::string userId;
	std::string password;
	oracle::occi::Environment* env;
	oracle::occi::StatelessConnectionPool* connectionPool;

};

#endif