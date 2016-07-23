#include "PokerAiUiWindow.hpp"
#include <boost/timer/timer.hpp>

PokerAiUiWindow::PokerAiUiWindow(TournamentController* tournamentController, GaEvolverController* gaEvolverController)
	: AwesomiumUiWindow(1500, 550, "Poker AI", "file:///c:/projects/vs_workspace/poker_ai/poker_ai/web_ui/poker_ai.html")
{
	this->tournamentController = tournamentController;
	this->gaEvolverController = gaEvolverController;
}

void PokerAiUiWindow::initTournament(WebView* caller, const JSArray& args) {
	
	TournamentController::TournamentMode tournamentMode = (TournamentController::TournamentMode) args.At(0).ToInteger();
	unsigned int playerCount = args.At(1).ToInteger();
	unsigned int buyInAmount = args.At(2).ToInteger();

	unsigned int stateId = tournamentController->initNonAutomatedTournament(tournamentMode, playerCount, buyInAmount);
	refreshUi(stateId);
}

void PokerAiUiWindow::stepPlay(WebView* caller, const JSArray& args) {
	
	unsigned int stateId = args.At(0).ToInteger();
	unsigned int smallBlindAmount = args.At(1).ToInteger();
	PokerEnums::PlayerMove playerMove = (PokerEnums::PlayerMove) args.At(2).ToInteger();
	unsigned int playerMoveAmount = args.At(3).ToInteger();

	stateId = tournamentController->stepPlay(stateId, smallBlindAmount, playerMove, playerMoveAmount);
	refreshUi(stateId);
}

void PokerAiUiWindow::editCard(WebView* caller, const JSArray& args) {

	unsigned int stateId = args.At(0).ToInteger();
	std::string cardType = Awesomium::ToString(args.At(1).ToString());
	unsigned int seatNumber = args.At(2).ToInteger();
	unsigned int cardSlot = args.At(3).ToInteger();
	unsigned int cardId = args.At(4).ToInteger();

	//stateId = tournamentStepperDbInterface->editCard(stateId, cardType, seatNumber, cardSlot, cardId);
	refreshUi(stateId);
}

void PokerAiUiWindow::loadState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();
	refreshUi(stateId);
}

void PokerAiUiWindow::loadPreviousState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();
	stateId = tournamentController->getPreviousStateId(stateId);
	refreshUi(stateId);
}

void PokerAiUiWindow::loadNextState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();
	stateId = tournamentController->getNextStateId(stateId);
	refreshUi(stateId);
}

void PokerAiUiWindow::refreshUi(unsigned int stateId) {
	Json::Value uiData(Json::objectValue);
	tournamentController->getUiState(stateId, uiData);
	executeJs("TournamentStepper.refreshUi(" + uiData.toStyledString() + ");");
}

void PokerAiUiWindow::performTournamentTest(WebView* caller, const JSArray& args) {

	boost::timer::auto_cpu_timer timer;
	tournamentController->testAutomatedTournament(
		args.At(0).ToInteger(), // evolution trial id
		args.At(1).ToInteger(), // tournament count
		args.At(2).ToInteger(), // player count
		args.At(3).ToInteger(), // tournament buy in
		args.At(4).ToInteger(), // initial small blind value
		args.At(5).ToInteger(), // double blinds interval
		true,                   // perform state logging
		true                    // perform general logging
	);

}

void PokerAiUiWindow::performEvolutionTrial(WebView* caller, const JSArray& args) {

	gaEvolverController->performEvolutionTrial(
		args.At(0).ToInteger(),        // trial id
		args.At(1).ToInteger(),        // start from generation number
		args.At(2).ToInteger(),        // generation size
		args.At(3).ToInteger(),        // max generations
		(float) args.At(4).ToDouble(), // crossover rate
		args.At(5).ToInteger(),        // crossover point
		(float) args.At(6).ToDouble(), // mutation rate
		args.At(7).ToInteger(),        // players per tournament
		args.At(8).ToInteger(),        // tournament worker threads
		args.At(9).ToInteger(),        // tournament play count
		args.At(10).ToInteger(),       // tournament buy in
		args.At(11).ToInteger(),       // initial small blind value
		args.At(12).ToInteger()        // double blinds interval
	);

}

void PokerAiUiWindow::joinEvolutionTrial(WebView* caller, const JSArray& args) {

	gaEvolverController->joinEvolutionTrial(
		args.At(0).ToInteger(), // trial id
		args.At(1).ToInteger()  // tournament worker threads
	);

}

void PokerAiUiWindow::bindJsFunctions() {
	JSObject scopeObj = createGlobalJsObject(std::string("PokerAi"));
	bindJsFunction(scopeObj, std::string("initTournament"), JSDelegate(this, &PokerAiUiWindow::initTournament));
	bindJsFunction(scopeObj, std::string("stepPlay"), JSDelegate(this, &PokerAiUiWindow::stepPlay));
	bindJsFunction(scopeObj, std::string("editCard"), JSDelegate(this, &PokerAiUiWindow::editCard));
	bindJsFunction(scopeObj, std::string("loadState"), JSDelegate(this, &PokerAiUiWindow::loadState));
	bindJsFunction(scopeObj, std::string("loadPreviousState"), JSDelegate(this, &PokerAiUiWindow::loadPreviousState));
	bindJsFunction(scopeObj, std::string("loadNextState"), JSDelegate(this, &PokerAiUiWindow::loadNextState));
	bindJsFunction(scopeObj, std::string("performTournamentTest"), JSDelegate(this, &PokerAiUiWindow::performTournamentTest));
	bindJsFunction(scopeObj, std::string("performEvolutionTrial"), JSDelegate(this, &PokerAiUiWindow::performEvolutionTrial));
	bindJsFunction(scopeObj, std::string("joinEvolutionTrial"), JSDelegate(this, &PokerAiUiWindow::joinEvolutionTrial));
}
