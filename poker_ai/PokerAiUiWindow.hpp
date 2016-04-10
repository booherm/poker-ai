#ifndef POKERAIUIWINDOW_HPP
#define POKERAIUIWINDOW_HPP

#include "AwesomiumUiWindow.hpp"
#include "DbInterface.hpp"

class PokerAiUiWindow : public AwesomiumUiWindow
{

public:
	PokerAiUiWindow(DbInterface* dbInterface);
	void onWindowDestroy();

private:
	void initTournament(WebView* caller, const JSArray& args);
	void initGame(WebView* caller, const JSArray& args);
	void refreshRenderWindowState(WebView* caller, const JSArray& args);
	void setModuleConfigValue(WebView* caller, const JSArray& args);
	void sendRenderWindowCommand(WebView* caller, const JSArray& args);
	void bindJsFunctions();

	DbInterface* dbInterface;

};

#endif
