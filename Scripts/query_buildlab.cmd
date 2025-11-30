@ECHO OFF
set CURRENT_VERSION_KEY="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
set BUILD_LAB_VAR="BuildLabEx"
set EDITION_ID_VAR="EditionID"

rem Our variables for no-no builds. We have a special edge case for 8020 winmain x86/amd64.
set NO_NO_LAB_BUILD_MIN_FLOOR=8049
set NO_NO_LAB_BUILD_EDGECASE_NUM=8020
set NO_NO_LAB=fbl_eeap
set NO_NO_LAB_WM=winmain
set ARM_UNSUPPORTED_FLAVOR_FRE=armfre
set ARM_UNSUPPORTED_FLAVOR_CHK=armchk

rem rem The SKUs this'll work with. Either Prerelease or ServerDatacenter.
rem set REQUIRED_SKU_CLIENT=Prerelease
rem set REQUIRED_SKU_SERVER=ServerDatacenter

rem These is the applicable build range we'll set for this script. Prevent our redpill installer from running if we're out of this range.
rem SPP format change happened sometime around ~788x-7891. ~7885 is a safe bet.
set REDPILL_MIN_SUPPORT_FLOOR=7779
set REDPILL_MIN_SUPPORT_OLD_SPP_FORMAT_CEILING=7885
set REDPILL_MIN_SUPPORT_CEILING=8123

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
	goto :CheckForNoNo
) else (
	echo Couldn't find BuildLabEx string! Exiting.
	exit /b 1
)

:CheckForNoNo
echo.
echo Checking build applicability...
echo.

rem rem Are we running an appropriate Windows edition for RP01-PDC?
rem @FOR /f "tokens=3*" %%i in (
rem 	'reg query %CURRENT_VERSION_KEY% /v %EDITION_ID_VAR%'
rem ) do set CURRENT_SKU=%%i

rem if %CURRENT_SKU% == %REQUIRED_SKU_CLIENT% (
rem 	rem blah
rem ) else if %CURRENT_SKU% == %REQUIRED_SKU_SERVER% (
rem 	rem blah
rem ) else (
rem 	rem We're not running the right edition. Exit.
rem 	set UNSUPPORTED_SKU=1
rem 	set SCREWED=1
rem 	goto :EOF
rem )

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

rem Check if we're running EEAP >= 8049 or WM 8020 x86/amd64.
if %CURRENT_BUILD% GEQ %NO_NO_LAB_BUILD_MIN_FLOOR% if %CURRENT_LAB_NAME% == %NO_NO_LAB% (
	echo We're running a stripped-down EEAP build. Failing...
	set SCREWED=1
	goto :EOF
) else if %CURRENT_BUILD% == %NO_NO_LAB_BUILD_EDGECASE_NUM% if %CURRENT_LAB_NAME% == %NO_NO_LAB_WM% (
	echo Special edge case detected - We're running 8020 winmain x86/amd64. Failing...
	set SCREWED=1
	goto :EOF
) else if SCREWED == 0 (
	goto :yay
)

:yay
echo We're good. Continuing...
echo.

