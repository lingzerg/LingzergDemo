#include <iostream>
#include <windows.h>
#include <tchar.h>
#include <atlimage.h>

#include "api.h"

using namespace std;

int main(int argc, char** argv) {

	platform_initialize();

	platform_terminate();
	return 0;
}