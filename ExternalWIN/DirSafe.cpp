#include <windows.h>
#include <iostream>
#include <string>
#include <sstream>
#include <cstring>
#include <fstream>
#include <vector>
#include <iomanip>
using namespace std;

//Declare Vars here
bool recurse = false;
vector<DWORD> NoLNKS;

//Declare Methods here
bool isLink(wstring dir, DWORD att);
void ListDirectories(const std::wstring& directory);
bool EndsWith (const std::wstring &fullString, const std::wstring &ending);
string toHex(unsigned long v);
DWORD fromHex(string v);
DWORD GetReparsePointId(wstring path);
int revIndexOf(string str, string key);
string parent(string path);
void LoadCFG(string cfg);

int main(int argc, char* argv[]) {
	string WorkingDir = parent(string(argv[0]));
	string nonlnkscfg = WorkingDir + "\\DirNonShortcuts.cfg";
	LoadCFG(nonlnkscfg);
	cout << nonlnkscfg << endl;
    wstring dirarg = L"C:\\Users\\jredfox";
    dirarg = L"C:\\Users\\subba\\OneDrive";
    if(dirarg.size() > 1 && EndsWith(dirarg, L"\\"))
    	dirarg = dirarg.substr(0, dirarg.length() - 1);

    std::wcout << L"Listing directories in: " << dirarg << std::endl;
    ListDirectories(dirarg);

    return 0;
}

void ListDirectories(const std::wstring& directory) {
    WIN32_FIND_DATAW findFileData;
    HANDLE hFind = INVALID_HANDLE_VALUE;

    std::wstring searchPath = directory + L"\\*";
    hFind = FindFirstFileW(searchPath.c_str(), &findFileData);

    if (hFind == INVALID_HANDLE_VALUE) {
        std::wcout << L"Access Denied: " << directory << std::endl;
        return;
    }

    do {
    	DWORD att = findFileData.dwFileAttributes;
        if (att & FILE_ATTRIBUTE_DIRECTORY)
        {
            if (wcscmp(findFileData.cFileName, L".") != 0 && wcscmp(findFileData.cFileName, L"..") != 0)
            {
            	std::wstring currentDir = directory + L"\\" + findFileData.cFileName;
            	wcout << currentDir << " " << att << endl;
            	if (/*recurse &&*/ !isLink(currentDir, att) && recurse)
            	{
            		//std::wcout << currentDir << std::endl;
                	ListDirectories(currentDir);
            	}
            }
        }
        else
        {
//        	std::wstring currentFile = directory + L"\\" + findFileData.cFileName;
//        	isLink(currentFile, att);
        }
    } while (FindNextFileW(hFind, &findFileData) != 0);

    FindClose(hFind);
}

/**
 * ONEDRIVE reparse points don't show themselves unless under C:\Windows is the parent directory.
 * Fortunately this method handles when the program is installed in the windows folder itself
 */
bool isLink(wstring dir, DWORD att)
{
	DWORD RPID = 0;
	if(att & FILE_ATTRIBUTE_REPARSE_POINT)
	{
		RPID = GetReparsePointId(dir);
		for(DWORD n : NoLNKS)
			if(n == RPID)
				return false;
		wcout << "Link Found:" << dir;
		cout << " ReparseId:" << toHex(RPID) << endl;
		return true;//TODO: check the reparse point tag code here
	}
	return false;
}

/**
 * Handles any reparse points including non microsoft ones
 */
DWORD GetReparsePointId(wstring path)
{
    HANDLE hFile = CreateFileW(
    		path.c_str(),
    		0,
			FILE_SHARE_VALID_FLAGS,
			0,
			OPEN_EXISTING,
            FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS,
			0);

    if (hFile == INVALID_HANDLE_VALUE) {
        std::cerr << "Failed To Get ReparsePoint. Error code: " << GetLastError() << std::endl;
        return 0;
    }

    // Buffer to store reparse data
    BYTE buffer[1024];
    REPARSE_GUID_DATA_BUFFER* reparseData = reinterpret_cast<REPARSE_GUID_DATA_BUFFER*>(buffer);
    DWORD bytesReturned;

    if (!DeviceIoControl(
        hFile,
        FSCTL_GET_REPARSE_POINT,
        NULL,
        0,
        reparseData,
        sizeof(buffer),
        &bytesReturned,
        NULL
    )) {
        std::wcerr << path << L" Failed to get reparse point information. Error code: " << GetLastError() << std::endl;
        CloseHandle(hFile);
        return 0;
    }
    DWORD tag = reparseData->ReparseTag;
    CloseHandle(hFile);
    return tag;
}

bool EndsWith (const std::wstring &fullString, const std::wstring &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

DWORD fromHex(string v)
{
	return std::stoul(v, nullptr, 16);
}

string toHex(DWORD v)
{
	std::stringstream ss;
	ss << std::uppercase << "0X" << std::setfill('0') << std::setw(8) << std::hex << v;
	return ss.str();
}

int revIndexOf(string str, string key)
{
	size_t found = str.rfind(key);
	if(found != std::string::npos)
		 return static_cast<int>(found);
	return -1;
}

int IndexOf(string str, string key)
{
	size_t found = str.find(key);
	if(found != std::string::npos)
		 return static_cast<int>(found);
	return -1;
}

string parent(string path)
{
	int index = revIndexOf(path, "\\");
	return path.substr(0, index);
}

string trim(string str)
{
    str.erase(str.find_last_not_of(' ')+1);         //suffixing spaces
    str.erase(0, str.find_first_not_of(' '));       //prefixing spaces
    return str;
}

bool exists(const std::string& filePath) {
    DWORD fileAttributes = GetFileAttributes(filePath.c_str());
    return fileAttributes != INVALID_FILE_ATTRIBUTES;
}

void LoadCFG(string cfg)
{
	//create config file if it doesn't exist and then read config file
	if(!exists(cfg))
	{
		ofstream filewriter(cfg);
		filewriter << "IO_REPARSE_TAG_CLOUD_6 = 0x9000601A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD = 0x9000001A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_1 = 0x9000101A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_2 = 0x9000201A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_3 = 0x9000301A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_4 = 0x9000401A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_5 = 0x9000501A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_7 = 0x9000701A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_8 = 0x9000801A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_9 = 0x9000901A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_A = 0x9000A01A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_B = 0x9000B01A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_C = 0x9000C01A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_D = 0x9000D01A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_E = 0x9000E01A" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_F = 0x9000F01A" << endl;
		filewriter << "IO_REPARSE_TAG_ONEDRIVE = 0x80000021" << endl;
		filewriter << "IO_REPARSE_TAG_CLOUD_MASK = 0x0000F000" << endl;
		filewriter.close();
	}

    std::ifstream file(cfg);
    if (file.is_open())
    {
        std::string line;
        while (std::getline(file, line))
        {
        	line = trim(line.substr(IndexOf(line, "=") + 1));
        	NoLNKS.push_back(fromHex(line));
        }
        file.close();
    } else {
        std::cout << "Err Loading Config: " << GetLastError() << std::endl;
    }
}
