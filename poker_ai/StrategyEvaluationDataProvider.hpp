#ifndef STRATEGYEVALUATIONDATAPROVIDER_HPP
#define STRATEGYEVALUATIONDATAPROVIDER_HPP

#include "PokerEnumerations.hpp"
#include "StateVariableCollection.hpp"
#include "Strategy.hpp"

class StrategyEvaluationDataProvider {
public:
	struct BetRaiseLimits {
		unsigned int minBetRaiseAmount;
		unsigned int maxBetRaiseAmount;
	};
	void initialize(unsigned int playerSeatNumber, StateVariableCollection* stateVariableCollection, Strategy* strategy);
	PythonManager::PlayerMoveResult executeDecisionProcedure(std::vector<PokerEnums::PlayerMove>* possiblePlayerMoves, BetRaiseLimits* betRaiseLimits);
	PokerEnums::PlayerMove getMoveForDecisionTreeUnit(unsigned int decisionTreeUnitId);
	unsigned int getMoveAmountForDecisionTreeUnit(float amountMultiplier);
	float getExpressionValue(unsigned int expressionId);
	unsigned int getStrategyId() const;

private:
	float getValueExpressionVariableValue(unsigned int valueExpressionVariableId) const;
	float getSubExpressionValue(unsigned int expressionSlotId, std::vector<unsigned int>& leftReferencedIds, std::vector<unsigned int>& rightReferencedIds);

	Strategy* strategy = nullptr;
	StateVariableCollection* stateVariableCollection;
	std::vector<PokerEnums::PlayerMove>* currentPossiblePlayerMoves;
	BetRaiseLimits* currentBetRaiseLimits;
	unsigned int playerSeatNumber;
	StateVariableCollection::VariableSectionBoundaries vsb;

};

#endif
