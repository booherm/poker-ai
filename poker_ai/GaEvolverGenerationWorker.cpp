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
			updateStrategyFitness();
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

void GaEvolverGenerationWorker::updateStrategyFitness() {

	// calculate strategy fitness
	std::string procCall = "BEGIN pkg_ga_evolver.update_strategy_fitness(";
	procCall.append("p_trial_id => :1");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->execute();
	con->terminateStatement(statement);

}

void GaEvolverGenerationWorker::createNextGeneration() {

	logger.log(0, "creating new generation");
	
	updateStrategyFitness();

	// debug, could purge tournament reuslts here or in update proc

	// call for strategies to use as parents
	std::string procCall = "BEGIN pkg_ga_evolver.select_parent_generation(";
	procCall.append("p_trial_id         => :1, ");
	procCall.append("p_generation       => :2, ");
	procCall.append("p_trial_attributes => :3, ");
	procCall.append("p_parents          => :4");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->setUInt(2, currentGenerationNumber);
	statement->registerOutParam(3, oracle::occi::OCCICURSOR);
	statement->registerOutParam(4, oracle::occi::OCCICURSOR);
	statement->execute();

	// get evolution trial attributes
	oracle::occi::ResultSet* trialAttributesRs = statement->getCursor(3);
	trialAttributesRs->next();
	unsigned int crossoverPoint = trialAttributesRs->getUInt(1);
	float mutationRate = trialAttributesRs->getFloat(2);
	unsigned int generationSize = trialAttributesRs->getUInt(3);
	statement->closeResultSet(trialAttributesRs);

	// perform evolution work
	currentGenerationNumber++;
	std::vector<Strategy*> newGeneration;
	oracle::occi::ResultSet* parentsRs = statement->getCursor(4);
	unsigned int parentRecCount = 0;
	while (parentsRs->next()) {

		// debug
		parentRecCount++;

		unsigned int parentAStrategyId = parentsRs->getUInt(2);
		unsigned int parentBStrategyId = parentsRs->getUInt(3);
		Strategy* parentA = strategyManager->getStrategy(parentAStrategyId);
		Strategy* parentB = strategyManager->getStrategy(parentBStrategyId);
		Strategy* childA = strategyManager->createStrategy();
		Strategy* childB = strategyManager->createStrategy();
		childA->setGeneration(currentGenerationNumber);
		childB->setGeneration(currentGenerationNumber);
		childA->assignNewStrategyId();
		childB->assignNewStrategyId();

		// crossover
		bool shouldPerformCrossover = parentsRs->getUInt(1) == 1;
		if (shouldPerformCrossover) {
			performCrossover(parentA, parentB, crossoverPoint, childA, childB);
		}
		else {
			copyChromosome(parentA, childA);
			copyChromosome(parentB, childB);
		}

		// mutate
		mutateChromosome(childA, mutationRate);
		mutateChromosome(childB, mutationRate);

		childA->generateDecisionProcedure();
		childB->generateDecisionProcedure();
		childA->save();
		childB->save();
		newGeneration.push_back(childA);
		newGeneration.push_back(childB);
	}
	statement->closeResultSet(parentsRs);
	con->terminateStatement(statement);

	// debug
	if (parentRecCount != (generationSize / 2))
		std::cout << "hit generation size bug" << std::endl;

	// clear parent generation
	strategyManager->flush(currentGenerationNumber - 1);

	// set new generation
	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->setStrategy(newGeneration[i]);
	}

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

void GaEvolverGenerationWorker::performCrossover(Strategy* parentA, Strategy* parentB, unsigned int crossoverPoint, Strategy* childA, Strategy* childB) {

	std::vector<bool>* parentAChromosome = parentA->getChromosome();
	std::vector<bool>* parentBChromosome = parentB->getChromosome();
	std::vector<bool>* childAChromosome = childA->getChromosome();
	std::vector<bool>* childBChromosome = childB->getChromosome();
	unsigned int chromosomeLength = parentAChromosome->size();

	for (unsigned int i = 0; i < crossoverPoint; i++) {
		childAChromosome->push_back(parentAChromosome->at(i));
		childBChromosome->push_back(parentBChromosome->at(i));
	}
	for (unsigned int i = crossoverPoint; i < chromosomeLength; i++) {
		childAChromosome->push_back(parentBChromosome->at(i));
		childBChromosome->push_back(parentAChromosome->at(i));
	}

}

void GaEvolverGenerationWorker::copyChromosome(Strategy* source, Strategy* destination) {
	std::vector<bool>* sourceChromosome = source->getChromosome();
	std::vector<bool>* destinationChromosome = destination->getChromosome();
	unsigned int chromosomeLength = sourceChromosome->size();

	for (unsigned int i = 0; i < chromosomeLength; i++) {
		destinationChromosome->push_back(sourceChromosome->at(i));
	}
}

void GaEvolverGenerationWorker::mutateChromosome(Strategy* strategy, float mutationRate) {

	std::vector<bool>* strategyChromosome = strategy->getChromosome();
	unsigned int chromosomeLength = strategyChromosome->size();

	for (unsigned int i = 0; i < chromosomeLength; i++) {
		float randomValue = randomNumberGenerator.getRandomFloat(0.0f, 1.0f);
		if (randomValue <= mutationRate)
			strategyChromosome->at(i) = !strategyChromosome->at(i);
	}
	
}