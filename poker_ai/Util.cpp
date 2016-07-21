#include "Util.hpp"
#include <iomanip>
#include <sstream>

std::string Util::zeroPadNumber(unsigned int number) {
	std::ostringstream stringStream;
	stringStream << std::setw(2) << std::setfill('0') << number;
	return stringStream.str();
}

Util::RandomNumberGenerator::RandomNumberGenerator() {
	randomNumberEngine.seed(std::random_device()());
}

unsigned int Util::RandomNumberGenerator::getRandomUnsignedInt(unsigned int lowerLimit, unsigned int upperLimit) {
	std::uniform_int_distribution<unsigned int> uniformDist(lowerLimit, upperLimit);
	return uniformDist(randomNumberEngine);
}

bool Util::RandomNumberGenerator::getRandomBool(){
	std::uniform_int_distribution<unsigned int> uniformDist(0, 1);
	return uniformDist(randomNumberEngine) == 1;
}