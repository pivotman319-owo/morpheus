@ECHO OFF && CLS

@FOR /f "tokens=2 delims=\" %%i in ( 'whoami' ) do (set CURRENT_USER=%%i)

if %PHASE2_READY% NEQ 1 (
	title Wrong Script File Invoked
	color 4F
	echo.
	echo     Please invoke "morpheus.bat" instead of this dependency script.
	echo.
	echo     Press any key to exit.
	echo.
	pause > NUL
	cls
	exit /d 1
)

rem For Charms bar
set CHARMS_MODE_MIN_BUILD=8008
set CHARMS_MODE_MAX_BUILD=8040
set CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH=HKEY_USERS\DefAccountHive

title Morpheus - Phase 2
echo.
echo Initiating Phase 2...
echo.

rem Installs patched shsxs and ImmersiveBrowser
echo.
echo Installing Redpill components...
"%~dp0\..\Bin\AdvRun\AdvancedRun.exe" /Clear /ExeFilename "%~dp0\..\Bin\Redlock\redlock.exe" /CommandLine "audit nopol" /RunAs 8 /Run /WaitProcess 1 & if not ERRORLEVEL == 0 ( exit /b 1 )

echo.
echo Enabling extra non-Redlock bits...
echo.

echo Enabling new UI for Windows Boot Manager and WinRE
rem 0x250000c2 - BootMenuPolicy
bcdedit /set {globalsettings} custom:250000c2 1
echo.

rem RibbonizeMePlease
echo Enabling Ribbon for 7xxx-series builds
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "RibbonizeMePlease" /t REG_DWORD /d 1 /f > NUL
echo.

rem FileCopy
echo Enabling File Copy Dialog for 78xx-series builds
reg add "HKEY_CLASSES_ROOT\CLSID\{3f97e701-2fad-40b5-90fc-77ca1a723a3a}" /v "AppID" /t REG_SZ /d "{8F09011C-9A2A-4BBD-A04F-FF1C635DBCA3}" /f > NUL
echo.

echo EnablePatternLogonForInternalTesting
echo Enabling Pattern Logon for 78xx-series builds
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion" /v "EnablePatternLogonForInternalTesting" /t REG_DWORD /d 1 /f > NUL
echo.

rem Ask the user if they'd like the fully-fledged Charms Bar, if they're running on a period-appropriate build
if %CURRENT_BUILD% GEQ %CHARMS_MODE_MIN_BUILD% if %CURRENT_BUILD% LEQ %CHARMS_MODE_MAX_BUILD% (
	rem The prompt.
	echo Morpheus has detected that this build is using an alternate touch screen-based Charms Bar invocation method.
	echo Do you want to enable the Charms Bar?
	echo.
	echo Note that doing this will disable the Charms Menu located at the Start button.
	echo.
	
	choice /C YN /M "Waiting for input: "
	echo.
	
	if ERRORLEVEL == 2 (
		goto :EnableLeftCharms
	) else if ERRORLEVEL == 1 (
		goto :EnableRightCharms
	)
)

:EnableLeftCharms
echo Enabling Charms Menu...
rem Apply right-hand charms bar mode globally; any new accounts created past this point will also have the alternate bar.
reg load "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%" "%SYSTEMDRIVE%\Users\Default\NTUSER.DAT%" > NUL
reg add "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "CharmBarMode" /t REG_DWORD /d 0 /f > NUL
reg unload "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%" > NUL

rem Do this for the current user as well.
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "CharmBarMode" /t REG_DWORD /d 0 /f > NUL

goto :Finalize

:EnableRightCharms
echo Enabling Charms Bar...
rem Apply right-hand charms bar mode globally; any new accounts created past this point will also have the alternate bar.
reg load "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%" "%SYSTEMDRIVE%\Users\Default\NTUSER.DAT%" > NUL
reg add "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "CharmBarMode" /t REG_DWORD /d 1 /f > NUL
reg unload "%CHARMS_MODE_GLOBAL_ACCOUNT_HIVE_PATH%" > NUL

rem Do this for the current user as well.
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "CharmBarMode" /t REG_DWORD /d 1 /f > NUL

goto :Finalize

:Finalize
echo.

if ERRORLEVEL == 0 (
	rem We're done.
	set PILL_COMPLETE=1
) else (
	rem What the fuck even happened here?
	exit /b 1
)
