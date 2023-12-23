#include <windows.h>
#include <iostream>
#include <string>
#include <sstream>
#include <cstring>
#include <fstream>
#include <vector>
#include <iomanip>
#include <fcntl.h>
typedef struct _REPARSE_DATA_BUFFER {
  ULONG  ReparseTag;
  USHORT  ReparseDataLength;
  USHORT  Reserved;
  union {
    struct {
      USHORT  SubstituteNameOffset;
      USHORT  SubstituteNameLength;
      USHORT  PrintNameOffset;
      USHORT  PrintNameLength;
      ULONG   Flags; // it seems that the docu is missing this entry (at least 2008-03-07)
      WCHAR  PathBuffer[1];
      } SymbolicLinkReparseBuffer;
    struct {
      USHORT  SubstituteNameOffset;
      USHORT  SubstituteNameLength;
      USHORT  PrintNameOffset;
      USHORT  PrintNameLength;
      WCHAR  PathBuffer[1];
      } MountPointReparseBuffer;
    struct {
      UCHAR  DataBuffer[1];
    } GenericReparseBuffer;
  };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;

#define REPARSE_DATA_BUFFER_HEADER_SIZE  FIELD_OFFSET(REPARSE_DATA_BUFFER, GenericReparseBuffer)
#ifndef MAXIMUM_REPARSE_DATA_BUFFER_SIZE
#define MAXIMUM_REPARSE_DATA_BUFFER_SIZE  ( 16 * 1024 )
#endif
using namespace std;

//Declare Vars here
bool Recurse = false;
bool Bare = false;
wstring Attribs = L"";
vector<DWORD> NoLNKS;

//Declare Methods here
void ListDirectories(const std::wstring& directory);
bool isLink(DWORD &RPID);
DWORD GetRPTag(wstring &path);
DWORD GetReparsePointId(wstring &path, DWORD &att);
wstring getTarget(wstring &path);
bool foundFile(wstring &path, wstring &n, DWORD &attr, DWORD &RPID);
std::wstring GetAbsolutePath(const std::wstring& path);

bool EndsWith (const std::wstring &fullString, const std::wstring &ending);
string toHex(unsigned long v);
DWORD fromHex(string v);
int revIndexOf(string str, string key);
string parent(string path);
void LoadCFG(string cfg);
bool parseBool(wstring s);
wstring tolower(wstring s);
wstring trim(wstring str);
wstring toupper(wstring s);

int main(int a, char* sargs[]) {
	string WorkingDir = parent(string(sargs[0]));
	setlocale(LC_CTYPE, "");
	cout << WorkingDir << endl;
	_setmode( _fileno(stdout), _O_U8TEXT );
	int argc;
	LPWSTR* args = CommandLineToArgvW(GetCommandLineW(), &argc);
	//Parse command Line Args
	wstring dirarg;
	 if(argc > 1)
		 dirarg = GetAbsolutePath(wstring(args[1]));
	 else
		 dirarg = GetAbsolutePath(L"");
    if(argc > 2)
    	Recurse = parseBool(args[2]);
    if(argc > 3)
    	Bare = parseBool(args[3]);
    if(argc > 4)
    	Attribs = toupper(trim(args[4]));
    wcout << Recurse << " " << Bare << " " << Attribs << endl;

	//Get the working directory and load the config
	string nonlnkscfg = WorkingDir + "\\DirNonShortcuts.cfg";
	LoadCFG(nonlnkscfg);
    if(dirarg.size() > 1 && EndsWith(dirarg, L"\\"))
    	dirarg = dirarg.substr(0, dirarg.length() - 1);

    ListDirectories(dirarg);

    return 0;
}

bool parseBool(wstring s)
{
	return s.size() > 0 ? (tolower(trim(s)) == L"true") : false;
}

wstring toupper(wstring s)
{
	for(auto& c : s)
		c = toupper(c);
	return s;
}

wstring tolower(wstring s)
{
	for(auto& c : s)
		c = tolower(c);
	return s;
}

std::wstring GetAbsolutePath(const std::wstring& path) {
	wstring copypath = path;
	//handle empty strings
	if(trim(copypath) == L"")
	{
		wchar_t buffer[MAX_PATH];
		GetCurrentDirectoryW(MAX_PATH, buffer);
		return wstring(buffer);
	}
    wchar_t absolutePath[MAX_PATH];

    DWORD length = GetFullPathNameW(path.c_str(), MAX_PATH, absolutePath, nullptr);

    if (length == 0) {
        // Handle error
        std::wcerr << L"Error getting absolute path." << std::endl;
        return L"";
    }

    return std::wstring(absolutePath);
}

void ListDirectories(const std::wstring& directory) {
    WIN32_FIND_DATAW findFileData;
    HANDLE hFind = INVALID_HANDLE_VALUE;

    std::wstring searchPath = directory + L"\\*";
    hFind = FindFirstFileW(searchPath.c_str(), &findFileData);

    if (hFind == INVALID_HANDLE_VALUE) {
        wcerr << L"Access Denied: " << directory << std::endl;
        return;
    }
    bool idir = Bare; //if bare is true don't print it

    do {
    	std::wstring currentPath = directory + L"\\" + findFileData.cFileName;
    	DWORD att = findFileData.dwFileAttributes;
    	DWORD rpid = GetReparsePointId(currentPath, att);//Resource Point ID
    	wstring targ = L"";
    	wstring type = L"";
    	bool isDIR = att & FILE_ATTRIBUTE_DIRECTORY;
    	wstring name = findFileData.cFileName;
    	if(!Bare)
    	{
			if(rpid == IO_REPARSE_TAG_MOUNT_POINT)
			{
				targ = L" [" + getTarget(currentPath) + L"]";
				type = L"<JUNCTION> ";
			}
			else if(rpid == IO_REPARSE_TAG_SYMLINK)
			{
				targ = L" [" + getTarget(currentPath) + L"]";
				type = isDIR ? L"<SYMLINKD> " : L"<SYMLINK> ";
			}
			else if(isDIR)
			{
				type = L"<DIR> ";
			}
    	}
		if(foundFile(currentPath, name, att, rpid))
		{
			//print the initial directory
			if(!idir)
			{
				wcout << endl << L" Directory of " << directory << endl << endl;
				idir = true;
			}
			if(Bare)
				wcout << type << currentPath << targ << endl;
			else
				wcout << type << findFileData.cFileName << targ << endl;
		}
    } while (FindNextFileW(hFind, &findFileData) != 0);
    FindClose(hFind);

    //Go Through all Sub Directories
    if(Recurse)
    {
		hFind = FindFirstFileW(searchPath.c_str(), &findFileData);
		if (hFind != INVALID_HANDLE_VALUE)
		{
			do
			{
				DWORD att = findFileData.dwFileAttributes;
				if(att & FILE_ATTRIBUTE_DIRECTORY)
				{
					wstring name = findFileData.cFileName;
		            if ((name != L".") && (name != L".."))
		            {
		            	std::wstring currentPath = directory + L"\\" + name;
		            	DWORD rp = GetReparsePointId(currentPath, att);
		            	if (!isLink(rp))
		                	ListDirectories(currentPath);
		            }
				}
			} while (FindNextFileW(hFind, &findFileData) != 0);
		}
		FindClose(hFind);
    }
}

bool foundFile(wstring &path, wstring &name, DWORD &attr, DWORD &RPID)
{
	if ((name != L".") && (name != L".."))
	{
		return true;
	}
	return false;
}

/**
 * ONEDRIVE reparse points don't show themselves unless under C:\Windows is the parent directory.
 * Fortunately this method handles when the program is installed in the windows folder itself
 */
bool isLink(DWORD &RPID)
{
	for (DWORD n : NoLNKS)
		if (n == RPID)
			return false;
	return RPID != 0;
}

DWORD GetReparsePointId(wstring &path, DWORD &att)
{
	if(att & FILE_ATTRIBUTE_REPARSE_POINT)
	{
		return GetRPTag(path);
	}
	return 0;
}

/**
 * Handles any reparse points including non microsoft ones
 */
DWORD GetRPTag(wstring &path)
{
	HANDLE hFile = CreateFileW(path.c_str(),
			FILE_READ_EA, //0,
			FILE_SHARE_VALID_FLAGS, //FILE_SHARE_WRITE|FILE_SHARE_DELETE
			0,
			OPEN_EXISTING,
			FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, 0);

    if (hFile == INVALID_HANDLE_VALUE) {
		wcerr << L"ReparsePoint Failed:" << GetLastError() << " " << path << endl;
        CloseHandle(hFile);
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
		wcerr << L"ReparsePoint Failed:" << GetLastError() << " " << path << endl;
        CloseHandle(hFile);
        return 0;
    }
    DWORD tag = reparseData->ReparseTag;
    CloseHandle(hFile);
    return tag;
}

wstring getTarget(wstring &path)
{
	HANDLE hFile = CreateFileW(path.c_str(),
			FILE_READ_EA, //0,
			FILE_SHARE_VALID_FLAGS, //FILE_SHARE_WRITE|FILE_SHARE_DELETE
			0,
			OPEN_EXISTING,
			FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, 0);

	if (hFile == INVALID_HANDLE_VALUE)
	{
		wcerr << L"ReparsePoint Failed:" << GetLastError() << " " << path << endl;
		CloseHandle(hFile);
		return L"";
	}

	// Allocate the reparse data structure
    DWORD dwBufSize = MAXIMUM_REPARSE_DATA_BUFFER_SIZE;
    REPARSE_DATA_BUFFER* rdata;
    rdata = (REPARSE_DATA_BUFFER*) malloc(dwBufSize);

    // Query the reparse data
    DWORD dwRetLen;
    BOOL bRet = DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL, 0, rdata, dwBufSize, &dwRetLen, NULL);
    CloseHandle(hFile);
    if (bRet == FALSE)
    {
    	wcerr << L"ReparsePoint Failed:" << GetLastError() << " " << path << endl;
    	return L"";
    }

    wstring targ = L"";
	ULONG ReparseTag = rdata->ReparseTag;
    if (IsReparseTagMicrosoft(ReparseTag))
    {
    	if (ReparseTag == IO_REPARSE_TAG_SYMLINK)
    	{
    		size_t plen = rdata->SymbolicLinkReparseBuffer.PrintNameLength / sizeof(WCHAR);
    		WCHAR *szPrintName = new WCHAR[plen+1];
    		wcsncpy_s(szPrintName, plen+1, &rdata->SymbolicLinkReparseBuffer.PathBuffer[rdata->SymbolicLinkReparseBuffer.PrintNameOffset / sizeof(WCHAR)], plen);
    		szPrintName[plen] = 0;
    		targ = szPrintName;
    		delete [] szPrintName;
      }
      else if (ReparseTag == IO_REPARSE_TAG_MOUNT_POINT)
      {
    	  size_t plen = rdata->MountPointReparseBuffer.PrintNameLength / sizeof(WCHAR);
    	  WCHAR *szPrintName = new WCHAR[plen+1];
    	  wcsncpy_s(szPrintName, plen+1, &rdata->MountPointReparseBuffer.PathBuffer[rdata->MountPointReparseBuffer.PrintNameOffset / sizeof(WCHAR)], plen);
    	  szPrintName[plen] = 0;
    	  targ = szPrintName;
    	  delete [] szPrintName;
      }
      else
      {
    	  wcerr << L"No Mount-Point or Symblic-Link..." << endl;
      }
    }
    else
    {
    	wcerr << L"Not a Microsoft-reparse point - could not query data!" << endl;
    }
    free(rdata);
    return targ;
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

wstring trim(wstring str)
{
    str.erase(str.find_last_not_of(' ')+1);         //suffixing spaces
    str.erase(0, str.find_first_not_of(' '));       //prefixing spaces
    return str;
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
        std::wcerr << L"Err Loading Config: " << GetLastError() << std::endl;
    }
}
