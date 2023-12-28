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

//Declare classes here
class AttFilter;
class RPFilter;

//Declare Vars here
bool Recurse = false;
bool Bare = false;
bool Parseable = false;
bool HasRPF = false;
bool FoundFile = false;
bool RPVal = false;
bool ShowHL = false;
bool HLFil = false;
bool NHLFil = false;
wstring Attribs = L"";
vector<DWORD> NoLNKS;
vector <DWORD> NoPrintLNKS;
vector<wstring> SRCHBL;

//Declare program Methods here
void ListDirectories(const std::wstring& directory);
bool isBlackListed(const wstring &dir);
bool foundFile(wstring &path, wstring &n, DWORD &attr, DWORD &RPID);
bool isLink(DWORD &RPID);
bool isPrintLink(DWORD &RPID);
DWORD GetReparsePointId(wstring &path, DWORD &att);
DWORD GetRPTag(wstring &path);
wstring GetTarget(wstring &path);
std::wstring GetAbsolutePath(const std::wstring& path);
void LoadCFG(wstring &cfg);
void LoadRPBL(wstring &cfg, vector<DWORD> &bl);
void help();
bool isAttr(DWORD &att, DWORD &RPID);
void ParseAttribFilters(const wstring &attfilters);
bool isRP(DWORD &attr, DWORD &RPID);
void ParseRPFilters(const wstring &rpcmd);
void PrintHardLinks(const wstring &filePath);

//Declare Utility methods here
wstring AddSlash(wstring &s);
bool EndsWith (const std::wstring &fullString, const std::wstring &ending);
bool exists(const std::wstring& filePath);
DWORD fromHex(wstring v);
int IndexOf(wstring str, wstring key);
wstring parent(wstring path);
bool parseBool(wstring s);
wstring ReplaceAll(wstring& str, const wstring& from, const wstring& to);
int revIndexOf(wstring str, wstring key);
vector<wstring> split(const std::wstring& input, wchar_t c);
wstring toHex(unsigned long v);
wstring tolower(wstring s);
LPWSTR toLPWSTR(const std::wstring& str);
wstring toupper(wstring s);
wstring trim(wstring str);
void AddOneDriveCompat();

int main() {
	setlocale(LC_CTYPE, "");
	_setmode( _fileno(stdout), _O_U8TEXT );
	AddOneDriveCompat();

	//Make the command lines suitable for paths
	wstring cmdline = GetCommandLineW();
	ReplaceAll(cmdline, L"\\\\", L"\\");
	ReplaceAll(cmdline, L"\\", L"/");
	LPWSTR lpwstrcmd = toLPWSTR(cmdline);
	int argv;
	LPWSTR* cargs = CommandLineToArgvW(lpwstrcmd, &argv);
	vector<wstring> args;
	for(int i=0; i < argv; i++)
	{
		wstring s = cargs[i];
		wstring t = toupper(trim(s));
		if(t == L"/R") {
			RPVal = true;
		}
		else if(t == L"/H") {
			ShowHL = true;
		}
		else if(t == L"/HF") {
			HLFil = true;
		}
		else if(t == L"/-HF") {
			NHLFil = true;
		}
		else if(t == L"/?" || t == L"/HELP") {
			help();
		}
		else {
			args.push_back(ReplaceAll(s, L"/", L"\\"));
		}
	}
	//Check for Incompatible Filters
	if(HLFil && NHLFil)
	{
		wcerr << "Incompatible Filters Hard Link Filter and No Hard Link Filters" << endl;
		exit(1);
	}

	int argc = args.size();

	//Parse Args
	wstring WorkingDir = parent(wstring(args[0]));
	vector<wstring> dirpaths;
	if(argc > 1)
	{
		wstring dirstr = wstring(args[1]);
		vector<wstring> paths = split(dirstr, L';');
		for(wstring d : paths)
		{
			wstring dirarg = GetAbsolutePath(d);
			if(dirarg.size() > 1 && EndsWith(dirarg, L"\\"))
			{
				dirarg = dirarg.substr(0, dirarg.length() - 1);
			}
			dirpaths.push_back(dirarg);
		}
	 }
	 else
	 {
		 dirpaths.push_back(GetAbsolutePath(L""));
	 }
	 if(argc > 2) {
    	Recurse = parseBool(trim(args[2]));
	 }
	 if(argc > 3)
	 {
    	wstring mode = toupper(trim(args[3])).substr(0, 1);
    	if(mode == L"B")
    	{
    		Bare = true;
    	}
    	else if(mode == L"P")
    	{
    		Parseable = true;
    	}
	 }
	 if(argc > 4) {
    	Attribs = toupper(trim(args[4]));
    	ParseAttribFilters(Attribs);
	 }
	 else {
		 ParseAttribFilters(L"-HS");//Mimic Dir command by adding default attribute filter of not having hidden or system files
	 }
	 if(argc > 5) {
		ParseRPFilters(args[5]);
	 }
	 //Dynamic Exclusions
	 if(argc > 6)
	 {
		 vector<wstring> bl = split(trim(args[6]), L';');
		 for(wstring line : bl)
		 {
	        line = tolower(trim(line));
	        if(line.substr(1, 1) == L":")
	        	line = line.substr(2);
	        if(line != L"")
	        	SRCHBL.push_back(AddSlash(line));
		 }
	 }
	 //Get the working directory and load the config
	 LoadCFG(WorkingDir);
	 for(wstring d : dirpaths)
	 {
		 ListDirectories(d);
	 }
	 return FoundFile ? 0 : 404;
}

