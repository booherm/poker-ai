#include "Util.hpp"
#include <iomanip>
#include <sstream>

std::string Util::zeroPadNumber(unsigned int number) {
	std::ostringstream stringStream;
	stringStream << std::setw(2) << std::setfill('0') << number;
	return stringStream.str();
}
