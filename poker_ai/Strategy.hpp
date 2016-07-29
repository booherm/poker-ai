#ifndef STRATEGY_HPP
#define STRATEGY_HPP

#include <occi.h>
#include <vector>
#include "Logger.hpp"
#include "Util.hpp"
#include "PythonManager.hpp"

class StrategyEvaluationDataProvider;

class Strategy {

	friend class StrategyEvaluationDataProvider;

public:
	void initialize(
		oracle::occi::Connection* con,
		//oracle::occi::StatelessConnectionPool* connectionPool,
		PythonManager* pythonManager,
		bool loggingEnabled
	);
	void assignNewStrategyId();
	void loadById(unsigned int loadStrategyId);
	unsigned int generateFromRandom(unsigned int generation);
	void generateDecisionProcedure();
	std::vector<bool>* getChromosome();
	unsigned int getStrategyId() const;
	unsigned int getGeneration() const;
	void setGeneration(unsigned int generation);
	void save();
	~Strategy();

private:
	struct ValueExpressionOperand {
		std::vector<bool> valueExpressionOperandBitString;
		unsigned int valueExpressionOperandBitStringLength;
		unsigned int valueExpressionOperandChromosomeStartIndex;
		unsigned int valueExpressionOperandId;
	};

	struct ValueExpressionOperator {
		std::vector<bool> valueExpressionOperatorBitString;
		unsigned int valueExpressionOperatorBitStringLength;
		unsigned int valueExpressionOperatorChromosomeStartIndex;
		unsigned int valueExpressionOperatorId;
	};

	struct ValueExpression {
		unsigned int valueExpressionSlotId;
		ValueExpressionOperand leftValueExpressionOperand;
		ValueExpressionOperator valueExpressionOperator;
		ValueExpressionOperand rightValueExpressionOperand;
	};

	struct DecisionOperator {
		std::vector<bool> decisionOperatorBitString;
		unsigned int decisionOperatorBitStringLength;
		unsigned int decisionOperatorChromosomeStartIndex;
		unsigned int decisionOperatorId;
	};

	struct AmountMultiplier {
		std::vector<bool> amountMultiplierBitString;
		unsigned int amountMultiplierBitStringLength;
		unsigned int amountMultiplierChromosomeStartIndex;
		unsigned int amountMultiplierId;
	};

	struct DecisionTreeUnit {
		ValueExpression leftValueExpression;
		DecisionOperator decisionOperator;
		ValueExpression rightValueExpression;
		AmountMultiplier leftAmountMultiplier;
		AmountMultiplier rightAmountMultiplier;
	};

	void setDecisionTreeAttributes();
	std::string getDecisionTree(unsigned int decisionTreeUnitId) const;
	std::vector<bool> getChromosomeSection(unsigned int startIndex, unsigned int length) const;
	unsigned int getIdFromBitString(const std::vector<bool>& bitString) const;
	std::string getExpressionValueOperatorText(unsigned int expressionValueOperatorId) const;
	std::string getDecisionOperatorText(unsigned int decisionOperatorId) const;
	double getAmountMultiplierFromId(unsigned int amountMultiplierId) const;
	ValueExpression* getValueExpression(unsigned int expId);
	std::string indent(unsigned int tabCount) const;

	const unsigned int valueExpressionOperandIdBitLength = 10;
	const unsigned int valueExpressionOperatorIdBitLength = 2;
	const unsigned int decisionOperatorBitLength = 3;
	const unsigned int amountMultiplierBitLength = 8;
	const unsigned int treeDepth = 8;
	const unsigned int valueExpressionBitLength = (2 * valueExpressionOperandIdBitLength) + valueExpressionOperatorIdBitLength; // 22
	const unsigned int decisionTreeUnitBitLength = (2 * valueExpressionBitLength) + decisionOperatorBitLength + (2 * amountMultiplierBitLength); // 44 + 3 + 16 = 63
	const unsigned int decisionTreeUnitSlots = (unsigned int) pow(2, treeDepth - 1) - 1; // 127
	const unsigned int chromosomeBitLength = decisionTreeUnitBitLength * decisionTreeUnitSlots; // 63 * 127 = 8001
	const unsigned int valueExpressionSlotIdCount = 2 * decisionTreeUnitSlots; // 254

	unsigned int strategyId;
	unsigned int generation;
	std::vector<bool> chromosome;
	std::string decisionProcedure;
	std::vector<DecisionTreeUnit> decisionTreeUnits;
	PyObject* compiledDecisionProcedure = nullptr;
	PythonManager* pythonManager;
	//oracle::occi::StatelessConnectionPool* connectionPool;
	oracle::occi::Connection* con;
	Logger logger;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
