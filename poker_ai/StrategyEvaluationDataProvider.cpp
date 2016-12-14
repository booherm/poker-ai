#include "StrategyEvaluationDataProvider.hpp"

void StrategyEvaluationDataProvider::initialize(unsigned int playerSeatNumber, StateVariableCollection* stateVariableCollection, Strategy* strategy) {
	this->playerSeatNumber = playerSeatNumber;
	this->stateVariableCollection = stateVariableCollection;
	this->strategy = strategy;
	stateVariableCollection->getVariableSectionBoundaries(vsb);
}

PythonManager::PlayerMoveResult StrategyEvaluationDataProvider::executeDecisionProcedure(std::vector<PokerEnums::PlayerMove>* possiblePlayerMoves, BetRaiseLimits* betRaiseLimits) {
	currentPossiblePlayerMoves = possiblePlayerMoves;
	currentBetRaiseLimits = betRaiseLimits;

	currentStrategyUnitId = 0;

	// determine proper strategy unit id by possible moves
	if (possiblePlayerMoves->size() == 2) {
		if (possiblePlayerMoves->at(0) == PokerEnums::PlayerMove::CHECK && possiblePlayerMoves->at(1) == PokerEnums::PlayerMove::BET)
			currentStrategyUnitId = 0;
		else if (possiblePlayerMoves->at(0) == PokerEnums::PlayerMove::CHECK && possiblePlayerMoves->at(1) == PokerEnums::PlayerMove::RAISE)
			currentStrategyUnitId = 1;
		else // FOLD, CALL
			currentStrategyUnitId = 2;
	}
	else {  // FOLD, CALL, RAISE
		currentStrategyUnitId = 3;
	}

	return strategy->pythonManager->executeDecisionProcedure(this, strategy->strategyUnits[currentStrategyUnitId].compiledDecisionProcedure);
}

PokerEnums::PlayerMove StrategyEvaluationDataProvider::getMoveForDecisionTreeUnit(unsigned int decisionTreeUnitId) {

	unsigned int startingOutputSlotId = (unsigned int) pow(2, strategy->treeDepth - 1) - 1;
	unsigned int outputSlotId = decisionTreeUnitId - startingOutputSlotId;
	unsigned int outputSlotIdCount = startingOutputSlotId;
	float location = (float) outputSlotId / outputSlotIdCount;
	unsigned int possibleMoveCount = currentPossiblePlayerMoves->size();

	// all player moves consist of either exactly 2 or 3 choices
	if (possibleMoveCount == 2) {
		if (location < 0.5f)
			return currentPossiblePlayerMoves->at(0);
		else
			return currentPossiblePlayerMoves->at(1);
	}
	else {
		if(location < 0.333f)
			return currentPossiblePlayerMoves->at(0);
		else if (location < 0.666f)
			return currentPossiblePlayerMoves->at(1);
		else
			return currentPossiblePlayerMoves->at(2);
	}

}

unsigned int StrategyEvaluationDataProvider::getMoveAmountForDecisionTreeUnit(float amountMultiplier) {

	unsigned int moveAmount;

	if (amountMultiplier >= 0.95f)
		moveAmount = currentBetRaiseLimits->maxBetRaiseAmount;
	else if (amountMultiplier <= 0.05f)
		moveAmount = currentBetRaiseLimits->minBetRaiseAmount;
	else {
		moveAmount = currentBetRaiseLimits->minBetRaiseAmount
			+ (unsigned int) ((amountMultiplier * (float) (currentBetRaiseLimits->maxBetRaiseAmount - currentBetRaiseLimits->minBetRaiseAmount)) + 0.5f);
	}

	if (moveAmount > currentBetRaiseLimits->maxBetRaiseAmount)
		moveAmount = currentBetRaiseLimits->maxBetRaiseAmount;

	if (moveAmount < currentBetRaiseLimits->minBetRaiseAmount)
		moveAmount = currentBetRaiseLimits->minBetRaiseAmount;

	return moveAmount;
}

float StrategyEvaluationDataProvider::getExpressionValue(unsigned int expressionId) {

	// 10 bit, 0 <= expressionId <= 1023

	// if expression id exceeds variables + expression slots, circle back around
	// 754 + 254 = 1008, valid values are 0 <= expId <= 1007
	unsigned int expId = expressionId % (vsb.publicPlayerStateUpperBound + strategy->valueExpressionSlotIdCount);

	if (expId <= vsb.publicPlayerStateUpperBound) {
		return getValueExpressionVariableValue(expId);
	}
	else {
		// value is > vsb.publicPlayerStateUpperBound, references another expression
		std::vector<unsigned int> leftReferencedIds;
		std::vector<unsigned int> rightReferencedIds;
		leftReferencedIds.push_back(expId);
		rightReferencedIds.push_back(expId);

		return getSubExpressionValue(expId, leftReferencedIds, rightReferencedIds);
	}

}

