#include "PokerAiUiWindow.hpp"

PokerAiUiWindow::PokerAiUiWindow(DbInterface* dbInterface)
	: AwesomiumUiWindow(1500, 550, "Poker AI", "file:///c:/projects/vs_workspace/poker_ai/poker_ai/web_ui/poker_ai.html")
{
	this->dbInterface = dbInterface;
}

void PokerAiUiWindow::initTournament(WebView* caller, const JSArray& args) {
	
	unsigned int playerCount = args.At(0).ToInteger();
	unsigned int buyInAmount = args.At(1).ToInteger();

	dbInterface->initTournament(playerCount, buyInAmount);
	refreshUi();
}

void PokerAiUiWindow::stepPlay(WebView* caller, const JSArray& args) {
	
	unsigned int smallBlindAmount = args.At(0).ToInteger();
	std::string playerMove = Awesomium::ToString(args.At(1).ToString());
	unsigned int playerMoveAmount = args.At(2).ToInteger();

	dbInterface->stepPlay(smallBlindAmount, playerMove, playerMoveAmount);
	refreshUi();
}

void PokerAiUiWindow::loadState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();

	dbInterface->loadState(stateId);
	refreshUi();
}

void PokerAiUiWindow::loadPreviousState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();
	dbInterface->loadPreviousState(stateId);
	refreshUi();
}

void PokerAiUiWindow::loadNextState(WebView* caller, const JSArray& args) {
	unsigned int stateId = args.At(0).ToInteger();
	dbInterface->loadNextState(stateId);
	refreshUi();
}

void PokerAiUiWindow::refreshUi() {
	Json::Value uiData(Json::objectValue);
	dbInterface->getUiState(uiData);
	//std::cout << uiData.toStyledString() << std::endl;
	executeJs("PokerAiUi.refreshUi(" + uiData.toStyledString() + ");");
}

void PokerAiUiWindow::bindJsFunctions() {
	JSObject scopeObj = createGlobalJsObject(std::string("PokerAi"));
	bindJsFunction(scopeObj, std::string("initTournament"), JSDelegate(this, &PokerAiUiWindow::initTournament));
	bindJsFunction(scopeObj, std::string("stepPlay"), JSDelegate(this, &PokerAiUiWindow::stepPlay));
	bindJsFunction(scopeObj, std::string("loadState"), JSDelegate(this, &PokerAiUiWindow::loadState));
	bindJsFunction(scopeObj, std::string("loadPreviousState"), JSDelegate(this, &PokerAiUiWindow::loadPreviousState));
	bindJsFunction(scopeObj, std::string("loadNextState"), JSDelegate(this, &PokerAiUiWindow::loadNextState));
}
