#ifndef POKERAIUIWINDOW_HPP
#define POKERAIUIWINDOW_HPP

#include "AwesomiumUiWindow.hpp"
#include "DbInterface.hpp"

class PokerAiUiWindow : public AwesomiumUiWindow
{

public:
	PokerAiUiWindow(DbInterface* dbInterface);

private:
	void initTournament(WebView* caller, const JSArray& args);
	void stepPlay(WebView* caller, const JSArray& args);
	void refreshUi();
	void bindJsFunctions();

	DbInterface* dbInterface;

};

#endif
