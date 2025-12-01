@ECHO OFF
set CURRENT_VERSION_KEY="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
set BUILD_LAB_VAR="BuildLabEx"
set EDITION_ID_VAR="EditionID"

set CURRENT_BUILD=0000
set CURRENT_ARCH=meow128fre
set CURRENT_LAB_NAME=meowmain

rem Our variables for no-no builds. We have a special edge case for 8020 winmain x86/amd64.
set NO_NO_LAB_BUILD_MIN_FLOOR=8049
set NO_NO_LAB_BUILD_EDGECASE_NUM=8020
set NO_NO_LAB_WM_EEAP_FLOOR=8090
set NO_NO_LAB_WM_EEAP_CEILING=8102
set NO_NO_LAB=fbl_eeap
set NO_NO_LAB_WM=winmain
set NO_NO_LAB_WM_EEAP=winmain_win8m3_eeap
set ARM_UNSUPPORTED_FLAVOR_FRE=armfre
set ARM_UNSUPPORTED_FLAVOR_CHK=armchk

rem Stored to skip dropping ShSxS payload on 8102
set RP_SHSXS_SKIP_BUILDNUM=8102
set RP_SHSXS_SKIP_LAB=winmain_win8m3

rem Needed for 7989 edge case...
set RP_SKU_CLIENT_ULTIMATE=Ultimate
set RP_7989_SANITY_FCIV_EXE=%~dp0\..\Bin\FCIV\fciv.exe
set RP_7989_SANITY_CURRENT_SHA=TempVar
set RP_7989_SANITY_EXPECTED_SHA=17b9e705ba867d93068a5dca2e98473160fc5584

rem These is the applicable build range we'll set for this script. Prevent our redpill installer from running if we're out of this range.
rem SPP format change happened sometime around ~788x-7891. ~7885 is a safe bet.
set REDPILL_MIN_SUPPORT_FLOOR=7779
set REDPILL_MIN_SUPPORT_OLD_SPP_FORMAT_CEILING=7885
set REDPILL_MIN_SUPPORT_CEILING=8123

rem Query the current OS edition.
@FOR /f "tokens=3*" %%i in (
	'reg query %CURRENT_VERSION_KEY% /v %EDITION_ID_VAR%'
) do set CURRENT_SKU=%%i

rem Query the build lab.
@FOR /f "tokens=3" %%i in (
	'reg query %CURRENT_VERSION_KEY% /v %BUILD_LAB_VAR%'
) do set BUILD_LAB_STR=%%i

if defined BUILD_LAB_STR (
	echo.
	echo Running Windows OS build %BUILD_LAB_STR%
	echo.
	@FOR /f "tokens=1 delims=." %%i in ( "%BUILD_LAB_STR%" ) do ( echo Current build num: %%i & set CURRENT_BUILD=%%i )
	@FOR /f "tokens=3 delims=." %%i in ( "%BUILD_LAB_STR%" ) do ( echo Current build arch: %%i & set CURRENT_ARCH=%%i )
	@FOR /f "tokens=4 delims=." %%i in ( "%BUILD_LAB_STR%" ) do ( echo Current build lab: %%i & set CURRENT_LAB_NAME=%%i )
	echo Current OS edition: %CURRENT_SKU%
	goto :CheckForNoNo
) else (
	echo Couldn't find BuildLabEx string! Exiting.
	exit /b 1
)

:CheckForNoNo
echo.
echo Checking build applicability...
echo.

rem AdvancedRun and Redlock aren't available on ARMv7/WoA builds, so we need to fail if our build flavor is armfre/armchk.
if %CURRENT_ARCH% == %ARM_UNSUPPORTED_FLAVOR_FRE% (
	echo Unsupported OS build flavor - armfre
	set IS_RUNNING_ARM=1
	set SCREWED=1
	goto :EOF
) else if %CURRENT_ARCH% == %ARM_UNSUPPORTED_FLAVOR_CHK% (
	echo Unsupported OS build flavor - armchk
	set IS_RUNNING_ARM=1
	set SCREWED=1
	goto :EOF
) else if %CURRENT_ARCH% NEQ %ARM_UNSUPPORTED_FLAVOR_FRE% if %CURRENT_ARCH% NEQ %ARM_UNSUPPORTED_FLAVOR_FRE% (
	set IS_RUNNING_ARM=0
)

