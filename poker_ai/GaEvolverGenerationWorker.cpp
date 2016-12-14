#include "GaEvolverGenerationWorker.hpp"
#include "TournamentController.hpp"
#include <string>

GaEvolverGenerationWorker::GaEvolverGenerationWorker(
	DbConnectionManager* dbConnectionManager,
	unsigned int trialId,
	const std::string& workerId,
	StrategyManager* strategyManager,
	unsigned int initialGenerationNumber,
	bool loggingEnabled
) {
	this->dbConnectionManager = dbConnectionManager;
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

	int result = 0;
	con = dbConnectionManager->getConnection();

	while (result != -1) {

		try {

			logger.initialize(con);
			logger.setLoggingEnabled(loggingEnabled);
			bool verboseOutput = false;
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

			dbConnectionManager->releaseConnection(con);

		}
		catch (const oracle::occi::SQLException& e) {

			// connection lost contact, re-establish
			std::cout << "oracle::occi::SQLException - " << e.what() << std::endl;
			dbConnectionManager->releaseConnection(con);
			Sleep(5000);
			con = dbConnectionManager->getConnection();

			if (generationCreationInProgress) {
				// cleanup and restart generation creation
				std::string procCall = "BEGIN :1 := pkg_ga_evolver.clean_interrupted_gen_create(";
				procCall.append("p_trial_id => :2");
				procCall.append("); END; ");
				oracle::occi::Statement* statement = con->createStatement(procCall);
				statement->registerOutParam(1, oracle::occi::OCCIUNSIGNED_INT);
				statement->setUInt(2, trialId);
				statement->execute();
				currentGenerationNumber = statement->getUInt(1);
				con->terminateStatement(statement);
				createNextGeneration();
			}

			std::cout << workerId << " recovered" << std::endl;

		}
		catch (const std::exception& e) {
			std::cout << "unknown exception: " << e.what() << std::endl;
		}
		catch (const std::string& e) {
			std::cout << "unknown exception: " << e << std::endl;
		}
		catch (...) {
			std::cout << "unknown exception" << std::endl;
		}
	}
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

	logger.log(0, workerId + ": creating new generation " + std::to_string(currentGenerationNumber + 1));
	generationCreationInProgress = true;

	updateStrategyFitness();

	// debug, could purge tournament reuslts here or in update proc

	// call for strategies to use as parents
	std::string procCall = "BEGIN pkg_ga_evolver.select_parent_generation(";
	procCall.append("p_trial_id         => :1, ");
	procCall.append("p_generation       => :2, ");
	procCall.append("p_trial_attributes => :3, ");
	procCall.append("p_carry_overs      => :4, ");
	procCall.append("p_parents          => :5");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement(procCall);
	statement->setUInt(1, trialId);
	statement->setUInt(2, currentGenerationNumber);
	statement->registerOutParam(3, oracle::occi::OCCICURSOR);
	statement->registerOutParam(4, oracle::occi::OCCICURSOR);
	statement->registerOutParam(5, oracle::occi::OCCICURSOR);
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

	// best n strategies get automatically carried on to the next generation as is
	oracle::occi::ResultSet* carryOversRs = statement->getCursor(4);
	while (carryOversRs->next()) {
		Strategy* carryOverParent = strategyManager->getStrategy(carryOversRs->getUInt(1));
		Strategy* carryOverChildA = strategyManager->createStrategy();
		Strategy* carryOverChildB = strategyManager->createStrategy();
		carryOverChildA->setTrialId(trialId);
		carryOverChildB->setTrialId(trialId);
		carryOverChildA->setGeneration(currentGenerationNumber);
		carryOverChildB->setGeneration(currentGenerationNumber);
		carryOverChildA->assignNewStrategyId();
		carryOverChildB->assignNewStrategyId();
		copyChromosomes(carryOverParent, carryOverChildA);
		copyChromosomes(carryOverParent, carryOverChildB);
		carryOverChildA->generateStrategyUnitDecisionProcedures();
		carryOverChildB->generateStrategyUnitDecisionProcedures();
		carryOverChildA->save();
		carryOverChildB->save();
		newGeneration.push_back(carryOverChildA);
		newGeneration.push_back(carryOverChildB);
	}
	statement->closeResultSet(carryOversRs);

	// breed from parent generation
	oracle::occi::ResultSet* parentsRs = statement->getCursor(5);
	while (parentsRs->next()) {

		unsigned int parentAStrategyId = parentsRs->getUInt(2);
		unsigned int parentBStrategyId = parentsRs->getUInt(3);
		Strategy* parentA = strategyManager->getStrategy(parentAStrategyId);
		Strategy* parentB = strategyManager->getStrategy(parentBStrategyId);
		Strategy* childA = strategyManager->createStrategy();
		Strategy* childB = strategyManager->createStrategy();
		childA->setTrialId(trialId);
		childB->setTrialId(trialId);
		childA->setGeneration(currentGenerationNumber);
		childB->setGeneration(currentGenerationNumber);
		childA->assignNewStrategyId();
		childB->assignNewStrategyId();

		// by strategy unit (chromosome)
		for (unsigned int strategyUnitId = 0; strategyUnitId < parentA->strategyUnitCount; strategyUnitId++)
		{
			// crossover
			bool shouldPerformCrossover = parentsRs->getUInt(1) == 1;
			if (shouldPerformCrossover) {
				performCrossover(parentA, parentB, crossoverPoint, childA, childB);
			}
			else {
				copyStrategyUnit(strategyUnitId, parentA, childA);
				copyStrategyUnit(strategyUnitId, parentB, childB);
			}

			// mutate
			mutateChromosome(strategyUnitId, childA, mutationRate);
			mutateChromosome(strategyUnitId, childB, mutationRate);
		}

		childA->generateStrategyUnitDecisionProcedures();
		childB->generateStrategyUnitDecisionProcedures();
		childA->save();
		childB->save();
		newGeneration.push_back(childA);
		newGeneration.push_back(childB);
	}
	statement->closeResultSet(parentsRs);

	/*
	// breed from parent generation
	oracle::occi::ResultSet* parentsRs = statement->getCursor(5);
	while (parentsRs->next()) {

		unsigned int parentAStrategyId = parentsRs->getUInt(2);
		unsigned int parentBStrategyId = parentsRs->getUInt(3);
		Strategy* parentA = strategyManager->getStrategy(parentAStrategyId);
		Strategy* parentB = strategyManager->getStrategy(parentBStrategyId);
		Strategy* childA = strategyManager->createStrategy();
		Strategy* childB = strategyManager->createStrategy();
		childA->setTrialId(trialId);
		childB->setTrialId(trialId);
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

		childA->generateStrategyUnitDecisionProcedures();
		childB->generateStrategyUnitDecisionProcedures();
		childA->save();
		childB->save();
		newGeneration.push_back(childA);
		newGeneration.push_back(childB);
	}
	statement->closeResultSet(parentsRs);
	*/

	con->terminateStatement(statement);

	// set new generation
	for (unsigned int i = 0; i < generationSize; i++) {
		strategyManager->setStrategy(newGeneration[i]);
	}
	strategyManager->setGenerationLoaded(currentGenerationNumber);

	generationCreationInProgress = false;

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

	logger.log(0, workerId + ": generation " + std::to_string(currentGenerationNumber) + " created and tournaments queued");
}

