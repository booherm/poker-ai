#include <iostream>
#include <string>
#include <windows.h>
#include "GuiConsole.hpp"
#include "PokerAiController.hpp"

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	startConsole();
	try {
		std::cout << "Starting Poker AI" << std::endl;
		PokerAiController paic;
		std::cout << "Exiting Poker AI" << std::endl;
	}
	catch (std::string e) {
		std::cout << "Exception: " << e << std::endl;
		system("pause");
	}

	return 0;
}
