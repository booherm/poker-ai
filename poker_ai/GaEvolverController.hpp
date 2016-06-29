#ifndef GAEVOLVERCONTROLLER_HPP
#define GAEVOLVERCONTROLLER_HPP

#include <ocilib.hpp>
#include <vector>
#include "GaEvolverWorker.hpp"

class GaEvolverController
{
public:
	GaEvolverController(const std::string& databaseId);
	~GaEvolverController();
	void performEvolutionTrial(
		const std::string& trialId,
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

private:
	std::string databaseId;
	ocilib::Connection con;
	std::vector<GaEvolverWorker*> evolverWorkers;
	unsigned int workerCount;

	void startTournamentWorkers(const std::string& trialId);
	void joinTournamentWorkers();

};

#endif
