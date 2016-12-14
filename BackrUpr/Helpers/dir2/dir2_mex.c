#pragma comment(lib, "shlwapi.lib")
#include <stdio.h>
#include <windows.h>
#include <shlwapi.h>
#include "mex.h"

#define MAX_FILES		 10000000 // max number of files
#define NUMBER_OF_FIELDS 	 5
#define MAX_NUM_FILTERS		 100000	  // max number of filters
#define NAMEFIELD 	 	 0
#define DATEFIELD 	 	 1
#define BYTESFIELD 	 	 2
#define ISDIRFIELD 	 	 3
#define DATENUMFIELD 	 	 4

#define PARSE_CHARS(aC); \
1; \
	if (mxIsChar(aC)) { \
		temp = (char *)mxArrayToString(aC); \
		if (strstr(temp,"*") != NULL) \
		{ \
			if (!hasDir) \
			{ \
				parts = fileSplit(temp,dir,fn); \
				dir = parts.dir; \
				fn  = parts.fn; \
				if (strlen(dir) == 0) \
				{ \
					getcwd(path, MAX_PATH); \
					dir = path; \
				} \
				hasDir = 1; \
				if (strlen(fn) != 0) \
				{ \
					filter[nFilts] = fn; \
					nFilts++; \
				} \
			} else { \
				filter[nFilts] = temp; \
				nFilts++; \
			} \
		} else if (strstr(temp,"-r") != NULL) \
		{ \
			isRecursive = 1; \
		} else if (!hasDir) \
		{ \
			dir = temp; \
			hasDir = 1; \
		} else \
		{ \
			filter[nFilts] = fn; \
			nFilts++; \
		} \
	} else { \
		printf("One or more inputs could not be understood. Please verify that all inputs are strings or cell strings.\n"); \
	}
	
// Type defs
 typedef struct {
     char   *dir;
     char   *fn;
 } fileparts;

// Prototypes
int wildcmp(const char *wild, char *string);
char* monthNumToStr(int monthNum);
void addResultsEntry(WIN32_FIND_DATA WFD, int cnt, mxArray *structOut, char *defaultPath);
int search(LPSTR lpszPath, char **filter, int nFilts, int cnt, mxArray *structOut, char *defaultPath);
int searchRecursive(LPSTR lpszPath, char **filter, int nFilts, int cnt, mxArray *structOut, const char *defaultPath);
fileparts fileSplit(const char *input);


void mexFunction(int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[])
{
	// Declare variables
	char **fieldnames[NUMBER_OF_FIELDS];
	char *dir, *temp, *fn;
	char **filter[MAX_NUM_FILTERS];
	int ii, jj, nFilts = 0, isRecursive = 0, nCells = 0;
	int hasDir = 0, hasRec;
	const mxArray *aC, *C, *structOut, **ms, **ma;
	int cnt = 0;
	char *defaultPath = "";
	char path[MAX_PATH+1];
	char path2[MAX_PATH+1];
	fileparts parts;
	
	// Set Field Names
	fieldnames[0] = "name";
	fieldnames[1] = "date";
	fieldnames[2] = "bytes";
	fieldnames[3] = "isdir";
	fieldnames[4] = "datenum";
	
	// Parse inputs
	for (ii = 0; ii < nrhs; ii++)
	{
		aC = prhs[ii];
		if (mxIsCell(aC)) {
			nCells = mxGetNumberOfElements(aC);
			for (jj = 0; jj < nCells; jj++)
			{
				C = mxGetCell( aC , jj);
				{PARSE_CHARS(C);}
			}
		} else {
			{PARSE_CHARS(aC);}
		}
	}
	
	// Default path
	if (!hasDir)
	{ 
		getcwd(path, MAX_PATH);
		dir = path;
	}
	
	// Default filter
	if (nFilts == 0) {
		nFilts = 1;
		filter[0] = "*";
	}
	
	// Handle Relative Paths
	if (!strstr(dir,":")) {
		getcwd(path2, MAX_PATH);
		dir = strcat( strcat(path2, "\\") ,dir);
	}
	
	// Make the output structure
	structOut = mxCreateStructMatrix(MAX_FILES, 1, NUMBER_OF_FIELDS, fieldnames);
	
	// Search
	if (isRecursive){
		cnt = searchRecursive(dir,filter,nFilts,cnt,structOut,defaultPath);
	} else {
		cnt = search(dir,filter,nFilts,cnt,structOut,defaultPath);
	}
	
	// Trim off excess and pass it out
	ms = mxGetData(structOut);
	ma = mxMalloc(cnt*NUMBER_OF_FIELDS*sizeof(ms));
	for( ii=0; ii<cnt*NUMBER_OF_FIELDS; ii++ ) {
		ma[ii] = ms[ii];
	}
	mxFree(ms);
	mxSetData(structOut,ma);
	mxSetM(structOut,cnt);
	plhs[0] = structOut;
    return 0;
}

int wildcmp(const char *wild, char *string) {
  // Written by Jack Handy - <A href="mailto:jakkhandy@hotmail.com">jakkhandy@hotmail.com</A>
  const char *cp = NULL, *mp = NULL;

  while ((*string) && (*wild != '*')) {
    if ((*wild != *string) && (*wild != '?')) {
      return 0;
    }
    wild++;
    string++;
  }

  while (*string) {
    if (*wild == '*') {
      if (!*++wild) {
        return 1;
      }
      mp = wild;
      cp = string+1;
    } else if ((tolower(*wild) == tolower(*string)) || (*wild == '?')) {
      wild++;
      string++;
    } else {
      wild = mp;
      string = cp++;
    }
  }

  while (*wild == '*') {
    wild++;
  }
  return !*wild;
}

