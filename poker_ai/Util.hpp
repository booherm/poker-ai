#ifndef UTIL_HPP
#define UTIL_HPP

#include <random>
#include <string>
#include <occi.h>

namespace Util {
	std::string zeroPadNumber(unsigned int number);
	void clobToString(const oracle::occi::Clob& sourceClob, std::string& destinationString);

	class RandomNumberGenerator {
	public:
		RandomNumberGenerator();
		unsigned int getRandomUnsignedInt(unsigned int lowerLimit, unsigned int upperLimit);
		bool getRandomBool();
		float getRandomFloat(float lowerLimit, float upperLimit);

	private:
		std::default_random_engine randomNumberEngine;
	};
};

#endif
