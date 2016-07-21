#ifndef PYTHONMANAGER_HPP
#define PYTHONMANAGER_HPP

#ifdef _DEBUG
#undef _DEBUG
	#include <Python.h>
#define _DEBUG
#else
	#include <Python.h>
#endif
#include "PokerEnumerations.hpp"
#include "StrategyEvaluationDataProvider.hpp"
#include <boost/thread.hpp>
#include <string>

class PythonManager {
public:

	struct PlayerMoveResult {
		PokerEnums::PlayerMove move;
		unsigned int moveAmount;
	};

	// callable from python
	static PyObject* getMoveForDecisionTreeUnit(PyObject* self, PyObject* args);
	static PyObject* getMoveAmountForDecisionTreeUnit(PyObject* self, PyObject* args);
	static PyObject* getExpressionValue(PyObject* self, PyObject* args);
	static PyObject* setResults(PyObject* self, PyObject* args);

	PythonManager();
	~PythonManager();
	PlayerMoveResult executeDecisionProcedure(StrategyEvaluationDataProvider* stratEvalDataProvider, PyObject* decisionProcedure);
	PyObject* compileDecisionProcedure(const std::string& procedureText);
	void decreaseReferenceCount(PyObject* pyObject);

private:
	boost::mutex pythonMutex;
	static StrategyEvaluationDataProvider* stratEvalDataProvider;
	PyObject* mainDictionary;
	PyMethodDef embeddedMethods[5];
	static PlayerMoveResult executionResult;
};

#endif