rem We want to make sure we're not on a build that's too old or too new to run here.
if %CURRENT_BUILD% LSS %REDPILL_MIN_SUPPORT_FLOOR%  (
	echo Build's too old for this to work. Failing...
	set BUILD_TOO_HIGH=1
	set SCREWED=1
	goto :EOF
) else if %CURRENT_BUILD% GTR %REDPILL_MIN_SUPPORT_CEILING%  (
	echo Build's too new for this to work. Failing...
	set BUILD_TOO_HIGH=1
	set SCREWED=1
	goto :EOF
)

rem ...and this is needed if we're on a build that uses the older SPP store format.
if %CURRENT_BUILD% GEQ %REDPILL_MIN_SUPPORT_FLOOR% if %CURRENT_BUILD% LEQ %REDPILL_MIN_SUPPORT_OLD_SPP_FORMAT_CEILING%  (
	echo Old SPP format detected.
	set IS_RUNNING_OLD_BUILD=1
)

rem Check if we're running EEAP >= 8049 or WM 8020 x86/amd64. Also blacklist winmain_win8m3_eeap.
if %CURRENT_BUILD% GEQ %NO_NO_LAB_BUILD_MIN_FLOOR% if %CURRENT_LAB_NAME% == %NO_NO_LAB% (
	echo We're running a stripped-down EEAP build. Failing...
	set SCREWED=1
	goto :EOF
)

if %CURRENT_BUILD% == %NO_NO_LAB_BUILD_EDGECASE_NUM% if %CURRENT_LAB_NAME% == %NO_NO_LAB_WM% (
	echo Special edge case detected - We're running 8020 winmain x86/amd64. Failing...
	set SCREWED=1
	goto :EOF
)

if %CURRENT_BUILD% GEQ %NO_NO_LAB_WM_EEAP_FLOOR% if %CURRENT_BUILD% LEQ %NO_NO_LAB_WM_EEAP_CEILING% if %CURRENT_LAB_NAME% == %NO_NO_LAB_WM_EEAP% (
	echo Special edge case detected - We're running a winmain_win8m3_eeap build. Failing...
	set SCREWED=1
	goto :EOF
)

if SCREWED == 0 (
	goto :yay
)

rem Edge case for 7989 Ultimate amd64 - the version of twinui.dll in Windows\System32 is a private compile
rem that lacks the appropriate code paths needed for the Windows 8 shell to function properly. If our buildnum
rem is 7989, lab is winmain and current edition is Ultimate, we need to check if twinui has been SFC'd or not.
rem If it returns positive, SFC it and then reboot the system. 

@for /f "skip=3 tokens=1* delims= " %%i in ('%RP_7989_SANITY_FCIV_EXE% -sha1 "%WINDIR%\System32\twinui.dll"') do ( set RP_7989_SANITY_CURRENT_SHA=%%i )
if %CURRENT_BUILD% == 7989 if %CURRENT_LAB_NAME% == %NO_NO_LAB_WM% if %CURRENT_ARCH% == amd64fre if %CURRENT_SKU% == %RP_SKU_CLIENT_ULTIMATE% (
	rem Invoke FCIV and check hash.
	echo Special edge case detected - We're running 7989 Ultimate amd64fre. Checking hash of TWINUI...
	
	rem print hashes
	echo.
	echo Current TwinUI hash: %RP_7989_SANITY_CURRENT_SHA%
	echo Expected TwinUI hash: %RP_7989_SANITY_EXPECTED_SHA%
	if not %RP_7989_SANITY_CURRENT_SHA% == %RP_7989_SANITY_EXPECTED_SHA% (
		rem We've got a match, SFC it and mark system as ineligible for pilling.
		echo.
		echo Bad TWINUI library detected. Restoring clean copy from WinSxS...
		echo.
		sfc /scanfile="%WINDIR%\System32\twinui.dll" > NUL
		set RP_BAD_TWINUI_DLL=1
		set SCREWED=1
		goto :EOF
	)
)

rem This exists so we can skip the ShSxS payload if we're on 8102 WINMAIN_WIN8M3.
if %CURRENT_BUILD% == %RP_SHSXS_SKIP_BUILDNUM% if %CURRENT_LAB_NAME% == %RP_SHSXS_SKIP_LAB% (
	echo Win8 Developer Preview detected. Payload drop will be skipped.
	set RP_SHSXS_SKIP_REQUIRED=1
	goto :yay
)

:yay
echo We're good. Continuing...
echo.

