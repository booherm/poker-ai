#include "Logger.hpp"

void Logger::initialize(ocilib::Connection& con) {
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
	procCall.append("p_state_id => :stateId, ");
	procCall.append("p_message  => :message");
	procCall.append("); END; ");

	ocilib::Statement st(con);
	st.Prepare(procCall);
	ocilib::ostring messageOString(message);
	st.Bind("stateId", stateId, ocilib::BindInfo::In);
	st.Bind("message", messageOString, static_cast<unsigned int>(messageOString.size()), ocilib::BindInfo::In);
	st.ExecutePrepared();

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