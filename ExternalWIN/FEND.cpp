#include <windows.h>
#include <psapi.h>
#include <process.h>
#include <tlhelp32.h>
#include <vector>
#include <iostream>
#include <string>
#include <cctype>
using namespace std;

string toString(bool b)
{
	return b ? "true" : "false";
}

bool endsWith (string const &fullString, string const &ending)
{
	if (fullString.length() >= ending.length())
	{
		return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
	}
	return false;
}

/**
 * returns the full executable path of the running process
 */
string getProcessName(unsigned long pid)
{
	string name = "";
	HANDLE phandle = OpenProcess( PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid);
	TCHAR filename[MAX_PATH];
	GetModuleFileNameEx(phandle, NULL, filename, MAX_PATH);
	CloseHandle(phandle);
	return string(filename);
}

string GetWindowClass(HWND hwnd)
{
	char windowClass[256];
	GetClassNameA(hwnd, windowClass, sizeof(windowClass));
	return std::string(windowClass);
}

/**
 * returns all PID's from the specified executable
 */
void getPIDS(string path, vector<DWORD> &pids)
{
	PROCESSENTRY32 entry;
	entry.dwSize = sizeof(PROCESSENTRY32);
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (Process32First(snapshot, &entry))
	{
		while (Process32Next(snapshot, &entry))
		{
			if(endsWith(path, entry.szExeFile) && getProcessName(entry.th32ProcessID) == path)
			{
				pids.push_back(entry.th32ProcessID);
			}
		}
	}
	CloseHandle(snapshot);
}

void GetAllWindowsFromProcessID(DWORD dwProcessID, vector <HWND> &vhWnds, bool bg)
{
	// find all hWnds (vhWnds) associated with a process id (dwProcessID)
	HWND hCurWnd = nullptr;
	do
	{
		hCurWnd = FindWindowEx(nullptr, hCurWnd, nullptr, nullptr);
		DWORD checkProcessID = 0;
		GetWindowThreadProcessId(hCurWnd, &checkProcessID);
		if (checkProcessID == dwProcessID && (bg || IsWindowVisible(hCurWnd)))
		{
			vhWnds.push_back(hCurWnd);
		}
	}
	while (hCurWnd != nullptr);
}

std::string GetWindowTitle(HWND hwnd)
{
    const int bufferSize = 256;
    char buffer[bufferSize];
    GetWindowText(hwnd, buffer, bufferSize);
    return std::string(buffer);
}

void ClosePopup(HWND hwnd, DWORD pid)
{
	//cout << "Closing File Explorer Popup:#32770" << " " << pid << endl;
	HWND parent = GetParent(hwnd);
	if(IsWindowVisible(parent))
	{
		//Take no chances close file explorer window forcibly. File Explorer by default is only 1 process regardless of windows
		PostMessage(parent, WM_CLOSE, 0, 0);
		PostMessage(parent, WM_QUIT, 0, 0);
		PostMessage(parent, WM_SYSCOMMAND, SC_CLOSE, 0);
	}
	else
	{
		//Once the parent window has been closed we are safe to close the dialog box without getting the extra accessible location popup
		PostMessage(hwnd, WM_QUIT, 0, 0);
	}
}

void lowercase(string &s)
{
	for (char& c : s) {
		c = std::tolower(c);
	}
}

bool IsSecurityPopup(string title)
{
	lowercase(title);
	unsigned int size = title.size();
	if (size < 2 || !std::islower(title[0]) || title[1] != ':' || (title[2] != '\\' && title[2] != '/' && size > 2 ) || (size > 3 && title[3] != ' ') )
		return false;
	return true;
}

/**
 * checks if Title of the HWND is A-Z:\ or A-Z:/
 */
bool IsSecurityPopup(HWND hwnd, DWORD pid)
{
	string title = GetWindowTitle(hwnd);
	return IsSecurityPopup(title);
}

/**
 * Checks if the Title is EqualsIgnoresCase("Microsoft Windows")
 */
bool IsFormatPopup(HWND hwnd, DWORD pid)
{
	string title = GetWindowTitle(hwnd);
	lowercase(title);
	return (title == "microsoft windows");
}

int main()
{
	//ShowWindow (GetConsoleWindow(), SW_HIDE);
	char* homePath = getenv("HOMEDRIVE");
	std::string homePathString(homePath);
	std::string drive = homePathString.substr(0,1);
	std::string expl = drive + ":\\Windows\\explorer.exe";
    while (true)
    {
        vector<DWORD> pids;
        getPIDS(expl, pids);
        for(DWORD pid : pids)
        {
        	vector<HWND> hwnds;
        	GetAllWindowsFromProcessID(pid, hwnds, false);
        	for(HWND hwnd : hwnds)
        	{
        		string clazz = GetWindowClass(hwnd);
        		//checks if the file explorer window is a dialog box and if so check if it needs to be closed
        		if(clazz == "#32770")
        		{
        			if(IsSecurityPopup(hwnd, pid) || IsFormatPopup(hwnd, pid))
        				ClosePopup(hwnd, pid);
        		}
        	}
        }
        Sleep(25); //40 ticks a second now that we have to close the parent window 2x times before the actual dialog box
    }
    return 0;
}
