#ifndef POKERAICONTROLLER_HPP
#define POKERAICONTROLLER_HPP

#include "PokerAiUiWindow.hpp"
#include "TournamentController.hpp"
#include "GaEvolverController.hpp"

class PokerAiController {
public:
	PokerAiController();
	~PokerAiController();
private:
	std::string databaseId;
	PokerAiUiWindow* uiWindow;
	TournamentController* tournamentController;
	GaEvolverController* gaEvolverController;
};

#endif