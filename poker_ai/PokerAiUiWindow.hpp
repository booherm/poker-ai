#ifndef POKERAIUIWINDOW_HPP
#define POKERAIUIWINDOW_HPP

#include "AwesomiumUiWindow.hpp"
#include "TournamentController.hpp"
#include "GaEvolverController.hpp"

class PokerAiUiWindow : public AwesomiumUiWindow
{

public:
	PokerAiUiWindow(TournamentController* tournamentController, GaEvolverController* gaEvolverController);

private:
	void initTournament(WebView* caller, const JSArray& args);
	void stepPlay(WebView* caller, const JSArray& args);
	void editCard(WebView* caller, const JSArray& args);
	void loadState(WebView* caller, const JSArray& args);
	void loadPreviousState(WebView* caller, const JSArray& args);
	void loadNextState(WebView* caller, const JSArray& args);
	void refreshUi(unsigned int stateId);
	void performTournamentTest(WebView* caller, const JSArray& args);
	void performEvolutionTrial(WebView* caller, const JSArray& args);
	void joinEvolutionTrial(WebView* caller, const JSArray& args);
	void bindJsFunctions();

	TournamentController* tournamentController;
	GaEvolverController* gaEvolverController;
};

#endif
