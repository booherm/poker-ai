#ifndef TOURNAMENTRESULTCOLLECTOR_HPP
#define TOURNAMENTRESULTCOLLECTOR_HPP

#include "PlayerState.hpp"
#include "DbConnectionManager.hpp"

class TournamentResultCollector {
public:
	void initialize(DbConnectionManager* dbConnectionManager);
	void pushTournamentResult(unsigned int trialId, unsigned int tournamentId, unsigned int generation, unsigned int strategyId, const PlayerState& playerState);
	void writeToDatabase();
	~TournamentResultCollector();

private:
	struct TournamentResult {
		unsigned int trialId;
		unsigned int tournamentId;
		unsigned int generation;
		unsigned int strategyId;
		PlayerState playerState;
	};

	DbConnectionManager* dbConnectionManager;
	oracle::occi::Connection* con;
	std::vector<TournamentResult> tournamentResults;
};

#endif