#ifndef POKERAICONTROLLER_HPP
#define POKERAICONTROLLER_HPP

#include "PokerAiUiWindow.hpp"
#include "TournamentStepperDbInterface.hpp"
#include "GaEvolverController.hpp"

class PokerAiController {
public:
	PokerAiController();
	~PokerAiController();
private:
	std::string databaseId;
	PokerAiUiWindow* uiWindow;
	TournamentStepperDbInterface* tournamentStepperDbInterface;
	GaEvolverController* gaEvolverController;
};

#endif