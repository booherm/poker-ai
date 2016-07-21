#include "Strategy.hpp"

void Strategy::initialize(ocilib::Connection& con,
	Logger* logger,
	PythonManager* pythonManager,
	Util::RandomNumberGenerator* randomNumberGenerator
) {
	this->con = con;
	this->logger = logger;
	this->pythonManager = pythonManager;
	this->randomNumberGenerator = randomNumberGenerator;
}

void Strategy::loadById(unsigned int loadStrategyId) {

	std::string procCall = "BEGIN pkg_poker_ai.select_strategy(";
	procCall.append("p_strategy_id => :strategyId, ");
	procCall.append("p_result      => :result");
	procCall.append("); END;");
	ocilib::Statement st(con);
	ocilib::Statement resultBind(con);
	st.Prepare(procCall);

	st.Bind("strategyId", loadStrategyId, ocilib::BindInfo::In);
	st.Bind("result", resultBind, ocilib::BindInfo::Out);
	st.ExecutePrepared();
	
	ocilib::Resultset resultRs = resultBind.GetResultset();
	if (resultRs.Next()) {

		strategyId = resultRs.Get<unsigned int>("strategy_id");
		generation = resultRs.Get<unsigned int>("generation");

		// strategy chromosome
		ocilib::Clob strategyChromosomeClob = resultRs.Get<ocilib::Clob>("strategy_chromosome");
		ocilib::ostring strategyChromosomeOString = strategyChromosomeClob.Read((unsigned int) strategyChromosomeClob.GetLength());
		chromosome.clear();
		unsigned int strategyChromosomeLength = strategyChromosomeOString.length();
		for (unsigned int i = 0; i < strategyChromosomeLength; i++) {
			chromosome.push_back(strategyChromosomeOString[i] == '1');
		}

		// rebuild decision unit tree
		setDecisionTreeAttributes();

		// strategy procedure
		ocilib::Clob strategyProcedureClob = resultRs.Get<ocilib::Clob>("strategy_procedure");
		ocilib::ostring strategyProcedureOString = strategyProcedureClob.Read((unsigned int) strategyProcedureClob.GetLength());
		decisionProcedure = std::string(strategyProcedureOString);
		compiledDecisionProcedure = pythonManager->compileDecisionProcedure(decisionProcedure);

		logger->log(0, "Strategy " + std::to_string(strategyId) + " loaded from database");
	}
	else {
		// strategy not found, generate from random
		strategyId = loadStrategyId;
		generateFromRandom();
		logger->log(0, "Strategy " + std::to_string(strategyId) + " not found on database, generated from random");
	}

}

unsigned int Strategy::generateFromRandom() {

	chromosome.clear();
	for (unsigned int i = 0; i < chromosomeBitLength; i++) {
		chromosome.push_back(randomNumberGenerator->getRandomBool());
	}

	if (compiledDecisionProcedure != nullptr) {
		pythonManager->decreaseReferenceCount(compiledDecisionProcedure);
	}
	generateDecisionProcedure();
	compiledDecisionProcedure = pythonManager->compileDecisionProcedure(decisionProcedure);

	// call for a new unique strategy id
	unsigned int freshStrategyId;
	std::string procCall = "BEGIN :freshStrategyId := pkg_poker_ai.get_new_strategy_id; END;";
	ocilib::Statement st(con);
	st.Prepare(procCall);
	st.Bind("freshStrategyId", freshStrategyId, ocilib::BindInfo::Out);
	st.ExecutePrepared();

	strategyId = freshStrategyId;
	generation = 1;

	save();

	return strategyId;
}

void Strategy::save() {

	ocilib::ostring strategyChromosomeOString = "";
	for (unsigned int i = 0; i < chromosome.size(); i++) {
		strategyChromosomeOString.append(chromosome[i] ? "1" : "0");
	}
	ocilib::Clob strategyChromosomeClob = ocilib::Clob(con);
	strategyChromosomeClob.Write(strategyChromosomeOString);

	ocilib::Clob strategyProcedureClob = ocilib::Clob(con);
	strategyProcedureClob.Write(ocilib::ostring(decisionProcedure));

	std::string procCall = "BEGIN pkg_poker_ai.upsert_strategy(";
	procCall.append("p_strategy_id         => :strategyId, ");
	procCall.append("p_generation          => :generation, ");
	procCall.append("p_strategy_chromosome => :strategyChromosome, ");
	procCall.append("p_strategy_procedure  => :strategyProcedure");
	procCall.append("); END;");
	ocilib::Statement st(con);
	st.Prepare(procCall);

	st.Bind("strategyId", strategyId, ocilib::BindInfo::In);
	st.Bind("generation", generation, ocilib::BindInfo::In);
	st.Bind("strategyChromosome", strategyChromosomeClob, ocilib::BindInfo::In);
	st.Bind("strategyProcedure", strategyProcedureClob, ocilib::BindInfo::In);
	st.ExecutePrepared();
	con.Commit();

	logger->log(0, "Strategy " + std::to_string(strategyId) + " saved to database");
}

