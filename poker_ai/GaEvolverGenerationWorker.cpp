#include "GaEvolverGenerationWorker.hpp"
#include "TournamentController.hpp"
#include <string>

GaEvolverGenerationWorker::GaEvolverGenerationWorker(
	oracle::occi::StatelessConnectionPool* connectionPool,
	unsigned int trialId,
	const std::string& workerId,
	StrategyManager* strategyManager,
	unsigned int initialGenerationNumber,
	bool loggingEnabled
) {
	this->connectionPool = connectionPool;
	this->trialId = trialId;
	this->workerId = workerId;
	this->strategyManager = strategyManager;
	currentGenerationNumber = initialGenerationNumber;
	this->loggingEnabled = loggingEnabled;
}

void GaEvolverGenerationWorker::startThread() {
	workerThread = boost::thread(&GaEvolverGenerationWorker::threadLoop, this);
}

void GaEvolverGenerationWorker::threadLoop() {

	con = connectionPool->getConnection();
	logger.initialize(con);
	logger.setLoggingEnabled(loggingEnabled);
	bool verboseOutput = false;
	int result;
	std::string resultStringPrefix = workerId + " stepping generation call returned ";

	std::string procCall = "BEGIN :1 := pkg_ga_evolver.step_generation(";
	procCall.append("p_trial_id => :2");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement();
	statement->setSQL(procCall);
	statement->registerOutParam(1, oracle::occi::OCCIINT);
	statement->setUInt(2, trialId);

	do {
		statement->execute();
		result = statement->getInt(1);

		if (verboseOutput && result == 0) {
			logger.log(0, resultStringPrefix + "0: tournament runner work remains");
		}
		else if (result == 1) {
			logger.log(0, resultStringPrefix + "1: create next generation");
			createNextGeneration();
		}
		else if (result == -1) {
			logger.log(0, resultStringPrefix + "-1: stop, no work to perform");
		}

		Sleep(1000);

	} while (result != -1);
	con->terminateStatement(statement);

	// mark trial complete
	procCall = "BEGIN pkg_ga_evolver.mark_trial_complete(";
	procCall.append("p_trial_id => :1");
	procCall.append("); END; ");
	statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->execute();
	con->terminateStatement(statement);

	connectionPool->releaseConnection(con);
}

void GaEvolverGenerationWorker::createNextGeneration() {

	logger.log(0, "creating new generation");

	// call for strategies to use as parents
	std::string procCall = "BEGIN pkg_ga_evolver.select_parent_generation(";
	procCall.append("p_trial_id   => :1, ");
	procCall.append("p_generation => :2, ");
	procCall.append("p_parents    => :3");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->setUInt(2, currentGenerationNumber);
	statement->registerOutParam(3, oracle::occi::OCCICURSOR);
	statement->execute();

	// evolution work here....
	oracle::occi::ResultSet* parentsRs = statement->getCursor(3);
	parentsRs->next();
	unsigned int generationSize = parentsRs->getUInt(1);

	strategyManager->flush();

	// debug - create dummy strategies
	currentGenerationNumber++;
	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->generateRandomStrategy(currentGenerationNumber);
	}

	statement->closeResultSet(parentsRs);
	con->terminateStatement(statement);

	// mark generation as created and enqueue tournements for new generation
	procCall = "BEGIN pkg_ga_evolver.set_current_generation(";
	procCall.append("p_trial_id           => :1, ");
	procCall.append("p_current_generation => :2");
	procCall.append("); END; ");
	statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->setUInt(2, currentGenerationNumber);
	statement->execute();
	con->terminateStatement(statement);

	logger.log(0, "generation " + std::to_string(currentGenerationNumber) + " created and tournaments queued");
}

void GaEvolverGenerationWorker::threadJoin() {
	workerThread.join();
}
