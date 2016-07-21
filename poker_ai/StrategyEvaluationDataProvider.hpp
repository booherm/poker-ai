#ifndef STRATEGYEVALUATIONDATAPROVIDER_HPP
#define STRATEGYEVALUATIONDATAPROVIDER_HPP

#include "PokerEnumerations.hpp"

class StrategyEvaluationDataProvider {
public:
	virtual PokerEnums::PlayerMove getMoveForDecisionTreeUnit(unsigned int decisionTreeUnitId) = 0;
	virtual unsigned int getMoveAmountForDecisionTreeUnit(float amountMultiplier) = 0;
	virtual float getExpressionValue(unsigned int expressionId) = 0;
};

#endif