void Strategy::setPlayerSeatNumber(unsigned int playerSeatNumber) {
	this->playerSeatNumber = playerSeatNumber;
}

void Strategy::setStateVariableCollection(StateVariableCollection* stateVariableCollection) {
	this->stateVariableCollection = stateVariableCollection;
	stateVariableCollection->getVariableSectionBoundaries(vsb);
}

PythonManager::PlayerMoveResult Strategy::executeDecisionProcedure(std::vector<PokerEnums::PlayerMove>* possiblePlayerMoves, BetRaiseLimits* betRaiseLimits) {
	currentPossiblePlayerMoves = possiblePlayerMoves;
	currentBetRaiseLimits = betRaiseLimits;
	return pythonManager->executeDecisionProcedure(this, compiledDecisionProcedure);
}

PokerEnums::PlayerMove Strategy::getMoveForDecisionTreeUnit(unsigned int decisionTreeUnitId) {

	unsigned int startingOutputSlotId = (unsigned int) pow(2, treeDepth - 1) - 1;
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

unsigned int Strategy::getMoveAmountForDecisionTreeUnit(float amountMultiplier) {

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

float Strategy::getExpressionValue(unsigned int expressionId) {

	// 10 bit, 0 <= expressionId <= 1023

	// if expression id exceeds variables + expression slots, circle back around
	// 754 + 254 = 1008, valid values are 0 <= expId <= 1007
	unsigned int expId = expressionId % (vsb.publicPlayerStateUpperBound + valueExpressionSlotIdCount);

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

unsigned int Strategy::getStrategyId() const {
	return strategyId;
}

float Strategy::getValueExpressionVariableValue(unsigned int valueExpressionVariableId) const {

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

float Strategy::getSubExpressionValue(unsigned int expressionSlotId, std::vector<unsigned int>& leftReferencedIds, std::vector<unsigned int>& rightReferencedIds) {

	// if expression id exceeds variables + expression slots, circle back around
	// 754 + 254 = 1008, valid values are 0 <= expId <= 1007
	unsigned int expId = expressionSlotId % (vsb.publicPlayerStateUpperBound + valueExpressionSlotIdCount);
	float leftOperandValue;
	float rightOperandValue;

	if (expId <= vsb.publicPlayerStateUpperBound) {
		// id references a variable
		return getValueExpressionVariableValue(expId);
	}
	else {

		// value is > vsb.publicPlayerStateUpperBound, id references another expression

		ValueExpression* valueExpression = getValueExpression(expId - vsb.publicPlayerStateUpperBound);
		std::vector<unsigned int>::iterator it;
		std::string expressionOp = getExpressionValueOperatorText(valueExpression->valueExpressionOperator.valueExpressionOperatorId);

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

Strategy::ValueExpression* Strategy::getValueExpression(unsigned int expId) {
	for (unsigned int i = 0; i < decisionTreeUnits.size(); i++) {
		DecisionTreeUnit* dtu = &decisionTreeUnits[i];

		if (dtu->leftValueExpression.valueExpressionSlotId == expId)
			return &dtu->leftValueExpression;

		if (dtu->rightValueExpression.valueExpressionSlotId == expId)
			return &dtu->rightValueExpression;
	}

	return nullptr;
}

Strategy::~Strategy() {
	if (compiledDecisionProcedure != nullptr) {
		pythonManager->decreaseReferenceCount(compiledDecisionProcedure);
	}
}

void Strategy::setDecisionTreeAttributes() {

	decisionTreeUnits.resize(decisionTreeUnitSlots);

	for (unsigned int i = 0; i < decisionTreeUnitSlots; i++) {

		DecisionTreeUnit* dtu = &decisionTreeUnits[i];

		// setup decision tree unit bit string lengths and chromosome start positions
		dtu->leftValueExpression.valueExpressionSlotId = i * 2;

		dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength = valueExpressionOperandIdBitLength;
		dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex = i * decisionTreeUnitBitLength;
		dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength = valueExpressionOperatorIdBitLength;
		dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex =
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex
			+ dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength;
		dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength = valueExpressionOperandIdBitLength;
		dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex =
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex
			+ dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength;

		dtu->decisionOperator.decisionOperatorBitStringLength = decisionOperatorBitLength;
		dtu->decisionOperator.decisionOperatorChromosomeStartIndex =
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex
			+ dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength;

		dtu->rightValueExpression.valueExpressionSlotId = (i * 2) + 1;

		dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength = valueExpressionOperandIdBitLength;
		dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex =
			dtu->decisionOperator.decisionOperatorChromosomeStartIndex
			+ dtu->decisionOperator.decisionOperatorBitStringLength;
		dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength = valueExpressionOperatorIdBitLength;
		dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex =
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex
			+ dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength;
		dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength = valueExpressionOperandIdBitLength;
		dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex =
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex
			+ dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength;

		dtu->leftAmountMultiplier.amountMultiplierBitStringLength = amountMultiplierBitLength;
		dtu->leftAmountMultiplier.amountMultiplierChromosomeStartIndex =
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex
			+ dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength;

		dtu->rightAmountMultiplier.amountMultiplierBitStringLength = amountMultiplierBitLength;
		dtu->rightAmountMultiplier.amountMultiplierChromosomeStartIndex =
			dtu->leftAmountMultiplier.amountMultiplierChromosomeStartIndex
			+ dtu->leftAmountMultiplier.amountMultiplierBitStringLength;

		// set bit strings
		dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString = getChromosomeSection(
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength);
		dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitString = getChromosomeSection(
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex,
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength);
		dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString = getChromosomeSection(
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength);

		dtu->decisionOperator.decisionOperatorBitString = getChromosomeSection(
			dtu->decisionOperator.decisionOperatorChromosomeStartIndex,
			dtu->decisionOperator.decisionOperatorBitStringLength);

		dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString = getChromosomeSection(
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength);
		dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitString = getChromosomeSection(
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex,
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength);
		dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString = getChromosomeSection(
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength);

		dtu->leftAmountMultiplier.amountMultiplierBitString = getChromosomeSection(
			dtu->leftAmountMultiplier.amountMultiplierChromosomeStartIndex,
			dtu->leftAmountMultiplier.amountMultiplierBitStringLength);

		dtu->rightAmountMultiplier.amountMultiplierBitString = getChromosomeSection(
			dtu->rightAmountMultiplier.amountMultiplierChromosomeStartIndex,
			dtu->rightAmountMultiplier.amountMultiplierBitStringLength);

		// decode bit strings to IDs
		dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandId = getIdFromBitString(
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString);
		dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorId = getIdFromBitString(
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitString);
		dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandId = getIdFromBitString(
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString);

		dtu->decisionOperator.decisionOperatorId = getIdFromBitString(dtu->decisionOperator.decisionOperatorBitString);

		dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandId = getIdFromBitString(
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString);
		dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorId = getIdFromBitString(
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitString);
		dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandId = getIdFromBitString(
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString);

		dtu->leftAmountMultiplier.amountMultiplierId = getIdFromBitString(dtu->leftAmountMultiplier.amountMultiplierBitString);
		dtu->rightAmountMultiplier.amountMultiplierId = getIdFromBitString(dtu->rightAmountMultiplier.amountMultiplierBitString);

	}
}

void Strategy::generateDecisionProcedure() {

	setDecisionTreeAttributes();
	decisionProcedure = "amountMultiplier = 1.0\n";
	decisionProcedure += getDecisionTree(0);

}

std::string Strategy::getDecisionTree(unsigned int decisionTreeUnitId) const {

	std::string treeCode;

	// determine the tree depth of the requested boolean operator slot ID
	unsigned int depth = (unsigned int) log2(decisionTreeUnitId + 1);
	if (depth == treeDepth - 1) {
		// leaf
		treeCode = indent(depth) + "playerMove = embeddedMethods.getMoveForDecisionTreeUnit(" + std::to_string(decisionTreeUnitId) + ")\n";
		treeCode += indent(depth) + "playerMoveAmount = embeddedMethods.getMoveAmountForDecisionTreeUnit(amountMultiplier)\n";
		treeCode += indent(depth) + "embeddedMethods.setResults(playerMove, playerMoveAmount)\n";
	}
	else {

		const DecisionTreeUnit* dtu = &decisionTreeUnits[decisionTreeUnitId];
		std::string valueExpressionOp;

		// left value expression
		treeCode = indent(depth) + "if embeddedMethods.getExpressionValue("
			+ std::to_string(dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandId) + ") ";
		valueExpressionOp = getExpressionValueOperatorText(dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorId);
		treeCode += valueExpressionOp + " ";
		if (valueExpressionOp == "/")
			treeCode += "safeDenom(";
		treeCode += "embeddedMethods.getExpressionValue(" + std::to_string(dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandId) + ")";
		if (valueExpressionOp == "/")
			treeCode += ")";

		// decision operator
		treeCode += " " + getDecisionOperatorText(dtu->decisionOperator.decisionOperatorId) + " ";

		// right value expression
		treeCode += "embeddedMethods.getExpressionValue(" + std::to_string(dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandId) + ") ";
		valueExpressionOp = getExpressionValueOperatorText(dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorId);
		treeCode += valueExpressionOp + " ";
		if (valueExpressionOp == "/")
			treeCode += "safeDenom(";
		treeCode += "embeddedMethods.getExpressionValue(" + std::to_string(dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandId) + ")";
		if (valueExpressionOp == "/")
			treeCode += ")";

		treeCode += ":\n";

		// left branch amount multiplier
		treeCode += indent(depth + 1) + "amountMultiplier *= " + std::to_string(getAmountMultiplierFromId(dtu->leftAmountMultiplier.amountMultiplierId)) + "\n";

		// left branch decision tree
		treeCode += getDecisionTree((2 * decisionTreeUnitId) + 1);

		treeCode += indent(depth) + "else:\n";

		// right branch amount multiplier
		treeCode += indent(depth + 1) + "amountMultiplier *= " + std::to_string(getAmountMultiplierFromId(dtu->rightAmountMultiplier.amountMultiplierId)) + "\n";

		// right branch decision tree
		treeCode += getDecisionTree((2 * decisionTreeUnitId) + 2);
	}

	return treeCode;
}

std::vector<bool> Strategy::getChromosomeSection(unsigned int startIndex, unsigned int length) const {
	return std::vector<bool>(chromosome.begin() + startIndex, chromosome.begin() + startIndex + length);
}

unsigned int Strategy::getIdFromBitString(const std::vector<bool>& bitString) const {
	unsigned int result = 0;
	unsigned int stringLength = bitString.size();

	for (unsigned int i = 0; i < stringLength; i++) {
		if (bitString[i])
			result += (unsigned int) pow(2, stringLength - i - 1);
	}

	return result;
}

std::string Strategy::getExpressionValueOperatorText(unsigned int expressionValueOperatorId) const {
	// 2 bits, 0 <= expressionValueOperatorId <= 3
	if (expressionValueOperatorId == 0)
		return "+";
	else if (expressionValueOperatorId == 1)
		return "-";
	else if (expressionValueOperatorId == 2)
		return "*";
	else if (expressionValueOperatorId == 3)
		return "/";

	return "";
}

std::string Strategy::getDecisionOperatorText(unsigned int decisionOperatorId) const {
	// 3 bits, 0 <= decisionOperatorId <= 7
	if (decisionOperatorId == 0)
		return "<";
	else if (decisionOperatorId == 1)
		return "<=";
	else if (decisionOperatorId == 2)
		return "==";
	else if (decisionOperatorId == 3)
		return ">=";
	else if (decisionOperatorId == 4)
		return ">";
	else if (decisionOperatorId == 5)
		return "!=";
	else if (decisionOperatorId == 6)
		return "<";
	else if (decisionOperatorId == 7)
		return ">";

	return "";
}

double Strategy::getAmountMultiplierFromId(unsigned int amountMultiplierId) const {
	// 8 bits, 0 <= amountMultiplierId <= 255
	return (double) amountMultiplierId / 255;
}

std::string Strategy::indent(unsigned int tabCount) const {
	std::string indention = "";
	for (unsigned int i = 0; i < tabCount; i++)
		indention += '\t';

	return indention;
}
