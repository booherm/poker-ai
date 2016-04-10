#include "PokerAiUiWindow.hpp"

PokerAiUiWindow::PokerAiUiWindow(DbInterface* dbInterface)
	: AwesomiumUiWindow(1500, 550, "Poker AI", "file:///c:/projects/vs_workspace/poker_ai/poker_ai/web_ui/poker_ai.html")
{
	this->dbInterface = dbInterface;
}

void PokerAiUiWindow::onWindowDestroy() {
	//renderWindow->handleInputCommand("closeWindow");
}

void PokerAiUiWindow::initTournament(WebView* caller, const JSArray& args) {
	
	unsigned int playerCount = args.At(0).ToInteger();
	unsigned int buyInAmount = args.At(1).ToInteger();

	dbInterface->initTournament(playerCount, buyInAmount);
	Json::Value playerState(Json::objectValue);
	dbInterface->getPlayerState(playerState);

	//std::cout << playerState.toStyledString() << std::endl;

	executeJs("PokerAiUi.initTournamentCallback(" + playerState.toStyledString() + ");");
}

void PokerAiUiWindow::initGame(WebView* caller, const JSArray& args) {
	
	unsigned int smallBlindSeatNumber = args.At(0).ToInteger();
	unsigned int smallBlindAmount = args.At(1).ToInteger();
	unsigned int bigBlindAmount = args.At(2).ToInteger();

	dbInterface->initGame(smallBlindSeatNumber, smallBlindAmount, bigBlindAmount);
	
	//Json::Value playerState(Json::objectValue);
	//dbInterface->getPlayerState(playerState);
	//std::cout << playerState.toStyledString() << std::endl;

	//executeJs("PokerAiUi.initGameCallback(" + playerState.toStyledString() + ");");
}

void PokerAiUiWindow::refreshRenderWindowState(WebView* caller, const JSArray& args) {
	//Json::Value stateJson(Json::objectValue);
	//renderWindow->getStateJson(stateJson);
	//executeJs("CawbUi.refreshRenderWindowStateCallback(" + stateJson.toStyledString() + ");");
}

void PokerAiUiWindow::setModuleConfigValue(WebView* caller, const JSArray& args) {
	//CaWorkbenchModule::ConfigSetting newSetting;
	//newSetting.key = ToString(args.At(0).ToString());
	//newSetting.value = ToString(args.At(1).ToString());

	//cout << "module config, key = " << newSetting.key << " value = " << newSetting.value << endl;
	//module->enqueueConfigChange(newSetting);
}

void PokerAiUiWindow::sendRenderWindowCommand(WebView* caller, const JSArray& args) {
	//std::string command = ToString(args.At(0).ToString());
	//renderWindow->handleInputCommand(command);
	//refreshRenderWindowState(caller, args);
}

void PokerAiUiWindow::bindJsFunctions() {
	JSObject scopeObj = createGlobalJsObject(std::string("PokerAi"));
	bindJsFunction(scopeObj, std::string("initTournament"), JSDelegate(this, &PokerAiUiWindow::initTournament));
	bindJsFunction(scopeObj, std::string("initGame"), JSDelegate(this, &PokerAiUiWindow::initGame));
	bindJsFunction(scopeObj, std::string("refreshRenderWindowState"), JSDelegate(this, &PokerAiUiWindow::refreshRenderWindowState));
	bindJsFunction(scopeObj, std::string("setModuleConfigValue"), JSDelegate(this, &PokerAiUiWindow::setModuleConfigValue));
	bindJsFunction(scopeObj, std::string("sendRenderWindowCommand"), JSDelegate(this, &PokerAiUiWindow::sendRenderWindowCommand));
}