void GaEvolverGenerationWorker::threadJoin() {
	workerThread.join();
}

void GaEvolverGenerationWorker::performCrossover(Strategy* parentA, Strategy* parentB, unsigned int crossoverPoint, Strategy* childA, Strategy* childB) {

	unsigned int strategyUnitId = 0;
	std::vector<bool>* parentAChromosome = parentA->getChromosome(strategyUnitId);
	std::vector<bool>* parentBChromosome = parentB->getChromosome(strategyUnitId);
	std::vector<bool>* childAChromosome = childA->getChromosome(strategyUnitId);
	std::vector<bool>* childBChromosome = childB->getChromosome(strategyUnitId);
	unsigned int chromosomeLength = parentAChromosome->size();

	// do some magic

	// known: how many times the decision procedure got executed.
	// each DTU will have been executed (n / total decision tree executions) 
	// sort parents by fitness.  Weight strength   Paths executed that 


	/*
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
	*/

}

void GaEvolverGenerationWorker::copyChromosomes(Strategy* source, Strategy* destination) {

	for (unsigned int su = 0; su < source->strategyUnitCount; su++) {
		std::vector<bool>* sourceChromosome = source->getChromosome(su);
		std::vector<bool>* destinationChromosome = destination->getChromosome(su);
		unsigned int chromosomeLength = sourceChromosome->size();

		for (unsigned int i = 0; i < chromosomeLength; i++) {
			destinationChromosome->push_back(sourceChromosome->at(i));
		}
	}
}

void GaEvolverGenerationWorker::copyStrategyUnit(unsigned int strategyUnitId, Strategy* source, Strategy* destination) {

	std::vector<bool>* sourceChromosome = source->getChromosome(strategyUnitId);
	std::vector<bool>* destinationChromosome = destination->getChromosome(strategyUnitId);
	unsigned int chromosomeLength = sourceChromosome->size();
	destinationChromosome->clear();

	for (unsigned int i = 0; i < chromosomeLength; i++) {
		destinationChromosome->push_back(sourceChromosome->at(i));
	}

}

void GaEvolverGenerationWorker::mutateChromosome(unsigned int strategyUnitId, Strategy* strategy, float mutationRate) {

	std::vector<bool>* strategyChromosome = strategy->getChromosome(strategyUnitId);
	unsigned int chromosomeLength = strategyChromosome->size();

	for (unsigned int i = 0; i < chromosomeLength; i++) {
		float randomValue = randomNumberGenerator.getRandomFloat(0.0f, 1.0f);
		if (randomValue <= mutationRate)
			strategyChromosome->at(i) = !strategyChromosome->at(i);
	}
	
}