@echo off
: test if command prompt was "run as administrator"
net session > nul 2>&1
if NOT "%ERRORLEVEL%" == "0" goto :notadmin
setlocal enableextensions
setlocal enabledelayedexpansion

: iterate through all video controllers identified by wmic
for /f "tokens=2 delims=, usebackq eol=" %%v in (`wmic path win32_VideoController get name /format:csv ^|findstr /I "%computername%"`) do (
	set VideoName=%%v
	: The video name set above includes an ascii 13 (carriage return)
	: "...:~0,-1..." below removes the extra char
	wmic path Win32_PNPEntity where "Name='!VideoName:~0,-1!'" call disable
	wmic path Win32_PNPEntity where "Name='!VideoName:~0,-1!'" call enable
	)
goto :eof

:notadmin
	: create a vbs script to get elevated privilege 
	: then re-run this script (%~s0)
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1  >> "%temp%\getadmin.vbs"
	echo Set objShell = CreateObject^("WScript.Shell"^)        > "%temp%\activate.vbs"
	echo objShell.AppActivate "Video Reset" >> "%temp%\activate.vbs"
	"%temp%\getadmin.vbs"
	"%temp%\activate.vbs"
    del "%temp%\getadmin.vbs"
	del "%temp%\activate.vbs"
    exit /B
