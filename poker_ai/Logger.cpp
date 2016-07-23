#include "Logger.hpp"

void Logger::initialize(oracle::occi::Connection* con) {
	this->con = con;
	loggingEnabled = true;
}

void Logger::setLoggingEnabled(bool enabled) {
	loggingEnabled = enabled;
}

void Logger::log(unsigned int stateId, const std::string& message) {

	if (!loggingEnabled)
		return;

	logMessages.push_back(message);

	std::string procCall = "BEGIN pkg_poker_ai.log(";
	procCall.append("p_state_id => :1, ");
	procCall.append("p_message  => :2");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, stateId);
	statement->setString(2, message);
	statement->execute();
	con->terminateStatement(statement);

}

void Logger::getLogMessages(Json::Value& logMessagesJsonArray) {
	for (unsigned int i = 0; i < logMessages.size(); i++) {
		logMessagesJsonArray.append(logMessages[i]);
	}
}

void Logger::clearLogMessages() {
	logMessages.clear();
}

void Logger::loadMessage(const std::string& message) {
	logMessages.push_back(message);
}
