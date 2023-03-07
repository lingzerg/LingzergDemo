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
	// �������Գ�ʼ��
	HINSTANCE hIns = GetModuleHandle(0);
	WNDCLASSEX wc;

	wc.cbSize = sizeof(wc);								// ����ṹ��С
	wc.style = CS_HREDRAW | CS_VREDRAW;					// ����ı��˿ͻ�����Ŀ�Ȼ�߶ȣ������»����������� 
	wc.cbClsExtra = 0;									// ���ڽṹ�ĸ����ֽ���
	wc.cbWndExtra = 0;									// ����ʵ���ĸ����ֽ���
	wc.hInstance = hIns;								// ��ģ���ʵ�����
	wc.hIcon = NULL;									// ͼ��ľ��
	wc.hIconSm = NULL;									// �ʹ����������Сͼ��ľ��
	wc.hbrBackground = (HBRUSH)COLOR_WINDOW;			// ������ˢ�ľ��
	wc.hCursor = NULL;									// ���ľ��
	wc.lpfnWndProc = __WndProc;							// ���ڴ�������ָ��
	wc.lpszMenuName = NULL;								// ָ��˵���ָ��
	wc.lpszClassName = "LYSM_class";					// ָ�������Ƶ�ָ��

	// Ϊ����ע��һ��������
	if (!RegisterClassEx(&wc)) {
		cout << "RegisterClassEx error : " << GetLastError() << endl;
	}

	static TCHAR szWindowClass[] = _T("DesktopApp");
	static TCHAR szTitle[] = _T("Windows Desktop Guided Tour Application");

	// ��������
	HWND hWnd = CreateWindowEx(
		WS_EX_OVERLAPPEDWINDOW,				// ������չ��ʽ����������
		"LYSM_class",				// ��������
		szTitle,				// ���ڱ���
		WS_OVERLAPPEDWINDOW,		// ������ʽ���ص�����
		0,							// ���ڳ�ʼx����
		0,							// ���ڳ�ʼy����
		800,						// ���ڿ��
		600,						// ���ڸ߶�
		0,							// �����ھ��
		0,							// �˵���� 
		hIns,						// �봰�ڹ�����ģ��ʵ���ľ��
		0							// �������ݸ�����WM_CREATE��Ϣ
	);
	if (hWnd == 0) {
		cout << "CreateWindowEx error : " << GetLastError() << endl;
	}
	ShowWindow(hWnd, SW_SHOW);
	UpdateWindow(hWnd);

	// ��Ϣѭ����û�лᵼ�´��ڿ�����
	MSG msg = { 0 };
	while (msg.message != WM_QUIT) {
		// ����Ϣ������ɾ��һ����Ϣ
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