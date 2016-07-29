#include "GaEvolverTournamentWorker.hpp"
#include <string>
#include "TournamentController.hpp"
#include "Logger.hpp"

GaEvolverTournamentWorker::GaEvolverTournamentWorker(
	oracle::occi::StatelessConnectionPool* connectionPool,
	PythonManager* pythonManager,
	unsigned int trialId,
	const std::string& workerId,
	StrategyManager* strategyManager,
	bool loggingEnabled
) {
	this->connectionPool = connectionPool;
	this->trialId = trialId;
	this->workerId = workerId;
	this->pythonManager = pythonManager;
	this->strategyManager = strategyManager;
	this->loggingEnabled = loggingEnabled;
}

void GaEvolverTournamentWorker::startThread() {
	workerThread = boost::thread(&GaEvolverTournamentWorker::threadLoop, this);
}

void GaEvolverTournamentWorker::threadLoop() {

	oracle::occi::Connection* con = connectionPool->getConnection();
	Logger logger;
	logger.initialize(con);
	logger.setLoggingEnabled(loggingEnabled);
	bool verboseOutput = false;
	bool flush = false;

	TournamentController tournamentController;
	tournamentController.initialize(connectionPool, pythonManager, strategyManager);

	int result;
	std::string resultStringPrefix = workerId + " selecting tournament work returned ";

	std::string procCall = "BEGIN :1 := pkg_ga_evolver.select_tournament_work(";
	procCall.append("p_trial_id                   => :2, ");
	procCall.append("p_tournament_work            => :3, ");
	procCall.append("p_tournament_work_strategies => :4");
	procCall.append("); END; ");
	oracle::occi::Statement* statement = con->createStatement();
	statement->setSQL(procCall);
	statement->registerOutParam(1, oracle::occi::OCCIINT);
	statement->setUInt(2, trialId);
	statement->registerOutParam(3, oracle::occi::OCCICURSOR);
	statement->registerOutParam(4, oracle::occi::OCCICURSOR);

	do {
		statement->execute();
		result = statement->getInt(1);

		if (verboseOutput && result == 1) {
			logger.log(0, resultStringPrefix + "1: empty queue, wait for more");
			strategyManager->flushNonControlGenerations();
		}
		else if (result == 0) {
			logger.log(0, resultStringPrefix + "0: play tournament");

			oracle::occi::ResultSet* tournamentWorkRs = statement->getCursor(3);
			oracle::occi::ResultSet* tournamentWorkStrategiesRs = statement->getCursor(4);
			tournamentWorkRs->next();

			std::vector<unsigned int> strategyIds;
			while (tournamentWorkStrategiesRs->next()) {
				strategyIds.push_back(tournamentWorkStrategiesRs->getUInt(1));
			}
			statement->closeResultSet(tournamentWorkStrategiesRs);

			unsigned int tournamentId = tournamentWorkRs->getUInt(1);
			logger.log(0, "begin playing tournament " + std::to_string(tournamentId));
			tournamentController.playAutomatedTournament(
				trialId,
				tournamentId,
				strategyIds,
				tournamentWorkRs->getUInt(2),  // player count
				tournamentWorkRs->getUInt(3),  // tournament buy in
				tournamentWorkRs->getUInt(4),  // initial small blind value
				tournamentWorkRs->getUInt(5),  // double blinds interval
				false,                         // perform state logging
				false                          // perform general logging
			);
			statement->closeResultSet(tournamentWorkRs);

			logger.log(0, "end playing tournament " + std::to_string(tournamentId));

		}
		else if (result == -1) {
			logger.log(0, resultStringPrefix + "-1: stop, no work to perform");
		}

		Sleep(1000);

	} while (result != -1);

	con->terminateStatement(statement);
	connectionPool->releaseConnection(con);
}

void GaEvolverTournamentWorker::threadJoin() {
	workerThread.join();
}
