#ifndef GAEVOLVERCONTROLLER_HPP
#define GAEVOLVERCONTROLLER_HPP

#include <ocilib.hpp>
#include "GaEvolverWorker.hpp"
#include "StrategyManager.hpp"

class GaEvolverController
{
public:
	GaEvolverController(const std::string& databaseId, PythonManager* pythonManager, StrategyManager* strategyManager);
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
	std::string databaseId;
	ocilib::Connection con;
	std::vector<GaEvolverWorker*> evolverWorkers;
	unsigned int workerCount;
	Logger logger;
	PythonManager* pythonManager;
	Util::RandomNumberGenerator randomNumberGenerator;
};

#endif
