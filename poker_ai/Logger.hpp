#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <occi.h>
#include <string>
#include <vector>
#include "json.hpp"

class Logger {
public:
	void initialize(oracle::occi::Connection* con);
	void log(unsigned int stateId, const std::string& message);
	void getLogMessages(Json::Value& logMessagesJsonArray);
	void clearLogMessages();
	void loadMessage(const std::string& message);
	void setLoggingEnabled(bool enabled);

private:
	bool loggingEnabled;
	oracle::occi::Connection* con;
	std::vector<std::string> logMessages;
};

#endif
