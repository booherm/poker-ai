#include "GaEvolverTournamentWorker.hpp"
#include <string>
#include "TournamentController.hpp"
#include "Logger.hpp"
#include <boost/algorithm/string.hpp>

GaEvolverTournamentWorker::GaEvolverTournamentWorker(
	DbConnectionManager* dbConnectionManager,
	PythonManager* pythonManager,
	unsigned int trialId,
	unsigned int controlGeneration,
	const std::string& workerId,
	StrategyManager* strategyManager,
	bool loggingEnabled
) {
	this->dbConnectionManager = dbConnectionManager;
	this->trialId = trialId;
	this->controlGeneration = controlGeneration;
	this->workerId = workerId;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
	this->loggingEnabled = loggingEnabled;
}

void GaEvolverTournamentWorker::startThread() {
	workerThread = boost::thread(&GaEvolverTournamentWorker::threadLoop, this);
}

void GaEvolverTournamentWorker::threadLoop() {
	
	oracle::occi::Connection* con = dbConnectionManager->getConnection();
	int result = 0;

	while (result != -1) {

		try {

			struct TournamentWorkRecord {
				unsigned int tournamentId;
				std::vector<unsigned int> strategyIds;
			};
			std::vector<TournamentWorkRecord> tournamentWorkRecords;
			TournamentWorkRecord tournamentWorkRecordStruct;

			Logger logger;
			logger.initialize(con);
			logger.setLoggingEnabled(loggingEnabled);
			bool verboseOutput = false;
			tournamentResultCollector = new TournamentResultCollector;
			tournamentResultCollector->initialize(dbConnectionManager);

			strategyManager->loadGeneration(trialId, controlGeneration);

			TournamentController tournamentController;
			tournamentController.initialize(dbConnectionManager, pythonManager, strategyManager, tournamentResultCollector);

			std::string resultStringPrefix = workerId + ": selecting tournament work returned ";

			std::string procCall = "BEGIN :1 := pkg_ga_evolver.select_tournament_work(";
			procCall.append("p_worker_id        => :2, ");
			procCall.append("p_trial_id         => :3, ");
			procCall.append("p_trial_attributes => :4, ");
			procCall.append("p_tournament_work  => :5");
			procCall.append("); END; ");
			oracle::occi::Statement* statement = con->createStatement();
			statement->setSQL(procCall);
			statement->registerOutParam(1, oracle::occi::OCCIINT);
			statement->setString(2, workerId);
			statement->setUInt(3, trialId);
			statement->registerOutParam(4, oracle::occi::OCCICURSOR);
			statement->registerOutParam(5, oracle::occi::OCCICURSOR);
			statement->setPrefetchRowCount(100);

			do {
				statement->execute();
				result = statement->getInt(1);

				if (verboseOutput && result == 1) {
					logger.log(0, resultStringPrefix + "1: empty queue, wait for more");

					// release all non-control generations
					strategyManager->flushNonControlGenerations(controlGeneration);
				}
				else if (result == 0) {
					logger.log(0, resultStringPrefix + "0: play tournaments");

					// set common trial attributes
					oracle::occi::ResultSet* trialAttributesRs = statement->getCursor(4);
					trialAttributesRs->next();
					unsigned int generation = trialAttributesRs->getUInt(1);
					unsigned int playerCount = trialAttributesRs->getUInt(2);
					unsigned int tournamentBuyIn = trialAttributesRs->getUInt(3);
					unsigned int initialSmallBlindValue = trialAttributesRs->getUInt(4);
					unsigned int doubleBlindsInterval = trialAttributesRs->getUInt(5);
					statement->closeResultSet(trialAttributesRs);

					// ensure strategy manager has this generation cached
					strategyManager->loadGeneration(trialId, generation);

					// load tournaments to play records
					oracle::occi::ResultSet* tournamentWorkRs = statement->getCursor(5);
					tournamentWorkRecords.clear();
					while (tournamentWorkRs->next()) {
						tournamentWorkRecords.push_back(tournamentWorkRecordStruct);
						TournamentWorkRecord* tournamentWorkRecord = &tournamentWorkRecords[tournamentWorkRecords.size() - 1];
						tournamentWorkRecord->tournamentId = tournamentWorkRs->getUInt(1);

						// collect strategy ids
						std::string strategyStringList;
						Util::clobToString(tournamentWorkRs->getClob(2), strategyStringList);
						std::vector<std::string> strategyIdStrings;
						boost::split(strategyIdStrings, strategyStringList, boost::is_any_of(","));
						for (unsigned int i = 0; i < strategyIdStrings.size(); i++)
							tournamentWorkRecord->strategyIds.push_back(std::stoi(strategyIdStrings[i]));
					}
					statement->closeResultSet(tournamentWorkRs);

					// play tournaments
					for (unsigned int i = 0; i < tournamentWorkRecords.size(); i++) {
						TournamentWorkRecord* tournamentWorkRecord = &tournamentWorkRecords[i];
						if (verboseOutput)
							logger.log(0, workerId + ": begin playing tournament " + std::to_string(tournamentWorkRecord->tournamentId));
						tournamentController.playAutomatedTournament(
							trialId,
							tournamentWorkRecord->tournamentId,
							tournamentWorkRecord->strategyIds,
							playerCount,
							tournamentBuyIn,
							initialSmallBlindValue,
							doubleBlindsInterval,
							false,                         // perform state logging
							false                          // perform general logging
							);
						if (verboseOutput)
							logger.log(0, workerId + ": end playing tournament " + std::to_string(tournamentWorkRecord->tournamentId));
					}

					// write tournament results to database
					tournamentResultCollector->writeToDatabase();

					/*
					while (tournamentWorkRs->next()) {

						unsigned int tournamentId = tournamentWorkRs->getUInt(1);
						logger.log(0, "begin playing tournament " + std::to_string(tournamentId));

						// collect strategy ids
						std::string strategyStringList;
						Util::clobToString(tournamentWorkRs->getClob(3), strategyStringList);
						std::vector<std::string> strategyIdStrings;
						boost::split(strategyIdStrings, strategyStringList, boost::is_any_of(","));
						std::vector<unsigned int> strategyIds;
						for (unsigned int i = 0; i < strategyIdStrings.size(); i++)
							strategyIds.push_back(std::stoi(strategyIdStrings[i]));

						tournamentController.playAutomatedTournament(
							trialId,
							tournamentId,
							strategyIds,
							tournamentWorkRs->getUInt(2),  // player count
							tournamentWorkRs->getUInt(4),  // tournament buy in
							tournamentWorkRs->getUInt(5),  // initial small blind value
							tournamentWorkRs->getUInt(6),  // double blinds interval
							false,                         // perform state logging
							false                          // perform general logging
						);

						logger.log(0, "end playing tournament " + std::to_string(tournamentId));

					}

					statement->closeResultSet(tournamentWorkRs);
					//tournamentResultCollector->writeToDatabase();
					*/


				}
				else if (result == -1) {
					logger.log(0, resultStringPrefix + "-1: stop, no work to perform");
				}

				Sleep(1000);

			} while (result != -1);

			con->terminateStatement(statement);
			delete tournamentResultCollector;
		}
		catch (const oracle::occi::SQLException& e) {
			// connection lost contact, re-establish
			std::cout << "oracle::occi::SQLException - " << e.what() << std::endl;
			dbConnectionManager->releaseConnection(con);
			Sleep(5000);
			con = dbConnectionManager->getConnection();
			delete tournamentResultCollector;
			strategyManager->bounceDbConnection();

			// requeue anything that this thread had picked up but did not finish
			std::string procCall = "BEGIN pkg_ga_evolver.requeue_failed_work(";
			procCall.append("p_worker_id => :1, ");
			procCall.append("p_trial_id  => :2");
			procCall.append("); END; ");
			oracle::occi::Statement* statement = con->createStatement();
			statement->setSQL(procCall);
			statement->setString(1, workerId);
			statement->setUInt(2, trialId);
			statement->execute();
			con->terminateStatement(statement);

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

	dbConnectionManager->releaseConnection(con);

}

void GaEvolverTournamentWorker::threadJoin() {
	workerThread.join();
}
