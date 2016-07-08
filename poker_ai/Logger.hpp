#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <ocilib.hpp>
#include <string>
#include <vector>
#include "json.hpp"

class Logger {
public:
	void initialize(ocilib::Connection& con);
	void log(unsigned int stateId, const std::string& message);
	void getLogMessages(Json::Value& logMessagesJsonArray);
	void clearLogMessages();
	void loadMessage(const std::string& message);

private:
	ocilib::Connection con;
	std::vector<std::string> logMessages;
};

#endif
