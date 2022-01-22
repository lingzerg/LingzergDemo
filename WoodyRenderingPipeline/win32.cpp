#include <assert.h>
#include <iostream>
#include <tchar.h>
#include <atlimage.h>

#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <windows.h>

#include "platform.h"
#include "macro.h"

//
//window_t* window_create(const char* title, int width, int height) {
//
//}


using namespace std;

static int g_initialized = 0;

#ifdef UNICODE
static const wchar_t* const WINDOW_CLASS_NAME = L"Class";
static const wchar_t* const WINDOW_ENTRY_NAME = L"Entry";
#else
static const char* const WINDOW_CLASS_NAME = "Class";
static const char* const WINDOW_ENTRY_NAME = "Entry";
#endif

int direct = 0;

static void initialize_path(void) {
#ifdef UNICODE
	wchar_t path[MAX_PATH];
	GetModuleFileName(NULL, path, MAX_PATH);
	*wcsrchr(path, L'\\') = L'\0';
	_wchdir(path);
	_wchdir(L"assets");
#else
	char path[MAX_PATH];
	GetModuleFileName(NULL, path, MAX_PATH);
	*strrchr(path, '\\') = '\0';
	_chdir(path);
	_chdir("assets");
#endif
}

static LRESULT CALLBACK __WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {

	PAINTSTRUCT ps;
	HDC hdc;
	TCHAR greeting[] = _T("Hello, Windows desktop!");

	static HBITMAP bmp1, bmp2;
	static bool isImg1 = true;

	switch (msg) {
	case WM_INITDIALOG:
		return 0;

	case WM_KEYDOWN:
		switch (wParam)
		{
		case VK_LEFT:
			if (direct != VK_RIGHT)
				direct = VK_LEFT;
			break;
		case VK_RIGHT:
			if (direct != VK_LEFT)
				direct = VK_RIGHT;
			break;
		case VK_UP:
			if (direct != VK_DOWN)
				direct = VK_UP;
			break;
		case VK_DOWN:
			if (direct != VK_UP)
				direct = VK_DOWN;
			break;
		default:
			break;
		}
		return 0;
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);

		// Here your application is laid out.
		// For this introduction, we just print out "Hello, Windows desktop!"
		// in the top left corner.
		TextOut(hdc,
			5, 5,
			greeting, _tcslen(greeting));
		// End application specific layout section.

		EndPaint(hWnd, &ps);
		return DefWindowProc(hWnd, msg, wParam, lParam);

	case WM_COMMAND:

		break;
	case WM_CLOSE:
		cout << "WM_CLOSE" << GetLastError() << endl;
	case WM_DESTROY:
		cout << "WM_DESTROY" << GetLastError() << endl;
		PostQuitMessage(0);
		return 0;
	default:
		break;
	}
	return DefWindowProc(hWnd, msg, wParam, lParam);

}

static void register_class(void) {
	// 窗口属性初始化
	HINSTANCE hIns = GetModuleHandle(0);
	WNDCLASSEX wc;

	wc.cbSize = sizeof(wc);								// 定义结构大小
	wc.style = CS_HREDRAW | CS_VREDRAW;					// 如果改变了客户区域的宽度或高度，则重新绘制整个窗口 
	wc.cbClsExtra = 0;									// 窗口结构的附加字节数
	wc.cbWndExtra = 0;									// 窗口实例的附加字节数
	wc.hInstance = hIns;								// 本模块的实例句柄
	wc.hIcon = NULL;									// 图标的句柄
	wc.hIconSm = NULL;									// 和窗口类关联的小图标的句柄
	wc.hbrBackground = (HBRUSH)COLOR_WINDOW;			// 背景画刷的句柄
	wc.hCursor = NULL;									// 光标的句柄
	wc.lpfnWndProc = __WndProc;							// 窗口处理函数的指针
	wc.lpszMenuName = NULL;								// 指向菜单的指针
	wc.lpszClassName = "LYSM_class";					// 指向类名称的指针

	// 为窗口注册一个窗口类
	if (!RegisterClassEx(&wc)) {
		cout << "RegisterClassEx error : " << GetLastError() << endl;
	}

	static TCHAR szWindowClass[] = _T("DesktopApp");
	static TCHAR szTitle[] = _T("Windows Desktop Guided Tour Application");

	// 创建窗口
	HWND hWnd = CreateWindowEx(
		WS_EX_OVERLAPPEDWINDOW,				// 窗口扩展样式：顶级窗口
		"LYSM_class",				// 窗口类名
		szTitle,				// 窗口标题
		WS_OVERLAPPEDWINDOW,		// 窗口样式：重叠窗口
		0,							// 窗口初始x坐标
		0,							// 窗口初始y坐标
		800,						// 窗口宽度
		600,						// 窗口高度
		0,							// 父窗口句柄
		0,							// 菜单句柄 
		hIns,						// 与窗口关联的模块实例的句柄
		0							// 用来传递给窗口WM_CREATE消息
	);
	if (hWnd == 0) {
		cout << "CreateWindowEx error : " << GetLastError() << endl;
	}
	ShowWindow(hWnd, SW_SHOW);
	UpdateWindow(hWnd);

	// 消息循环（没有会导致窗口卡死）
	MSG msg = { 0 };
	while (msg.message != WM_QUIT) {
		// 从消息队列中删除一条消息
		if (PeekMessage(&msg, 0, 0, 0, PM_REMOVE)) {
			DispatchMessage(&msg);
		}
	}

	cout << "finished." << endl;
}

static void unregister_class(void) {
	UnregisterClass(WINDOW_CLASS_NAME, GetModuleHandle(NULL));
}

void platform_initialize(void) {
	assert(g_initialized == 0);
	register_class();
	initialize_path();
	g_initialized = 1;
}

void platform_terminate(void) {
	assert(g_initialized == 1);
	unregister_class();
	g_initialized = 0;
}