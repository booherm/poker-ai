#include "Strategy.hpp"

void Strategy::initialize(
	//oracle::occi::StatelessConnectionPool* connectionPool,
	oracle::occi::Connection* con,
	PythonManager* pythonManager,
	bool loggingEnabled
) {
	//this->connectionPool = connectionPool;
	//con = connectionPool->getConnection();
	this->con = con;
	logger.initialize(con);
	logger.setLoggingEnabled(loggingEnabled);
	this->pythonManager = pythonManager;
}

void Strategy::assignNewStrategyId() {

	// call for a new unique strategy id
	std::string procCall = "BEGIN :1 := pkg_poker_ai.get_new_strategy_id; END;";
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->registerOutParam(1, oracle::occi::OCCIUNSIGNED_INT);
	statement->execute();
	unsigned int freshStrategyId = statement->getUInt(1);
	con->terminateStatement(statement);

	strategyId = freshStrategyId;
}

void Strategy::loadById(unsigned int loadStrategyId) {

	std::string procCall = "BEGIN pkg_poker_ai.select_strategy(";
	procCall.append("p_strategy_id => :1, ");
	procCall.append("p_result      => :2");
	procCall.append("); END;");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, loadStrategyId);
	statement->registerOutParam(2, oracle::occi::OCCICURSOR);
	statement->execute();
	oracle::occi::ResultSet* resultSet = statement->getCursor(2);
	
	if (resultSet->next()) {
		strategyId = resultSet->getUInt(1);
		generation = resultSet->getUInt(2);
		
		// strategy chromosome
		std::string strategyChromosomeClobString;
		Util::clobToString(resultSet->getClob(3), strategyChromosomeClobString);
		chromosome.clear();
		unsigned int strategyChromosomeLength = strategyChromosomeClobString.length();
		for (unsigned int i = 0; i < strategyChromosomeLength; i++) {
			chromosome.push_back(strategyChromosomeClobString[i] == '1');
		}

		// rebuild decision unit tree
		setDecisionTreeAttributes();

		// strategy procedure
		Util::clobToString(resultSet->getClob(4), decisionProcedure);
		compiledDecisionProcedure = pythonManager->compileDecisionProcedure(decisionProcedure);

		logger.log(0, "Strategy " + std::to_string(strategyId) + " loaded from database");
	}
	else {
		// strategy not found, generate from random
		strategyId = loadStrategyId;
		generateFromRandom(1);
		logger.log(0, "Strategy " + std::to_string(strategyId) + " not found on database, generated from random");
	}

	statement->closeResultSet(resultSet);
	con->terminateStatement(statement);
}

unsigned int Strategy::generateFromRandom(unsigned int generation) {

	chromosome.clear();
	for (unsigned int i = 0; i < chromosomeBitLength; i++) {
		chromosome.push_back(randomNumberGenerator.getRandomBool());
	}

	if (compiledDecisionProcedure != nullptr) {
		pythonManager->decreaseReferenceCount(compiledDecisionProcedure);
	}
	generateDecisionProcedure();

	assignNewStrategyId();
	this->generation = generation;

	save();

	return strategyId;
}

void Strategy::generateDecisionProcedure() {
	setDecisionTreeAttributes();
	decisionProcedure = "amountMultiplier = 1.0\n";
	decisionProcedure += getDecisionTree(0);
	compiledDecisionProcedure = pythonManager->compileDecisionProcedure(decisionProcedure);
}

std::vector<bool>* Strategy::getChromosome() {
	return &chromosome;
}

unsigned int Strategy::getStrategyId() const {
	return strategyId;
}

unsigned int Strategy::getGeneration() const {
	return generation;
}

void Strategy::setGeneration(unsigned int generation) {
	this->generation = generation;
}

void Strategy::save() {

	// strategy chromosome
	std::string strategyChromosomeString = "";
	for (unsigned int i = 0; i < chromosome.size(); i++) {
		strategyChromosomeString.append(chromosome[i] ? "1" : "0");
	}

	std::string procCall = "BEGIN DBMS_LOB.CREATETEMPORARY(:1, FALSE); END;";
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->registerOutParam(1, oracle::occi::OCCICLOB);
	statement->execute();
	oracle::occi::Clob strategyChromosomeClob = statement->getClob(1);
	strategyChromosomeClob.write(strategyChromosomeString.length(), (unsigned char*) &strategyChromosomeString[0], strategyChromosomeString.length());

	// strategy procedure
	statement->execute();
	oracle::occi::Clob strategyProcedureClob = statement->getClob(1);
	strategyProcedureClob.write(decisionProcedure.length(), (unsigned char*) &decisionProcedure[0], decisionProcedure.length());
	con->terminateStatement(statement);

	// save to database
	procCall = "BEGIN pkg_poker_ai.upsert_strategy(";
	procCall.append("p_strategy_id         => :1, ");
	procCall.append("p_generation          => :2, ");
	procCall.append("p_strategy_chromosome => :3, ");
	procCall.append("p_strategy_procedure  => :4");
	procCall.append("); END;");
	statement = con->createStatement(procCall);
	statement->setUInt(1, strategyId);
	statement->setUInt(2, generation);
	statement->setClob(3, strategyChromosomeClob);
	statement->setClob(4, strategyProcedureClob);
	statement->execute();
	con->terminateStatement(statement);
	con->commit();
	
	logger.log(0, "Strategy " + std::to_string(strategyId) + " saved to database");
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
	//connectionPool->releaseConnection(con);
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

	// convert from bit string to unsigned int
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
