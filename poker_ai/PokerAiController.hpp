#ifndef POKERAICONTROLLER_HPP
#define POKERAICONTROLLER_HPP

#include "PokerAiUiWindow.hpp"
#include "TournamentController.hpp"
#include "StrategyManager.hpp"
#include "TournamentResultCollector.hpp"
#include "GaEvolverController.hpp"

class PokerAiController {
public:
	PokerAiController();
private:
	PokerAiUiWindow* uiWindow;
	PythonManager* pythonManager;
	StrategyManager* strategyManager;
	TournamentResultCollector* tournamentResultCollector;
	TournamentController* tournamentController;
	GaEvolverController* gaEvolverController;
};

#endif
