@echo off
:
: cleartemp.bat
:	Clear out "temp" and "content.ie5"
:
: 3/12/2016
:	Display the largest temp folder filecount
:	(if possible) check for elevated privileges
:
: 6/11/2015
:	Add code to clear:
:	* appdata\local\...\temporary internet files
:	* appdata\local\mozilla\...\cache2\entries
:
:	Fix a bug with counting files (change 'dir /a/b...' to 'dir /s/b...')
:
: 6/24/2013
:	Add code to support %1 as the folder to clear out.
:
: 3/26/2013
:	Add code to show counts of files to be removed from each folder
:	Results can be saved by redirecting batch output using "^> c:\cleartemp.log"
:
: 6/8/2011
:	Clear out 'Flash Player' data
:	Support Win 7 workstations
:
: 1/15/2008
:	Modified to clear all local profiles by default.  
:	(Assumes profiles are stored in %systemdrive%\Documents and Settings)
:
: 1/12/2008
:	Modified to take a profile name as an argument
:	(so "cleartemp j.blow" will clear out temp files in \Documents and Settings\j.blow\Local Settings)
:
:


if "%1" == "" goto :setdefaults
set PROFILEDIR=%1

if not "%2" == "" set drivetodo=%2


:setdefaults

net session > nul 2>&1
if NOT "%ERRORLEVEL%" == "0" goto :notadmin

setlocal enableextensions enabledelayedexpansion

set TMPCOUNT=0
set TMPFOLDER=""
if "%1"=="" set PROFILEDIR=!userprofile:%username%=!
if "%2"=="" set drivetodo=%systemdrive%
set winfold=NONE
if exist %drivetodo%\windows set winfold=%drivetodo%\WINDOWS
if exist %drivetodo%\winnt set winfold=%drivetodo%\WINNT
if "%drivetodo%" == "%WINDIR:~0,2%" set winfold=%windir%
if "%winfold%" == "NONE" goto :syntax

:begin
 %drivetodo%
 if not exist %PROFILEDIR% GOTO :syntax
 echo cleartemp running in %CD%
 echo Clearing %drivetodo%\temp ...
   if not exist %drivetodo%\temp goto :windowstemp
   for /f %%j in ('dir /s /B "%drivetodo%\temp"^| find /C /V ""') do set fcount=%%j
   echo ^(!fcount! files^):	%drivetodo%\temp
   if !fcount! GTR !TMPCOUNT! set TMPFOLDER=%drivetodo%\temp
   if !fcount! GTR !TMPCOUNT! set TMPCOUNT=!fcount!
   rd /s /q "%drivetodo%\temp" >nul 2>&1
   md "%drivetodo%\temp" >nul 2>&1