char * monthNumToStr(int monthNum)
{
	char *month;
	switch (monthNum) {
		case 1:
			month = "Jan";
			break;
		case 2:
			month = "Feb";
			break;
		case 3:
			month = "Mar";
			break;
		case 4:
			month = "Apr";
			break;
		case 5:
			month = "May";
			break;
		case 6:
			month = "Jun";
			break;
		case 7:
			month = "Jul";
			break;
		case 8:
			month = "Aug";
			break;
		case 9:
			month = "Sep";
			break;
		case 10:
			month = "Oct";
			break;
		case 11:
			month = "Nov";
			break;
		case 12:
			month = "Dec";
			break;
		default:
			printf("Cannon understand month number %d\n",monthNum);
			month = "NaN";
			break;
	}
	
	return(month);
}

void addResultsEntry(WIN32_FIND_DATA WFD, int cnt, mxArray *structOut, char *defaultPath)
{
	char *buff[40], *month = "NaN";
	char filename[MAX_PATH + 1];
	double temp;
	mxArray *name, *date, *bytes, *isdir, *datenum;
	SYSTEMTIME stUTC, stLocal;
	FILETIME ftUTC, ftLocal;
	
	// File Name
	if (strlen(defaultPath) > 0){
	PathCombine(filename, defaultPath, WFD.cFileName);
	name = mxCreateString(filename);
	} else {
		name = mxCreateString(WFD.cFileName);
	}
	mxSetFieldByNumber(structOut, cnt, NAMEFIELD , name);
	
	// Size (bytes)
	bytes = mxCreateDoubleScalar((WFD.nFileSizeHigh * (MAXDWORD+1)) + WFD.nFileSizeLow);
	mxSetFieldByNumber(structOut, cnt, BYTESFIELD , bytes);
	
	// Directory flag
	isdir = mxCreateLogicalScalar((WFD.dwFileAttributes == FILE_ATTRIBUTE_DIRECTORY));
	mxSetFieldByNumber(structOut, cnt, ISDIRFIELD , isdir);
	
	// Get local time
	ftUTC = WFD.ftLastWriteTime;
	FileTimeToSystemTime(&ftUTC, &stUTC);
    SystemTimeToTzSpecificLocalTime(NULL, &stUTC, &stLocal);

	// Date string
	month = monthNumToStr(stLocal.wMonth);
	sprintf(buff,"%02d-%s-%04d %02d:%02d:%02d",stLocal.wDay,month,stLocal.wYear,stLocal.wHour,stLocal.wMinute,stLocal.wSecond);
	date = mxCreateString(buff);
	mxSetFieldByNumber(structOut, cnt, DATEFIELD , date);
	
	// Datenum
	SystemTimeToFileTime(&stLocal,&ftLocal);
	temp =  (double) ftLocal.dwHighDateTime;
	temp = temp * ((double)MAXDWORD+1);
	temp = temp + ftLocal.dwLowDateTime;
	datenum = mxCreateDoubleScalar((temp/864000000000) + 584755);
	mxSetFieldByNumber(structOut, cnt, DATENUMFIELD , datenum);

}

int search(LPSTR lpszPath, char **filter, int nFilts, int cnt, mxArray *structOut, char *defaultPath)
{
	int ii, passes;
    WIN32_FIND_DATA WFD;
    HANDLE hSearch;
    CHAR szFilePath[MAX_PATH + 1];
    PathCombine(szFilePath, lpszPath, "*");
    hSearch = FindFirstFile(szFilePath,&WFD);
    do {
		passes = 0;
		for (ii = 0; ii < nFilts; ii++) {
			if (wildcmp(filter[ii],WFD.cFileName)){
				passes = 1;
				break;
			}
		}
		if (passes){
			addResultsEntry(WFD, cnt, structOut, defaultPath);
			cnt++;
		}
    } while (FindNextFile(hSearch,&WFD));
    FindClose(hSearch);
    return(cnt);
}

int searchRecursive(LPSTR lpszPath, char **filter, int nFilts, int cnt, mxArray *structOut, const char *defaultPath)
{
	int ii, passes;
    WIN32_FIND_DATA WFD;
    HANDLE hSearch;
    CHAR szFilePath[MAX_PATH + 1];
	char defaultPathNew[MAX_PATH + 1];
    PathCombine(szFilePath, lpszPath, "*");
    hSearch = FindFirstFile(szFilePath,&WFD);
    do {
        if(strcmp(WFD.cFileName,"..") && strcmp(WFD.cFileName,"."))
        {
			if(WFD.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			{
				PathCombine(szFilePath, lpszPath, WFD.cFileName);
				PathCombine(defaultPathNew,defaultPath,WFD.cFileName);
				cnt = searchRecursive(szFilePath, filter, nFilts, cnt, structOut, &defaultPathNew);
			}
		}
		passes = 0;
		for (ii = 0; ii < nFilts; ii++) {
			if (wildcmp(filter[ii],WFD.cFileName)){
				passes = 1;
				break;
			}
		}
		if (passes){
			addResultsEntry(WFD, cnt, structOut, defaultPath);
			cnt++;
		}
    } while (FindNextFile(hSearch,&WFD));
    FindClose(hSearch);
    return(cnt);
}

fileparts fileSplit(const char *input)
{
	char *temp, *dir, *fn;
	fileparts parts;
	int len, ii, boundry = -1;
	len = strlen(input);
	for (ii = len - 1; ii >= 0; ii--)
	{
		if ((input[ii] == '/') || (input[ii] == '\\' ))
		{
			boundry = ii;
			break;
		}
	}
	dir = strdup(input);
	dir[boundry+1] = NULL;
	fn = strdup(input + boundry + 1);
	fn[len+1] = NULL;
	
	parts.dir = dir;
	parts.fn  = fn;
	
	return(parts);
}
