#ifndef GAEVOLVERCONTROLLER_HPP
#define GAEVOLVERCONTROLLER_HPP

#include "GaEvolverGenerationWorker.hpp"
#include "GaEvolverTournamentWorker.hpp"
#include "StrategyManager.hpp"

class GaEvolverController
{
public:
	GaEvolverController(
		DbConnectionManager* dbConnectionManager,
		PythonManager* pythonManager,
		StrategyManager* strategyManager
	);
	~GaEvolverController();
	void performEvolutionTrial(
		const std::string& machineId,
		unsigned int trialId,
		unsigned int controlGeneration,
		unsigned int startFromGenerationNumber,
		unsigned int generationSize,
		unsigned int maxGenerations,
		float crossoverRate,
		int crossoverPoint,
		unsigned int carryOverCount,
		float mutationRate,
		unsigned int playersPerTournament,
		unsigned int tournamentWorkerThreads,
		unsigned int tournamentPlayCount,
		unsigned int tournamentBuyIn,
		unsigned int initialSmallBlindValue,
		unsigned int doubleBlindsInterval
	);
	void joinEvolutionTrial(const std::string& machineId, unsigned int trialId, unsigned int tournamentWorkerThreads);

private:
	void startTournamentWorkers(unsigned int trialId, unsigned int controlGeneration);
	void joinTournamentWorkers();
	void createControlGeneration(unsigned int trialId, unsigned int playersPerTournament, unsigned int generationSize);
	void createInitialGeneration(unsigned int trialId, unsigned int generationSize);

	std::string machineId;
	StrategyManager* strategyManager;
	DbConnectionManager* dbConnectionManager;
	oracle::occi::Connection* con;
	std::vector<GaEvolverTournamentWorker*> tournamentWorkers;
	unsigned int workerCount;
	Logger logger;
	PythonManager* pythonManager;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