:windowstemp
   for /f %%j in ('dir /s /B "%winfold%\temp"^| find /C /V ""') do set fcount=%%j
   echo ^(!fcount! files^):	%winfold%\temp
   if !fcount! GTR !TMPCOUNT! set TMPFOLDER=%winfold%\temp
   if !fcount! GTR !TMPCOUNT! set TMPCOUNT=!fcount!
   rd /s /q "%winfold%\temp" >nul 2>&1
   md "%winfold%\temp" >nul 2>&1

   for /f %%j in ('dir /s /B "%winfold%\system32\config\systemprofile\local settings\temp"^| find /C /V ""') do set fcount=%%j
   echo ^(!fcount! files^):	%winfold%\system32\config\systemprofile\local settings\temp
   if !fcount! GTR !TMPCOUNT! set TMPFOLDER=%winfold%\system32\config\systemprofile\local settings\temp
   if !fcount! GTR !TMPCOUNT! set TMPCOUNT=!fcount!
   rd /s /q "%winfold%\system32\config\systemprofile\local settings\temp" >nul 2>&1
   md "%winfold%\system32\config\systemprofile\local settings\temp" >nul 2>&1

   for /f %%j in ('dir /s /B "%winfold%\system32\config\systemprofile\local settings\temporary internet files"^| find /C /V ""') do set fcount=%%j
   echo ^(!fcount! files^):	%winfold%\system32\config\systemprofile\local settings\temporary internet files
   if !fcount! GTR !TMPCOUNT! set TMPFOLDER=%winfold%\system32\config\systemprofile\local settings\temporary internet files
   if !fcount! GTR !TMPCOUNT! set TMPCOUNT=!fcount!
   rd /s /q "%winfold%\system32\config\systemprofile\local settings\temporary internet files" >nul 2>&1
   md "%winfold%\system32\config\systemprofile\local settings\Temporary Internet Files" >nul 2>&1

 
 cd "%PROFILEDIR%"
 echo Clearing User temp files...
 for /d %%D in (*) do (
     for /f %%j in ('dir /s /B "%%D\Local Settings\temp"^| find /C /V ""') do set fcount=%%j
     echo ^(!fcount! files^):	!PROFILEDIR!%%D\Local Settings\Temp
     if !fcount! GTR !TMPCOUNT! set TMPFOLDER=!PROFILEDIR!%%D\Local Settings\Temp
     if !fcount! GTR !TMPCOUNT! set TMPCOUNT=!fcount!
     rd /s /q "%%D\Local Settings\temp" >nul 2>&1
     md "%%D\Local Settings\temp" >nul 2>&1
     for /f %%j in ('dir /s /B "%%D\Local Settings\Temporary Internet Files"^| find /C /V ""') do set fcount=%%j
     echo ^(!fcount! files^):	!PROFILEDIR!%%D\Local Settings\Temporary Internet Files
     rd /s /q "%%D\Local Settings\Temporary Internet Files" > nul 2>&1
     md       "%%D\Local Settings\Temporary Internet Files" > nul 2>&1
     if exist "%%D\Appdata\Roaming\*" (
	     for /f %%j in ('dir /s /B "%%D\AppData\Roaming\Macromedia\Flash Player" ^| find /C /V ""') do set fcount=%%j
	     echo ^(!fcount! files^):	!PROFILEDIR!%%D\AppData\Roaming\Macromedia\Flash Player
	     rd /s /q "%%D\AppData\Roaming\Macromedia\Flash Player" > nul 2>&1
	     md       "%%D\AppData\Roaming\Macromedia\Flash Player" > nul 2>&1
	) else (
	     for /f %%j in ('dir /s /B "%%D\Application Data\Macromedia\Flash Player" ^| find /C /V ""') do set fcount=%%j
	     echo ^(!fcount! files^):	!PROFILEDIR!%%D\Application Data\Macromedia\Flash Player
	     rd /s /q "%%D\Application Data\Macromedia\Flash Player" > nul 2>&1
	     md       "%%D\Application Data\Macromedia\Flash Player" > nul 2>&1
	)

rem     :
rem     : AppData\Local\Microsoft\Windows\Temporary Internet Files
rem     :
     if exist "%%D\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*" (
	     for /f %%j in ('dir /S /B "%%D\Appdata\Local\Microsoft\Windows\Temporary Internet Files\" ^| find /C /V ""') do set fcount=%%j
	     echo ^(!fcount! files^):	!PROFILEDIR!%%D\Appdata\Local\Microsoft\Windows\Temporary Internet Files\
	     rd /s /q "%%D\Appdata\Local\Microsoft\Windows\Temporary Internet Files\" > nul 2>&1
	     md       "%%D\Appdata\Local\Microsoft\Windows\Temporary Internet Files\" > nul 2>&1
	) 

rem     :
rem     : Local\Mozilla\Firefox\Profiles\mrkjoir2.default-1413476180671\cache2\entries
rem     : for /f %c in ('dir /ad /s/b cache2') do rd /s /q %c\entries & md %c\entries
rem     :
rem     if exist "%%D\Appdata\Local\Mozilla\*" (
rem	cd "%%D\Appdata\Local\Mozilla"
rem	for /f %%c in ('dir /ad /s/b cache2') do (
rem	     set CACHEDIR=%%c
rem	     for /f %%j in ('dir /A /B "!CACHEDIR!\entries" ^| find /C /V ""') do set fcount=%%j
rem		     echo ^(!fcount! files^):	!CACHEDIR!
rem		     rd /s /q "!CACHEDIR!\entries" > nul 2>&1
rem		     md       "!CACHEDIR!\entries"
rem	     ) 
rem	)
rem
     if "%1"=="pause" pause
    )
echo.
echo.
echo.
echo.
echo Largest TEMP Folder (excluding browser cache folders):
echo.
echo 	%TMPFOLDER%	^(%TMPCOUNT% files^)
echo.
echo.
if %TMPCOUNT% GEQ 512 (
echo 256+  temp files can slow your computer slightly
echo 768+  temp files can slow your computer noticeably
echo 1768+ temp files can introduce odd behavior ^(some programs stop working^)
)
echo.
echo Press any key to exit...
pause > nul
endlocal
goto :exit

:notadmin
        echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
        echo UAC.ShellExecute "%~s0", "", "", "runas", 1  >> "%temp%\getadmin.vbs"
        "%temp%\getadmin.vbs"
        del "%temp%\getadmin.vbs"
        exit /B
		goto :syntax
cls
echo.
echo.
echo.

echo ###################################################################
echo ###################################################################
echo.
echo    %~nx0 must be RUN AS ADMINISTRATOR
echo.
echo    You must either run the batch file from an elevated CMD prompt,
echo    or you must right-click, Run As Administrator.
echo.
echo ###################################################################
echo ###################################################################


:syntax
echo.
echo.
echo 	Syntax
echo 	========
echo 	%~nx0 ^<profiledir^> ^<systemdrive^>
echo.
echo 	For example, to clear temp files from "computer_name":
echo 	net use x: \\computer_name
echo 	x:
echo 	cd \Documents and Settings
echo 	%0 .\ X:
echo.
echo.
echo Press any key to exit...
pause > nul
goto :exit


 
:exit
