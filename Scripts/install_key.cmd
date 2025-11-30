@ECHO OFF

@FOR /f "tokens=2 delims=\" %%i in ( 'whoami' ) do (set CURRENT_USER=%%i)

if %PHASE1_READY% NEQ 1 (
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

rem Required Redpill licensing data
rem Windows RP Protected Segment 01 (Modern Personality)
set RP01_KEY=6PB3F-HJWFK-X9YD4-8TB7Q-YQ2FB
set RP01_ACTIVATION_ID=cee174ef-dff4-4bbe-bc8f-54efe4881e22

rem Windows RP Protected Segment 02 (MoSh Platform and Dev Resources + Windows FTE Protected Features)
set RP02_ACTIVATION_ID=7f7bf1f2-c863-4d30-b15c-ada9ca945f2c

rem Windows RP Protected Segment 03 (Windows FTE Protected Features)
set RP03_ACTIVATION_ID=4eda97c7-bcdd-4b66-99a0-fbe1ac1a6db7

rem Windows RP Protected Segment 04 (Unknown)
set RP04_ACTIVATION_ID=791126b6-f5c5-467a-a2a2-31e35bfdfd53

rem Windows RP Protected Segment 05 (Unknown)
set RP05_ACTIVATION_ID=f2e0cd04-d62c-4073-9990-6b8625bacae3

set WMIC_ACTIVATION_ID_TO_CHECK=TempVar

rem TSForge config values
set TSFORGE_PATH="%~dp0\..\Bin\TSForge\TSForge.exe"
set TSFORGE_OS_TYPE=TempVar
rem set RP01_ZERO_CID=000000000000000000000000000000000000000000000000

rem Path to SLMGR.vbs
set SLMGR_PATH="%WINDIR%\System32\slmgr.vbs"

call "%~dp0\KillExplorer.cmd"

xcopy /cherkyq "%~dp0\..\Tokens" "%WINDIR%\System32\spp\tokens"
cscript %SLMGR_PATH% /rilc

rem Remove the pre-existing RP keys just in case...
echo.
echo Uninstalling pre-existing Redpill keys (if applicable)...
echo.
echo Uninstalling RP01(-PDC)...
cscript %SLMGR_PATH% /upk cee174ef-dff4-4bbe-bc8f-54efe4881e22 > NUL
echo Uninstalling RP02...
cscript %SLMGR_PATH% /upk 7f7bf1f2-c863-4d30-b15c-ada9ca945f2c > NUL
echo Uninstalling RP03...
cscript %SLMGR_PATH% /upk 4eda97c7-bcdd-4b66-99a0-fbe1ac1a6db7 > NUL
echo Uninstalling RP04...
cscript %SLMGR_PATH% /upk 791126b6-f5c5-467a-a2a2-31e35bfdfd53 > NUL
echo Uninstalling RP05...
cscript %SLMGR_PATH% /upk f2e0cd04-d62c-4073-9990-6b8625bacae3 > NUL

rem Attempt RP activation.

rem If we're running this on an older Win8 build, we need to make sure TSForge handles this
rem against the old SPP trusted store format. Activation WILL fail if the store structure
rem doesn't match what's being expected by this script.

if %IS_RUNNING_OLD_BUILD% == 1 (
	rem Switch to old SPP store version.
	set TSFORGE_OS_TYPE=8early
) else (
	set TSFORGE_OS_TYPE=8
)

rem Activate system + Redpill license

echo.
echo Attempting Windows RP Protected Segment 0%RP_LICENSE_TIER% Activation
echo.

rem SPP has a serious bug that prevents activation because the trusted store (tokens.dat) is missing crucial variables needed
rem to make activation work properly. So we do fixup of the SPP trusted store.
rem 
rem The only instance where this bug doesn't happen is while making use of Microsoft's own RP01 product key sourced from
rem WINMAIN_WIN8M3 8102.101, the official Win8 Developer Preview build.

rem Do fixup first. Call slmgr.vbs /dlv all to populate the missing activation vars.
echo Fixing up SPP trusted store...
cscript %SLMGR_PATH% /dlv all > NUL

rem Activate the OS.
%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid > NUL
%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /kms4k > NUL

rem Do or die: either install the pre-existing RP01 key from 8102.101, or fix sppsvc for other tiers.
rem For other RP tiers, TSForge our way through it. Store the RP activation ID for later.
if %RP_LICENSE_TIER% == 1 (
	rem Install the RP01 key from WINMAIN_WIN8M3 8102.101
	echo Installing RP01 key...
	cscript %SLMGR_PATH% /ipk %RP01_KEY%
	
	echo Activating RP01 key...
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid %RP01_ACTIVATION_ID% > NUL
	
	rem Store RP01 activation ID for WMIC to check later.
	set WMIC_ACTIVATION_ID_TO_CHECK=%RP01_ACTIVATION_ID%
) else if %RP_LICENSE_TIER% == 2 (
	rem Generate RP02 key in TSForge
	echo Generating RP0%RP_LICENSE_TIER% key...
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /igpk %RP02_ACTIVATION_ID%
	
	rem ZCID it
	echo Activating RP0%RP_LICENSE_TIER% key...
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid %RP02_ACTIVATION_ID%
	
	rem Store activation ID var
	set WMIC_ACTIVATION_ID_TO_CHECK=%RP02_ACTIVATION_ID%
) else if %RP_LICENSE_TIER% == 3 (
	rem Generate RP03 key in TSForge
	echo Generating RP0%RP_LICENSE_TIER% key...
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /igpk %RP03_ACTIVATION_ID%
	
	rem ZCID it
	echo Activating RP0%RP_LICENSE_TIER% key...
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid %RP03_ACTIVATION_ID%

	rem Store activation ID var
	set WMIC_ACTIVATION_ID_TO_CHECK=%RP03_ACTIVATION_ID%
) else if %RP_LICENSE_TIER% == 4 (
	rem Generate RP04 key in TSForge
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /igpk %RP04_ACTIVATION_ID%

	rem ZCID it
	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid %RP04_ACTIVATION_ID%

	rem Store activation ID var
	set WMIC_ACTIVATION_ID_TO_CHECK=%RP04_ACTIVATION_ID%
) 

rem RP05 is broken for some reason. Keeping this commented out.
rem ) else if %RP_LICENSE_TIER% == 5 (
rem 	rem Generate RP05 key in TSForge
rem 	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /igpk %RP05_ACTIVATION_ID%
rem 
rem 	rem ZCID it
rem 	%TSFORGE_PATH% /ver %TSFORGE_OS_TYPE% /prod /zcid %RP05_ACTIVATION_ID%
rem 
rem 	rem Store activation ID var
rem 	set WMIC_ACTIVATION_ID_TO_CHECK=%RP05_ACTIVATION_ID%
rem )

echo.
echo Checking Redpill licensing status...
echo Verifying license status for %WMIC_ACTIVATION_ID_TO_CHECK%

for /F "tokens=2 delims==" %%I IN ('wmic path SoftwareLicensingProduct where "ID='%WMIC_ACTIVATION_ID_TO_CHECK%'" get LicenseStatus /VALUE ^| find "="') do (
    set RP_DATA_LOOKS_RIGHT=%%I
)

if %RP_DATA_LOOKS_RIGHT% == 1 (
	rem Looks good, reload DWM atlas and continue our way through to "Neo".
	echo Redpill key activation succeeded.
) else (
	rem Nope.
	echo Redpill key activation failed.
)

rem Reload DWM atlas for RP.
call "%~dp0\KillDWM.cmd"
rem start "" "%WINDIR%\explorer.exe"
