#include "PythonManager.hpp"
#include "StrategyEvaluationDataProvider.hpp"

PythonManager::PlayerMoveResult PythonManager::executionResult;
StrategyEvaluationDataProvider* PythonManager::stratEvalDataProvider;

PyObject* PythonManager::getMoveForDecisionTreeUnit(PyObject* self, PyObject* args) {
	unsigned int decisionTreeUnitId;
	PyArg_ParseTuple(args, "i", &decisionTreeUnitId);

	PokerEnums::PlayerMove playerMove = stratEvalDataProvider->getMoveForDecisionTreeUnit(decisionTreeUnitId);

	return Py_BuildValue("i", playerMove);
}

PyObject* PythonManager::getMoveAmountForDecisionTreeUnit(PyObject* self, PyObject* args) {
	float amountMultiplier;
	PyArg_ParseTuple(args, "f", &amountMultiplier);

	unsigned int moveAmount = stratEvalDataProvider->getMoveAmountForDecisionTreeUnit(amountMultiplier);

	return Py_BuildValue("i", moveAmount);
}

PyObject* PythonManager::getExpressionValue(PyObject* self, PyObject* args) {
	unsigned int expressionId;
	PyArg_ParseTuple(args, "i", &expressionId);

	float expressionValue = stratEvalDataProvider->getExpressionValue(expressionId);

	return Py_BuildValue("f", expressionValue);
}

PyObject* PythonManager::setResults(PyObject* self, PyObject* args) {
	PyArg_ParseTuple(args, "ii", &executionResult.move, &executionResult.moveAmount);
	Py_RETURN_NONE;
}

PythonManager::PythonManager() {

	Py_Initialize();
	
	// init cpp extensions
	embeddedMethods[0] = { "getMoveForDecisionTreeUnit", PythonManager::getMoveForDecisionTreeUnit, METH_VARARGS, "retrieves a move decision for a given decision tree unit" };
	embeddedMethods[1] = { "getMoveAmountForDecisionTreeUnit", PythonManager::getMoveAmountForDecisionTreeUnit, METH_VARARGS, "retrieves move amount for a given decision tree unit" };
	embeddedMethods[2] = { "getExpressionValue", PythonManager::getExpressionValue, METH_VARARGS, "retrieves a value for an expression ID" };
	embeddedMethods[3] = { "setResults", PythonManager::setResults, METH_VARARGS, "sets results in cpp" };
	embeddedMethods[4] = { NULL, NULL, 0, NULL };

	Py_InitModule("embeddedMethods", embeddedMethods);

	PyObject* mainModule = PyImport_AddModule("__main__");
	mainDictionary = PyModule_GetDict(mainModule);

	std::string pythonInit = "import embeddedMethods\n"
		"def safeDenom(denominator):\n"
		"\tif denominator == 0:\n"
		"\t\treturn 1\n"
		"\telse:\n"
		"\t\treturn denominator\n";

	PyRun_SimpleString(pythonInit.c_str());

}

PythonManager::~PythonManager() {
	Py_Finalize();
}

PythonManager::PlayerMoveResult PythonManager::executeDecisionProcedure(StrategyEvaluationDataProvider* stratEvalDataProvider, PyObject* decisionProcedure) {

	pythonMutex.lock();
	PyGILState_STATE gilState = PyGILState_Ensure();
	this->stratEvalDataProvider = stratEvalDataProvider;
	PyObject* exeuctionResultObject = PyEval_EvalCode((PyCodeObject*) decisionProcedure, mainDictionary, mainDictionary);
	decreaseReferenceCount(exeuctionResultObject);
	if ((executionResult.move == PokerEnums::PlayerMove::BET || executionResult.move == PokerEnums::PlayerMove::RAISE) && executionResult.moveAmount > 5000) {
		int x = 0;
	}
	PlayerMoveResult playerMoveResult = executionResult;
	PyGILState_Release(gilState);
	pythonMutex.unlock();

	if ((playerMoveResult.move == PokerEnums::PlayerMove::BET || playerMoveResult.move == PokerEnums::PlayerMove::RAISE) && playerMoveResult.moveAmount > 5000) {
		int x = 0;

	}

	return playerMoveResult;
}

PyObject* PythonManager::compileDecisionProcedure(const std::string& procedureText) {

	pythonMutex.lock();
	PyObject* compiledProcedure = Py_CompileString(procedureText.c_str(), "somefilename", Py_file_input);
	pythonMutex.unlock();

	/*
	PyObject* errorOccurred = PyErr_Occurred();
	if (errorOccurred) {
		std::cout << "python error" << std::endl;

		PyObject* errorType;
		PyObject* errorValue;
		PyObject* errorTraceBack;

		PyErr_Fetch(&errorType, &errorValue, &errorTraceBack);
		char* errorTest = PyString_AsString(errorValue);
		
		std::cout << "python error variables gathered" << std::endl;
	}
	*/

	return compiledProcedure;
}

void PythonManager::decreaseReferenceCount(PyObject* pyObject) {
	Py_DECREF(pyObject);
}
