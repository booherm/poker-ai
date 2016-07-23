#ifndef GAEVOLVERCONTROLLER_HPP
#define GAEVOLVERCONTROLLER_HPP

#include "GaEvolverGenerationWorker.hpp"
#include "GaEvolverTournamentWorker.hpp"
#include "StrategyManager.hpp"

class GaEvolverController
{
public:
	GaEvolverController(oracle::occi::StatelessConnectionPool* connectionPool, PythonManager* pythonManager, StrategyManager* strategyManager);
	~GaEvolverController();
	void performEvolutionTrial(
		unsigned int trialId,
		unsigned int startFromGenerationNumber,
		unsigned int generationSize,
		unsigned int maxGenerations,
		float crossoverRate,
		int crossoverPoint,
		float mutationRate,
		unsigned int playersPerTournament,
		unsigned int tournamentWorkerThreads,
		unsigned int tournamentPlayCount,
		unsigned int tournamentBuyIn,
		unsigned int initialSmallBlindValue,
		unsigned int doubleBlindsInterval
	);
	void joinEvolutionTrial(unsigned int trialId, unsigned int tournamentWorkerThreads);

private:
	void startTournamentWorkers(unsigned int trialId);
	void joinTournamentWorkers();
	void createInitialGeneration(unsigned int trialId, unsigned int generationSize);

	StrategyManager* strategyManager;
	oracle::occi::StatelessConnectionPool* connectionPool;
	oracle::occi::Connection* con;
	std::vector<GaEvolverTournamentWorker*> tournamentWorkers;
	unsigned int workerCount;
	Logger logger;
	PythonManager* pythonManager;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
