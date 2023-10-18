#include <windows.h>
#include <psapi.h>
#include <process.h>
#include <tlhelp32.h>
#include <vector>
#include <iostream>
using namespace std;

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

int main()
{
	ShowWindow (GetConsoleWindow(), SW_HIDE);
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
        		//checks if the file explorer window is a dialog box and if so close it
        		if(clazz == "#32770")
        		{
        			cout << "Closing File Explorer Popup:" << clazz << " " << pid << endl;
        			PostMessage(hwnd, WM_CLOSE, 0, 0);
        			Sleep(5);
        			PostMessage(hwnd, WM_QUIT, 0, 0);
        		}
        	}
        }
        Sleep(50); // Sleep for 1/20th of a second so we tick 20 times a second optimally
    }
    return 0;
}
