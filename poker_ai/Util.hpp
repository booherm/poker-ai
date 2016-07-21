#ifndef UTIL_HPP
#define UTIL_HPP

#include <random>
#include <string>

namespace Util {
	std::string zeroPadNumber(unsigned int number);

	class RandomNumberGenerator {
	public:
		RandomNumberGenerator();
		unsigned int getRandomUnsignedInt(unsigned int lowerLimit, unsigned int upperLimit);
		bool getRandomBool();

	private:
		std::default_random_engine randomNumberEngine;
	};
};

#endif