unsigned int StrategyEvaluationDataProvider::getStrategyGeneration() const {
	if (strategy == nullptr)
		return 0;

	return strategy->getGeneration();
}

unsigned int StrategyEvaluationDataProvider::getStrategyId() const {
	if (strategy == nullptr)
		return 0;
	
	return strategy->strategyId;
}

float StrategyEvaluationDataProvider::getValueExpressionVariableValue(unsigned int valueExpressionVariableId) const {

	if (valueExpressionVariableId >= vsb.constantLowerBound && valueExpressionVariableId <= vsb.constantUpperBound) {
		return stateVariableCollection->getConstantValue((StateVariableCollection::Constant) valueExpressionVariableId);
	}
	else if (valueExpressionVariableId >= vsb.pokerStateLowerBound && valueExpressionVariableId <= vsb.pokerStateUpperBound) {
		return stateVariableCollection->getPokerStateVariableValue((StateVariableCollection::PokerStateVariable) valueExpressionVariableId);
	}
	else if (valueExpressionVariableId >= vsb.privatePlayerStateLowerBound && valueExpressionVariableId <= vsb.privatePlayerStateUpperBound) {
		return stateVariableCollection->getPrivatePlayerStateVariableValue((StateVariableCollection::PrivatePlayerStateVariable) valueExpressionVariableId, playerSeatNumber);
	}
	else {
		return stateVariableCollection->getPublicPlayerStateVariableValue((StateVariableCollection::PublicPlayerStateVariable) valueExpressionVariableId);
	}

}

float StrategyEvaluationDataProvider::getSubExpressionValue(unsigned int expressionSlotId, std::vector<unsigned int>& leftReferencedIds, std::vector<unsigned int>& rightReferencedIds) {

	// if expression id exceeds variables + expression slots, circle back around
	// 754 + 254 = 1008, valid values are 0 <= expId <= 1007
	unsigned int expId = expressionSlotId % (vsb.publicPlayerStateUpperBound + strategy->valueExpressionSlotIdCount);
	float leftOperandValue;
	float rightOperandValue;

	if (expId <= vsb.publicPlayerStateUpperBound) {
		// id references a variable
		return getValueExpressionVariableValue(expId);
	}
	else {

		// value is > vsb.publicPlayerStateUpperBound, id references another expression

		Strategy::ValueExpression* valueExpression = strategy->getValueExpression(currentStrategyUnitId, expId - vsb.publicPlayerStateUpperBound);
		std::vector<unsigned int>::iterator it;
		std::string expressionOp = strategy->getExpressionValueOperatorText(valueExpression->valueExpressionOperator.valueExpressionOperatorId);

		it = std::find(leftReferencedIds.begin(), leftReferencedIds.end(), valueExpression->leftValueExpressionOperand.valueExpressionOperandId);
		if (it != leftReferencedIds.end()) {
			leftOperandValue = (expressionOp == "+" || expressionOp == "-") ? 0.0f : 1.0f;
		}
		else {
			leftReferencedIds.push_back(valueExpression->leftValueExpressionOperand.valueExpressionOperandId);
			leftOperandValue = getSubExpressionValue(valueExpression->leftValueExpressionOperand.valueExpressionOperandId, leftReferencedIds, rightReferencedIds);
		}

		it = std::find(rightReferencedIds.begin(), rightReferencedIds.end(), valueExpression->rightValueExpressionOperand.valueExpressionOperandId);
		if (it != rightReferencedIds.end()) {
			rightOperandValue = (expressionOp == "+" || expressionOp == "-") ? 0.0f : 1.0f;
		}
		else {
			rightReferencedIds.push_back(valueExpression->rightValueExpressionOperand.valueExpressionOperandId);
			rightOperandValue = getSubExpressionValue(valueExpression->rightValueExpressionOperand.valueExpressionOperandId, leftReferencedIds, rightReferencedIds);
		}

		if (expressionOp == "+") {
			return leftOperandValue + rightOperandValue;
		}
		else if (expressionOp == "-") {
			return leftOperandValue - rightOperandValue;
		}
		else if (expressionOp == "*") {
			return leftOperandValue * rightOperandValue;
		}
		else {
			if (rightOperandValue == 0.0f)
				return leftOperandValue;
			else
				return leftOperandValue / rightOperandValue;
		}

	}

}