void ListDirectories(const std::wstring& directory) {
	if(isBlackListed(directory))
	{
		return;
	}
    WIN32_FIND_DATAW findFileData;
    HANDLE hFind = INVALID_HANDLE_VALUE;

    std::wstring searchPath = directory + L"\\*.*";
    hFind = FindFirstFileW(searchPath.c_str(), &findFileData);

    if (hFind == INVALID_HANDLE_VALUE) {
        wcerr << L"Access Denied: " << directory << std::endl;
        return;
    }
    bool idir = false;

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
				targ = L" <" + GetTarget(currentPath) + L">";
				type = L"<JUNCTION> ";
			}
			else if(rpid == IO_REPARSE_TAG_SYMLINK)
			{
				targ = L" <" + GetTarget(currentPath) + L">";
				type = isDIR ? L"<SYMLINKD> " : L"<SYMLINK> ";
			}
			else if(isDIR)
			{
				type = L"<DIR> ";
			}
			else if (Parseable)
			{
				type = L"<FILE> ";
			}
    	}

		if(foundFile(currentPath, name, att, rpid))
		{
			if(Bare) {
				wcout << currentPath << endl;
			}
			else if(Parseable) {
				wstring rpv = RPVal ? (L" <" + toHex(rpid) + L">") : L"";
				if(!ShowHL) {
					wcout << type << "<" << currentPath << L">" << rpv << targ << endl;
				}
				else
				{
					wcout << type << "<" << currentPath;
					if(!isDIR)
						PrintHardLinks(currentPath);
					wcout << L">" << rpv << targ << endl;
				}
			}
			else
			{
				//print the initial directory
				if(!idir)
				{
					wcout << endl << L" Directory of " << directory << (directory.size() < 3 ? (L"\\") : (L"")) << endl << endl;
					idir = true;
				}
				wstring rpv = RPVal ? (L" <" + toHex(rpid) + L">") : L"";
				if(!ShowHL) {
					wcout << type << name << rpv << targ << endl;
				}
				else
				{
					wcout << type << name;
					if(!isDIR)
						PrintHardLinks(currentPath);
					wcout << rpv << targ << endl;
				}
			}
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

bool isHardLink(const wstring &filePath)
{
	wstring drive = filePath.substr(0, 1) + L":";
	wstring lpath = tolower(filePath);
    HANDLE hFindFile;
    WCHAR szBuffer[MAX_PATH];
    DWORD dwBufferSize = sizeof(szBuffer);

    hFindFile = FindFirstFileNameW(filePath.c_str(), 0, &dwBufferSize, szBuffer);
    if (hFindFile == INVALID_HANDLE_VALUE) {
    	FindClose(hFindFile);
        return false;
    }

    do {
    	wstring hl = drive + wstring(szBuffer);
    	if(tolower(hl) != lpath)
    	{
    		FindClose(hFindFile);
    		return true;
    	}

        dwBufferSize = sizeof(szBuffer);
    } while (FindNextFileNameW(hFindFile, &dwBufferSize, szBuffer) != 0);

    FindClose(hFindFile);
    return false;
}

/**
 * Get All HardLinks given a file WIN32 API call
 */
void PrintHardLinks(const wstring &filePath) {
	wstring drive = filePath.substr(0, 1) + L":";
	wstring lpath = tolower(filePath);
    HANDLE hFindFile;
    WCHAR szBuffer[MAX_PATH];
    DWORD dwBufferSize = sizeof(szBuffer);

    hFindFile = FindFirstFileNameW(filePath.c_str(), 0, &dwBufferSize, szBuffer);
    if (hFindFile == INVALID_HANDLE_VALUE) {
//        wcerr << L"Error finding file names: " << filePath << L" " << GetLastError() << endl;
    	FindClose(hFindFile);
        return;
    }

    do {
    	wstring hl = drive + wstring(szBuffer);
    	if(tolower(hl) != lpath)
    		wcout << L";" << hl;

        dwBufferSize = sizeof(szBuffer);
    } while (FindNextFileNameW(hFindFile, &dwBufferSize, szBuffer) != 0);

    FindClose(hFindFile);
}

bool isBlackListed(const wstring &c)
{
	//transform the path into an exclusion comparable path
	wstring child = tolower(c);
    if(child.substr(1, 1) == L":") {
    	child = child.substr(2);
    }
	if(child.back() != L'\\') {
		child = child + L"\\";
	}

	for(wstring parent : SRCHBL)
		if(IndexOf(child, parent) == 0)
			return true;
	return false;
}


bool foundFile(wstring &path, wstring &name, DWORD &attr, DWORD &RPID)
{
	if ((name == L".") || (name == L"..") || !isAttr(attr, RPID) || !isRP(attr, RPID) || (HLFil && !isHardLink(path)) || (NHLFil && isHardLink(path)))
	{
		return false;
	}
	FoundFile = true;
	return true;
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

bool isPrintLink(DWORD &RPID)
{
	for (DWORD n : NoPrintLNKS)
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

wstring GetTarget(wstring &path)
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

wstring GetAbsolutePath(const std::wstring& path) {
	wstring copypath = trim(path);
	//handle empty strings or drives
	if(copypath == L"")
	{
		wchar_t buffer[MAX_PATH];
		GetCurrentDirectoryW(MAX_PATH, buffer);
		return wstring(buffer);
	}
	else if((copypath.size() == 2) && (copypath.substr(1, 1) == L":"))
	{
		return copypath + L"\\";
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

void LoadCFG(wstring &workdir)
{
	wstring cfg = workdir + L"\\SRCHReparsePoints.cfg";
	wstring cfgprint = workdir + L"\\PrintReparsePointsBL.cfg";
	wstring cfgsrch = workdir + L"\\SRCHDirBL.cfg";
	LoadRPBL(cfg, NoLNKS);
	LoadRPBL(cfgprint, NoPrintLNKS);

    //Parse Search Blacklist
	if(!exists(cfgsrch))
	{
		std::wofstream filewriter(cfgsrch.c_str());
		filewriter << L"C:\\Windows\\servicing" << endl;
		filewriter << L"C:\\Windows\\WinSxS" << endl;
		filewriter.close();
	}
    std::wifstream srchfile(cfgsrch.c_str());
    if (srchfile.is_open())
    {
        std::wstring line;
        while (std::getline(srchfile, line))
        {
        	line = tolower(trim(line));
        	if(line.substr(1, 1) == L":")
        		line = line.substr(2);
        	if(line != L"")
        		SRCHBL.push_back(AddSlash(line));
        }
    }
    else
    {
        std::wcerr << L"Err Loading Dir Blacklist: " << GetLastError() << std::endl;
    }
    srchfile.close();
}

//Internal Do not use
void LoadRPBL(wstring &cfg, vector<DWORD> &bl)
{
	//create config file if it doesn't exist and then read config file
	if(!exists(cfg))
	{
		std::wofstream filewriter(cfg.c_str());
		filewriter << L"IO_REPARSE_TAG_CLOUD_6 = 0x9000601A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD = 0x9000001A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_1 = 0x9000101A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_2 = 0x9000201A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_3 = 0x9000301A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_4 = 0x9000401A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_5 = 0x9000501A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_7 = 0x9000701A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_8 = 0x9000801A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_9 = 0x9000901A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_A = 0x9000A01A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_B = 0x9000B01A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_C = 0x9000C01A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_D = 0x9000D01A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_E = 0x9000E01A" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_F = 0x9000F01A" << endl;
		filewriter << L"IO_REPARSE_TAG_ONEDRIVE = 0x80000021" << endl;
		filewriter << L"IO_REPARSE_TAG_CLOUD_MASK = 0x0000F000" << endl;
		filewriter.close();
	}

    std::wifstream file(cfg.c_str());
    if (file.is_open())
    {
        std::wstring line;
        while (std::getline(file, line))
        {
        	line = trim(line.substr(IndexOf(line, L"=") + 1));
        	if(line != L"")
        		bl.push_back(fromHex(line));
        }
    }
    else
    {
        std::wcerr << L"Err Loading Config: " << GetLastError() << std::endl;
    }
    file.close();
}

void help()
{
	wcout << L"" << endl;
	wcout << L"###################################################################################################################" << endl;
	wcout << L"DirSafe.exe <DIR Or Dir;Dir2\\*PDF|File*.txt> <BOOL RECURSE> <PRINTTYPE> <ATTRIBS> <REPARSEPOINTS> <Exclusion;Dir2>" << endl;
	wcout << L"###################################################################################################################" << endl;
	wcout << L"/H Show Hard Links" << endl;
	wcout << L"/R Show Reparse Point Values" << endl;
	wcout << L"PrintTypes:{N = Normal, B = Bare, P = Parseable}" << endl;
	wcout << L"A Archiving" << endl;
	wcout << L"B SMR Blob" << endl;
	wcout << L"D Directories" << endl;
	wcout << L"C Compressed" << endl;
	wcout << L"E Encrypted" << endl;
	wcout << L"H Hidden" << endl;
	wcout << L"I Not Indexed" << endl;
	wcout << L"L Reparse Point Links" << endl;
	wcout << L"M Recall On Data Access" << endl;
	wcout << L"O Offline" << endl;
	wcout << L"P Pinned" << endl;
	wcout << L"Q Recall On Open" << endl;
	wcout << L"R ReadOnly" << endl;
	wcout << L"S System" << endl;
	wcout << L"U UnPinned" << endl;
	wcout << L"V Integrity(ReFS)" << endl;
	wcout << L"X No Scrub(ReFS)" << endl;
	wcout << L"- Prefix meaning not" << endl;
	wcout << L"-- Prefix meaning globally not" << endl;
	wcout << L"| Separator Between Attribute Statements" << endl;
	wcout << L"Example Attributes: \"LHS-O|OM--X\" Says L+H+S-O-X Or O+M-X" << endl;
	wcout << L"Example ReparsePoints: \"0;0xA0000003;0xA000000C=F;0xA000001D=D\" Says NormalFiles Or MountPoint(FD) Or SYMLINK as a File Or LX_SYMLINK as a DIR" << endl;
	wcout << L"Example Exclusions: \"W:\\Windows\\System32;C:\\ExternalWIN\" Says Do not Search in System32 or ExternalWIN. Drives get Truncated" << endl;
	wcout << L"" << endl;
	exit(0);
}

//#####################
//	START OOP METHODS
//#####################
vector<DWORD> AttGlobalBL;
vector<AttFilter> AttFilters;
class AttFilter {
public:
	vector<DWORD> req;
	vector<DWORD> blacklist;
	AttFilter(){}

	AttFilter(const wstring &attribs)
	{
		ParseAttribs(attribs);
	}

	~AttFilter()
	{
		req.clear();
		blacklist.clear();
	}

	/**
	 * Doesn't Check the Global Blacklist
	 */
	bool isFile(DWORD &att, DWORD &RPID)
	{
		for(DWORD d : blacklist)
		{
			bool isAtt = d == FILE_ATTRIBUTE_REPARSE_POINT ? ((att & d) && isPrintLink(RPID)) : (att & d);
			if(isAtt)
			{
				return false;
			}
		}
		for(DWORD d : req)
		{
			bool isAtt = d == FILE_ATTRIBUTE_REPARSE_POINT ? ((att & d) && isPrintLink(RPID)) : (att & d);
			if(!isAtt)
			{
				return false;
			}
		}
		return true;//if att is not on the blacklist and has no attribute filter return true otherwise it's false
	}
	/**
	 * parse the attributes variable from a string into the AttribsFilter & AttribsFilterBL
	 */
	void ParseAttribs(const wstring &atts)
	{
		vector<DWORD>* attribs = &req;
		wchar_t lch = ' ';
		for (wchar_t ch : atts)
		{
			switch (ch)
			{
				case L'-':
					if(lch == L'-')
					{
						attribs = &AttGlobalBL;
					}
					else
					{
						attribs = &blacklist;
					}
				break;
				case L'R':
					attribs->push_back(FILE_ATTRIBUTE_READONLY);
				break;
				case L'H':
					attribs->push_back(FILE_ATTRIBUTE_HIDDEN);
				break;
				case L'S':
					attribs->push_back(FILE_ATTRIBUTE_SYSTEM);
				break;
				case L'D':
					attribs->push_back(FILE_ATTRIBUTE_DIRECTORY);
				break;
				case L'A':
					attribs->push_back(FILE_ATTRIBUTE_ARCHIVE);
				break;
				case L'L':
					attribs->push_back(FILE_ATTRIBUTE_REPARSE_POINT);
				break;
				case L'O':
					attribs->push_back(FILE_ATTRIBUTE_OFFLINE);
				break;
				case L'I':
					attribs->push_back(FILE_ATTRIBUTE_NOT_CONTENT_INDEXED);
				break;
				//START Extended Attributes
				case L'P':
					attribs->push_back(FILE_ATTRIBUTE_PINNED);
				break;
				case L'U':
					attribs->push_back(FILE_ATTRIBUTE_UNPINNED);
				break;
				//OneDrive or cloud files but they won't always have this attribute reparse points are more reliable in determining onedrive files
				case L'M':
					attribs->push_back(FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS);
				break;
				case L'Q':
					attribs->push_back(FILE_ATTRIBUTE_RECALL_ON_OPEN);
				break;
				case L'C':
					attribs->push_back(FILE_ATTRIBUTE_COMPRESSED);
				break;
				case L'E':
					attribs->push_back(FILE_ATTRIBUTE_ENCRYPTED);
				break;
				//ReFS attribs
				case L'X':
					attribs->push_back(FILE_ATTRIBUTE_NO_SCRUB_DATA);
				break;
				case L'V':
					attribs->push_back(FILE_ATTRIBUTE_INTEGRITY_STREAM);
				break;
				case L'B':
					attribs->push_back(FILE_ATTRIBUTE_STRICTLY_SEQUENTIAL);
				break;
				default:
	            // Do nothing or add cases for other characters if needed
	            break;
			}
			lch = ch;
		}
	}
};

/**
 * Checks All Attribute Filters and The Global Blacklist for them
 */
bool isAttr(DWORD &att, DWORD &RPID)
{
	//checks global blacklist
	for(DWORD d : AttGlobalBL)
	{
		bool isAtt = d == FILE_ATTRIBUTE_REPARSE_POINT ? ((att & d) && isPrintLink(RPID)) : (att & d);
		if(isAtt)
		{
			return false;
		}
	}
	//checks each individual entry to see if one of them returns true
	for(AttFilter attfil : AttFilters)
	{
		if(attfil.isFile(att, RPID))
		{
			return true;
		}
	}
	return AttFilters.empty();
}

/**
 * Parse the entire attributes argument from command line into memory
 */
void ParseAttribFilters(const wstring &attfilters)
{
	vector<wstring> attstrvec = split(attfilters, '|');
	for(wstring attstr : attstrvec)
	{
		AttFilters.push_back(AttFilter(toupper(trim(attstr))));
	}
}

vector<RPFilter> RPFilters;
class RPFilter {
public:
	DWORD RPTag = -1;
	bool File = false;
	bool Dir = false;
	RPFilter(){}
	RPFilter(const wstring &e)
	{
		wstring entry = toupper(e);
		vector<wstring> pair = split(entry, '=');
		RPTag = fromHex(trim(pair[0]));
		if(pair.size() > 1)
		{
			wstring var = trim(pair[1]);
			for(wchar_t ch : var)
			{
				if(ch == L'D')
				{
					Dir = true;
				}
				else if(ch == L'F')
				{
					File = true;
				}
			}
		}
		else
		{
			Dir = true;
			File = true;
		}
	}
};

/**
 * ReparsePoint Filter
 */
bool isRP(DWORD &attr, DWORD &RPID)
{
	if(!HasRPF)
		return true;
	bool isDIR = attr & FILE_ATTRIBUTE_DIRECTORY;
	for(RPFilter r : RPFilters)
	{
		if((isDIR ? r.Dir : r.File))
		{
			DWORD d = r.RPTag;
			//if it's the whitelisted RPID or if if NULL(0) is in the RPFilter and It's not a Link Print it
			if(d == RPID || (d == 0 && !isPrintLink(RPID)))
				return true;
		}
	}
	return false;
}

void ParseRPFilters(const wstring &rpstr)
{
	wstring rpcmd = rpstr;
	ReplaceAll(rpcmd, L"|", L";");//make RP filter user-freindly
	ReplaceAll(rpcmd, L" ", L"");//remove all spaces
	vector<wstring> rps = split(rpcmd, L';');
	for(wstring rp : rps)
	{
		if(!rp.empty())
		{
			HasRPF = true;
			RPFilters.push_back(RPFilter(rp));
		}
	}
}


//#####################
//START UTILITY METHODS
//#####################

/**
 * Safely Add OneDrive Compatibility Mode for (Windows 10 1709) 2017+ or higher
 */
void AddOneDriveCompat()
{
	//Disable WOW64 File Redirection in case people use the x86 version on x64 or ARM64
    PVOID OldValue = NULL;
	if (Wow64DisableWow64FsRedirection(&OldValue)) {
		wcout << "Disabled WOW64 File Redirectrion" << endl;
	}

    typedef NTSTATUS(WINAPI *RtlSetCompatFunc)(CHAR Mode);
    #define PHCM_EXPOSE_PLACEHOLDERS ((CHAR)2)
    HMODULE hmod = LoadLibraryW(L"ntdll.dll");
    if (hmod == NULL)
    {
        wprintf(L"LoadLibrary failed with %u\n", GetLastError());
        FreeLibrary(hmod);
        return;
    }

    RtlSetCompatFunc pRtlSetCompatMode;
    pRtlSetCompatMode = (RtlSetCompatFunc)GetProcAddress(hmod, "RtlSetProcessPlaceholderCompatibilityMode");
    if (pRtlSetCompatMode == NULL)
    {
        wprintf(L"GetProcAddress failed with %u\n", GetLastError());
        FreeLibrary(hmod);
        return;
    }
    pRtlSetCompatMode(PHCM_EXPOSE_PLACEHOLDERS);
    FreeLibrary(hmod);
}

wstring AddSlash(wstring &s)
{
	if((s.size() > 1) && (s.back() != L'\\'))
		s = s + L"\\";
	return s;
}

bool EndsWith (const std::wstring &fullString, const std::wstring &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

bool exists(const std::wstring& filePath) {
    DWORD fileAttributes = GetFileAttributesW(filePath.c_str());
    return fileAttributes != INVALID_FILE_ATTRIBUTES;
}

DWORD fromHex(wstring v)
{
	return std::stoul(v, nullptr, 16);
}

int IndexOf(wstring str, wstring key)
{
	size_t found = str.find(key);
	if(found != std::string::npos)
		 return static_cast<int>(found);
	return -1;
}

wstring parent(wstring path)
{
	int index = revIndexOf(path, L"\\");
	return path.substr(0, index);
}

bool parseBool(wstring s)
{
	return s.size() > 0 ? (tolower(trim(s)) == L"true") : false;
}

wstring ReplaceAll(wstring& str, const wstring& from, const wstring& to) {
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // Handles case where 'to' is a substring of 'from'
    }
    return str;
}

int revIndexOf(wstring str, wstring key)
{
	size_t found = str.rfind(key);
	if(found != std::string::npos)
		 return static_cast<int>(found);
	return -1;
}

vector<wstring> split(const std::wstring& input, wchar_t c) {
	vector<wstring> arr;
    size_t startPos = 0;
    size_t foundPos = input.find(c, startPos);
    while (foundPos != std::wstring::npos)
    {
        std::wstring sub = input.substr(startPos, foundPos - startPos);
        arr.push_back(sub);
        startPos = foundPos + 1;
        foundPos = input.find(c, startPos);
    }
    std::wstring lastSub = input.substr(startPos);
    arr.push_back(lastSub);
    return arr;
}

wstring toHex(DWORD v)
{
	std::wstringstream ss;
	ss << std::uppercase << L"0X" << std::setfill(L'0') << std::setw(8) << std::hex << v;
	return ss.str();
}

wstring tolower(wstring s)
{
	for(auto& c : s)
		c = tolower(c);
	return s;
}

wstring toupper(wstring s)
{
	for(auto& c : s)
		c = toupper(c);
	return s;
}

LPWSTR toLPWSTR(const std::wstring& str) {
    LPWSTR lpwstr = new wchar_t[str.size() + 1];
    wcscpy_s(lpwstr, str.size() + 1, str.c_str());
    return lpwstr;
}

wstring trim(wstring str)
{
    str.erase(str.find_last_not_of(' ')+1);         //suffixing spaces
    str.erase(0, str.find_first_not_of(' '));       //prefixing spaces
    return str;
}
