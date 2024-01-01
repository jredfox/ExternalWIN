#include <windows.h>
#include <iostream>
#include <string>
#include <sstream>
#include <cstring>
#include <fstream>
#include <vector>
#include <iomanip>
#include <fcntl.h>
#include <stdio.h>
#include <aclapi.h>
#include <tchar.h>
#include <Accctrl.h>
#include <Aclapi.h>

using namespace std;
vector<DWORD> OneLinks = {0x9000601A, 0x9000001A, 0x9000101A, 0x9000201A, 0x9000301A, 0x9000401A, 0x9000501A, 0x9000701A, 0x9000801A, 0x9000901A, 0x9000A01A, 0x9000B01A, 0x9000C01A, 0x9000D01A, 0x9000E01A, 0x9000F01A, 0x80000021, 0x0000F000};

/**
 * ONEDRIVE reparse points don't show themselves unless under C:\Windows is the parent directory.
 * Fortunately this method handles when the program is installed in the windows folder itself
 */
bool isLink(DWORD &RPID)
{
	for (DWORD n : OneLinks)
		if (n == RPID)
			return false;
	return RPID != 0;
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

DWORD GetReparsePointId(wstring &path, DWORD &att)
{
	if(att & FILE_ATTRIBUTE_REPARSE_POINT)
	{
		return GetRPTag(path);
	}
	return 0;
}

void SetFilePermission(const wstring &FileName)
{
    PSID pEveryoneSID = NULL;
    PACL pACL = NULL;
    EXPLICIT_ACCESS ea[1];
    SID_IDENTIFIER_AUTHORITY SIDAuthWorld = SECURITY_WORLD_SID_AUTHORITY;

    // Create a well-known SID for the Everyone group.
    AllocateAndInitializeSid(&SIDAuthWorld, 1,
                     SECURITY_WORLD_RID,
                     0, 0, 0, 0, 0, 0, 0,
                     &pEveryoneSID);

    // Initialize an EXPLICIT_ACCESS structure for an ACE.
    ZeroMemory(&ea, 1 * sizeof(EXPLICIT_ACCESS));
    ea[0].grfAccessPermissions = 0xFFFFFFFF;
    ea[0].grfAccessMode = GRANT_ACCESS;
    ea[0].grfInheritance= NO_INHERITANCE;
    ea[0].Trustee.TrusteeForm = TRUSTEE_IS_SID;
    ea[0].Trustee.TrusteeType = TRUSTEE_IS_WELL_KNOWN_GROUP;
    ea[0].Trustee.ptstrName  = (LPTSTR) pEveryoneSID;

    // Create a new ACL that contains the new ACEs.
    SetEntriesInAcl(1, ea, NULL, &pACL);

    // Initialize a security descriptor.
    PSECURITY_DESCRIPTOR pSD = (PSECURITY_DESCRIPTOR) LocalAlloc(LPTR,
                                SECURITY_DESCRIPTOR_MIN_LENGTH);

    InitializeSecurityDescriptor(pSD,SECURITY_DESCRIPTOR_REVISION);

    // Add the ACL to the security descriptor.
    SetSecurityDescriptorDacl(pSD,
            TRUE,     // bDaclPresent flag
            pACL,
            FALSE);   // not a default DACL


    //Change the security attributes
    SetFileSecurityW(FileName.c_str(), DACL_SECURITY_INFORMATION, pSD);

    if (pEveryoneSID)
        FreeSid(pEveryoneSID);
    if (pACL)
        LocalFree(pACL);
    if (pSD)
        LocalFree(pSD);
}

void ListDirectories(const std::wstring& directory) {
	SetFilePermission(directory);
//	wcout << L"Granted:" << directory << endl;

    WIN32_FIND_DATAW findFileData;
    HANDLE hFind = INVALID_HANDLE_VALUE;

    std::wstring searchPath = directory + L"\\*.*";
    hFind = FindFirstFileW(searchPath.c_str(), &findFileData);

    if (hFind == INVALID_HANDLE_VALUE) {
    	wcerr << L"Access Denied: " << directory << L" Err:" << GetLastError() << endl;
    }

	hFind = FindFirstFileW(searchPath.c_str(), &findFileData);
	if (hFind != INVALID_HANDLE_VALUE)
	{
		do
		{
			std::wstring currentPath = directory + L"\\" + findFileData.cFileName;
			DWORD att = findFileData.dwFileAttributes;
			if(att & FILE_ATTRIBUTE_DIRECTORY)
			{
				wstring name = findFileData.cFileName;
	            if ((name != L".") && (name != L".."))
	            {
	            	DWORD rp = GetReparsePointId(currentPath, att);
	            	if (!isLink(rp))
	                	ListDirectories(currentPath);
	            	else
	            		SetFilePermission(currentPath); //If SYMLINK or JUNCTION set the permission on the link itself
	            }
			}
			else
			{
				SetFilePermission(currentPath);
			}
		} while (FindNextFileW(hFind, &findFileData) != 0);
	}
	FindClose(hFind);
}

bool EndsWith (const std::wstring &fullString, const std::wstring &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

wstring trim(wstring str)
{
    str.erase(str.find_last_not_of(' ')+1);         //suffixing spaces
    str.erase(0, str.find_first_not_of(' '));       //prefixing spaces
    return str;
}

wstring tolower(wstring s)
{
	for(auto& c : s)
		c = tolower(c);
	return s;
}

wstring RemSlash(wstring str)
{
	if(str.size() > 2 && EndsWith(str, L"\\"))
	{
		str = str.substr(0, str.length() - 1);
	}
	return str;
}

wstring ReplaceAll(wstring& str, const wstring& from, const wstring& to) {
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // Handles case where 'to' is a substring of 'from'
    }
    return str;
}

LPWSTR toLPWSTR(const std::wstring& str) {
    LPWSTR lpwstr = new wchar_t[str.size() + 1];
    wcscpy_s(lpwstr, str.size() + 1, str.c_str());
    return lpwstr;
}

wstring GetAbsolutePath(const wstring &path)
{
	wstring copypath = trim(path);
	//handle empty strings or drives
	if(copypath == L"")
	{
		wchar_t buffer[MAX_PATH];
		GetCurrentDirectoryW(MAX_PATH, buffer);
		return RemSlash(wstring(buffer));
	}
	else if((copypath.size() == 2) && (copypath.substr(1, 1) == L":"))
	{
		return copypath;
	}
    wchar_t absolutePath[MAX_PATH];

    DWORD length = GetFullPathNameW(path.c_str(), MAX_PATH, absolutePath, nullptr);

    if (length == 0)
    {
    	wcerr << L"Error getting absolute path." << endl;
        return L"";
    }

    return RemSlash(wstring(absolutePath));
}

int main() {
	setlocale(LC_CTYPE, "");
	_setmode( _fileno(stdout), _O_U8TEXT );

	//Handle Windows ARGS BS
	wstring cmdline = GetCommandLineW();
	ReplaceAll(cmdline, L"\\", L"/");
	LPWSTR lpwstrcmd = toLPWSTR(cmdline);
	int argv;
	LPWSTR* cargs = CommandLineToArgvW(lpwstrcmd, &argv);
	vector<wstring> args;
	for(int i=0; i < argv; i++)
	{
		wstring s = cargs[i];
		wstring h = tolower(trim(s));
		s = RemSlash(s);
		//Help command
		if(h == L"/?" || h == L"/help") {
			wcout << "Grant.exe <DIR>" << endl;
			exit(0);
		}
		args.push_back(ReplaceAll(s, L"/", L"\\"));
	}

	//Main Program
	wstring dir = GetAbsolutePath(args[1]);
	wcout << L"Granting Dir:" << dir << endl;
	ListDirectories(dir);
}
