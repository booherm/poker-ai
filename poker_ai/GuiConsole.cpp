#include "GuiConsole.hpp"
#include <io.h>
#include <fcntl.h>
#include <windows.h>
#include <iostream>

void startConsole() {
	// allocate a console and bind cout

	AllocConsole();
	HANDLE stdHandle;
	int hConsole;
	FILE* fp;
	stdHandle = GetStdHandle(STD_OUTPUT_HANDLE);
	hConsole = _open_osfhandle((long) stdHandle, _O_TEXT);
	fp = _fdopen(hConsole, "w");
	freopen_s(&fp, "CONOUT$", "w", stdout);

}
