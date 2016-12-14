#include "Strategy.hpp"

void Strategy::initialize(
	oracle::occi::Connection* con,
	PythonManager* pythonManager,
	bool loggingEnabled
) {
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
	strategyUnits.clear();

	if (resultSet->next()) {
		strategyId = resultSet->getUInt(1);
		generation = resultSet->getUInt(2);
		
		// strategy units
		for (unsigned int strategyUnitId = 0; strategyUnitId < strategyUnitCount; strategyUnitId++) {

			StrategyUnit s;
			strategyUnits.push_back(s);
			StrategyUnit* strategyUnit = &strategyUnits[strategyUnitId];

			// chromosome
			std::string strategyChromosomeClobString;
			Util::clobToString(resultSet->getClob(3 + strategyUnitId), strategyChromosomeClobString);
			std::vector<bool>* chromosome = &strategyUnit->chromosome;
			for (unsigned int i = 0; i < chromosomeBitLength; i++)
				chromosome->push_back(strategyChromosomeClobString[i] == '1');

			// rebuild decision unit tree
			setDecisionTreeAttributes(strategyUnitId);

			// strategy procedure
			Util::clobToString(resultSet->getClob(4 + strategyUnitId), strategyUnit->decisionProcedure);
			strategyUnit->compiledDecisionProcedure = pythonManager->compileDecisionProcedure(strategyUnit->decisionProcedure);
		}

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

	strategyUnits.clear();

	for (unsigned int strategyUnitId = 0; strategyUnitId < strategyUnitCount; strategyUnitId++) {
		StrategyUnit s;
		strategyUnits.push_back(s);
		StrategyUnit* strategyUnit = &strategyUnits[strategyUnitId];

		std::vector<bool>* chromosome = &strategyUnit->chromosome;
		for (unsigned int i = 0; i < chromosomeBitLength; i++) {
			chromosome->push_back(randomNumberGenerator.getRandomBool());
		}

		generateDecisionProcedure(strategyUnitId);
	}

	assignNewStrategyId();
	this->generation = generation;

	save();

	return strategyId;
}

void Strategy::generateStrategyUnitDecisionProcedures() {
	for (unsigned int i = 0; i < strategyUnitCount; i++)
		generateDecisionProcedure(i);
}

void Strategy::generateDecisionProcedure(unsigned int strategyUnitId) {
	setDecisionTreeAttributes(strategyUnitId);
	StrategyUnit* strategyUnit = &strategyUnits[strategyUnitId];
	std::string* decisionProcedure = &strategyUnit->decisionProcedure;

	decisionProcedure->assign("amountMultiplier = 1.0\n");
	decisionProcedure->append(getDecisionTree(strategyUnitId, 0));
	strategyUnit->compiledDecisionProcedure = pythonManager->compileDecisionProcedure(*decisionProcedure);
}

std::vector<bool>* Strategy::getChromosome(unsigned int strategyUnitId) {
	return &strategyUnits[strategyUnitId].chromosome;
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

void Strategy::setTrialId(unsigned int trialId) {
	this->trialId = trialId;
}

void Strategy::save() {

	// statement for creating a clob
	std::string createClobProcCall = "BEGIN DBMS_LOB.CREATETEMPORARY(:1, FALSE); END;";
	oracle::occi::Statement* createClobStatement = con->createStatement(createClobProcCall);
	createClobStatement->registerOutParam(1, oracle::occi::OCCICLOB);

	// statement for saving to database
	std::string upsertProcCall = "BEGIN pkg_poker_ai.upsert_strategy(";
	upsertProcCall.append("p_trial_id              => :1, ");
	upsertProcCall.append("p_generation            => :2, ");
	upsertProcCall.append("p_strategy_id           => :3, ");
	upsertProcCall.append("p_strategy_chromosome_1 => :4, ");
	upsertProcCall.append("p_strategy_procedure_1  => :5, ");
	upsertProcCall.append("p_strategy_chromosome_2 => :6, ");
	upsertProcCall.append("p_strategy_procedure_2  => :7, ");
	upsertProcCall.append("p_strategy_chromosome_3 => :8, ");
	upsertProcCall.append("p_strategy_procedure_3  => :9, ");
	upsertProcCall.append("p_strategy_chromosome_4 => :10, ");
	upsertProcCall.append("p_strategy_procedure_4  => :11");
	upsertProcCall.append("); END;");
	oracle::occi::Statement* upsertStatement = con->createStatement(upsertProcCall);
	upsertStatement->setUInt(1, trialId);
	upsertStatement->setUInt(2, generation);
	upsertStatement->setUInt(3, strategyId);

	// strategy units
	for (unsigned int strategyUnitId = 0; strategyUnitId < strategyUnitCount; strategyUnitId++) {
		
		StrategyUnit* strategyUnit = &strategyUnits[strategyUnitId];

		// convert chromosome bit string to text string
		std::vector<bool>* chromosome = &strategyUnit->chromosome;
		std::string strategyChromosomeString = "";
		for (unsigned int i = 0; i < chromosomeBitLength; i++) {
			strategyChromosomeString.append(chromosome->at(i) ? "1" : "0");
		}

		// convert chromosome text string to clob and bind 
		createClobStatement->execute();
		oracle::occi::Clob strategyChromosomeClob = createClobStatement->getClob(1);
		strategyChromosomeClob.write(chromosomeBitLength, (unsigned char*) &strategyChromosomeString[0], chromosomeBitLength);
		upsertStatement->setClob(4 + strategyUnitId, strategyChromosomeClob);

		// strategy procedure
		createClobStatement->execute();
		oracle::occi::Clob strategyProcedureClob = createClobStatement->getClob(1);
		unsigned int procLength = strategyUnit->decisionProcedure.length();
		strategyProcedureClob.write(procLength, (unsigned char*) &strategyUnit->decisionProcedure[0], procLength);
		upsertStatement->setClob(5 + strategyUnitId, strategyProcedureClob);
	}
	con->terminateStatement(createClobStatement);

//	upsertStatement->execute();
	con->terminateStatement(upsertStatement);
	con->commit();
	
	logger.log(0, "Strategy " + std::to_string(strategyId) + " saved to database");
}

Strategy::ValueExpression* Strategy::getValueExpression(unsigned int strategyUnitId, unsigned int expId) {

	std::vector<DecisionTreeUnit>* dtus = &strategyUnits[strategyUnitId].decisionTreeUnits;

	for (unsigned int i = 0; i < dtus->size(); i++) {
		DecisionTreeUnit* dtu = &dtus->at(i);

		if (dtu->leftValueExpression.valueExpressionSlotId == expId)
			return &dtu->leftValueExpression;

		if (dtu->rightValueExpression.valueExpressionSlotId == expId)
			return &dtu->rightValueExpression;
	}

	return nullptr;
}

Strategy::~Strategy() {
	for (unsigned int i = 0; i < strategyUnitCount; i++) {
		pythonManager->decreaseReferenceCount(strategyUnits[i].compiledDecisionProcedure);
	}
}

void Strategy::setDecisionTreeAttributes(unsigned int strategyUnitId) {

	StrategyUnit* strategyUnit = &strategyUnits[strategyUnitId];
	std::vector<DecisionTreeUnit>* decisionTreeUnits = &strategyUnit->decisionTreeUnits;
	std::vector<bool>* chromosome = &strategyUnit->chromosome;

	for (unsigned int i = 0; i < decisionTreeUnitSlots; i++) {

		decisionTreeUnits->push_back(DecisionTreeUnit());
		DecisionTreeUnit* dtu = &decisionTreeUnits->at(i);

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

		getChromosomeSection(chromosome,
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength,
			dtu->leftValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString);
		getChromosomeSection(chromosome,
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex,
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength,
			dtu->leftValueExpression.valueExpressionOperator.valueExpressionOperatorBitString);
		getChromosomeSection(chromosome,
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength,
			dtu->leftValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString);

		getChromosomeSection(chromosome, 
			dtu->decisionOperator.decisionOperatorChromosomeStartIndex,
			dtu->decisionOperator.decisionOperatorBitStringLength,
			dtu->decisionOperator.decisionOperatorBitString);

		getChromosomeSection(chromosome, 
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitStringLength,
			dtu->rightValueExpression.leftValueExpressionOperand.valueExpressionOperandBitString);
		getChromosomeSection(chromosome, 
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorChromosomeStartIndex,
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitStringLength,
			dtu->rightValueExpression.valueExpressionOperator.valueExpressionOperatorBitString);
		getChromosomeSection(chromosome, 
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandChromosomeStartIndex,
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitStringLength,
			dtu->rightValueExpression.rightValueExpressionOperand.valueExpressionOperandBitString);

		getChromosomeSection(chromosome, 
			dtu->leftAmountMultiplier.amountMultiplierChromosomeStartIndex,
			dtu->leftAmountMultiplier.amountMultiplierBitStringLength,
			dtu->leftAmountMultiplier.amountMultiplierBitString);

		getChromosomeSection(chromosome, 
			dtu->rightAmountMultiplier.amountMultiplierChromosomeStartIndex,
			dtu->rightAmountMultiplier.amountMultiplierBitStringLength,
			dtu->rightAmountMultiplier.amountMultiplierBitString);

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

std::string Strategy::getDecisionTree(unsigned int strategyUnitId, unsigned int decisionTreeUnitId) const {

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

		const DecisionTreeUnit* dtu = &strategyUnits[strategyUnitId].decisionTreeUnits[decisionTreeUnitId];
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
		treeCode += getDecisionTree(strategyUnitId, (2 * decisionTreeUnitId) + 1);

		treeCode += indent(depth) + "else:\n";

		// right branch amount multiplier
		treeCode += indent(depth + 1) + "amountMultiplier *= " + std::to_string(getAmountMultiplierFromId(dtu->rightAmountMultiplier.amountMultiplierId)) + "\n";

		// right branch decision tree
		treeCode += getDecisionTree(strategyUnitId, (2 * decisionTreeUnitId) + 2);
	}

	return treeCode;
}

void Strategy::getChromosomeSection(std::vector<bool>* chromosome, unsigned int startIndex, unsigned int length, std::vector<bool>& destination) {
	std::vector<bool>::iterator i = chromosome->begin() + startIndex;
	destination = std::vector<bool>(i, i + length);
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
