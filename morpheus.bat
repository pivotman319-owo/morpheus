@ECHO OFF && CLS && ECHO.
setlocal ENABLEDELAYEDEXPANSION

rem Software Protection Platform enablement check
set SPP_SERVICE_STATE=0

rem Redpill licensing variables (used by install_key.cmd)
set RP_DATA_LOOKS_RIGHT=0
set RP_LICENSE_TIER=0
set RP_SHSXS_SKIP_REQUIRED=0

rem "Screwed build" variables
set BUILD_TOO_HIGH=0
set IS_RUNNING_OLD_BUILD=0
set IS_RUNNING_ARM=0
set SCREWED=0

rem Morpheus stage progress vars
set PHASE1_READY=0
set PHASE2_READY=0
set PILL_COMPLETE=0

rem RNG Quote
set STARTPILL_QUOTE="You take the blue pill: the story ends, you wake up in your bed and believe whatever you want to believe. You take the red pill: you stay in Wonderland, and I show you how deep the rabbit hole goes."

whoami /groups /nh | findstr /C:"S-1-16-12288" /C:"S-1-16-16384" > nul & if ERRORLEVEL 1 (
	title Administrative Privileges Required
	color 4F
	echo.
	echo      This script can only be run with administrative privileges.
	echo.
	echo      Press any key to exit.
	echo.
	pause > NUL
	color
	cls
	title
	exit /b 1
)

title Prerequisites Check

:CheckBogusBuild
rem Which build are we running on, exactly?
call "%~dp0Scripts\query_buildlab.cmd"

rem rem Check if the "screwed" value is set to 1. If so, bail and tell the user NOT to run EEAP or winmain 8020.
rem  echo Is Screwed: %SCREWED%
if %BUILD_TOO_HIGH% == 1 ( 
	goto :NoNoBuild_Ceiling
) else if %IS_RUNNING_ARM% == 1 ( 
	goto :IsOnARMv7
) else if %SCREWED% == 1 ( 
	goto :NoNoBuild
) else (
	goto :CheckSPP
)

:CheckSPP
rem Check if sppsvc is disabled.
@FOR /f "tokens=3" %%i in (
	'reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sppsvc" /v "Start"'
) do set SPP_SERVICE_STATE=%%i

rem 4 == Service Disabled
if %SPP_SERVICE_STATE% == 0x4 (
	goto :TheFucksWrongWithYourPC_SPPSvcDisabled
) else (
	rem Start SPP just in case.
	net start sppsvc > NUL
)

rem Check if we're on a build with test-signed spp licenses. We can't cleanly redpill if we're not on one.
if exist "%WINDIR%\System32\spp\store_test" (
	rem echo SPP test store exists, failing now
	goto :TestSignedSPP
) else if exist "%WINDIR%\System32\spp\store" (
	rem Prod-signed. We're good.
	set PHASE1_READY=1
	goto :StartPill_Prompt
) else if not exist "%WINDIR%\System32\spp" (
	rem uh
	goto :TheFucksWrongWithYourPC_NoSPPDir
)

:StartPill_Prompt
rem configure cmd console display
MODE CON COLS=120
cls
title Morpheus - Main Menu
echo.
echo                     ======== Welcome to Morpheus ========
echo.
echo %STARTPILL_QUOTE%
echo.
choice /C PCX /N /M "    Press P to start the Redpilling process, C for credits, or X to quit."

if ERRORLEVEL == 3 (
	cls
	title 
	exit /b 0
) else if ERRORLEVEL == 2 (
	goto :Credits
) else if ERRORLEVEL == 1 (
	goto :SelectRPLevel
)

:Credits
cls.
title Morpheus - Credits
echo.
echo                     ========       Credits       ========
echo.
echo     - pivotman319 - developer of this script
echo     - gus33000, casm for Redlock (for ShSxS/Win8 shell payload)
echo     - The MAS folks for TSForge (used for Redpill activation ^+ key generation)
echo         - Special thanks to WitherOrNot of MAS for debugging sppsvc and
echo           implementing the ridiculously insane hack used to get the other
echo           Redpill tiers working
echo     - NirSoft for AdvancedRun (used for Redlock TrustedInstaller elevation)
echo.
echo   Thank you to all those who tested and provided feedback for Morpheus before
echo   its release!
echo.
echo               ========       No Rights Reserved       ========
echo. 
echo All files used in this script (including those in the Scripts directory) are licensed
echo under the Creative Commons Zero (CC0) license, and therefore falls into the public domain.
echo Some of the tools used by this script, however, belong to their respective authors and 
echo are credited above.
echo.
echo Press any key to go back.
echo.
pause > NUL
goto :StartPill_Prompt

:SelectRPLevel
rem Ask the user which Redpill level they'd like.
cls
title Morpheus - Select Redpill Licensing Tier
echo.
echo Please select a Redpill licensing tier (from 1 to 4; RP05 policies are currently broken):
echo.
echo     - 1: RP01 (Modern Personality) - Full Windows 8 shell
echo         - Start Screen, apps and friends; alternate Aero animation map, DWM atlas
echo     - 2: RP02 (MoSh Platform and Dev Resources ^+ Windows FTE Protected Features)
echo         - Windows Runtime platform, Win32 shell features
echo     - 3: RP03 (Windows FTE Protected Features) - Various Win32 shell features
echo         - Explorer ribbon, new Task Manager, et al.
echo     - 4: RP04
echo         - Small subset of Metro features (Charms, LogonUI et al.)
rem echo     - 5: RP05
echo.
echo Press 'X' to go back to the main menu.
echo.
choice /C 1234X /N /M "Waiting for input: "

rem Set RP license tier and start pilling.
if ERRORLEVEL == 5 (
	goto :StartPill_Prompt
) else if ERRORLEVEL == 4 (
	set RP_LICENSE_TIER=4
	goto :StartPill
) else if ERRORLEVEL == 3 (
	set RP_LICENSE_TIER=3
	goto :StartPill
) else if ERRORLEVEL == 2 (
	set RP_LICENSE_TIER=2
	goto :StartPill
) else if ERRORLEVEL == 1 (
	set RP_LICENSE_TIER=1
	goto :StartPill
)

rem RP05 always fails to activate atm, keeping this commented out.
rem else if ERRORLEVEL == 5 (
rem 	set RP_LICENSE_TIER=5
rem 	goto :StartPill
rem )

:StartPill
rem configure cmd console display
MODE CON COLS=120 LINES=500
CLS

rem If we get to this point, we're good. Start installing RP tokens and then reboot.
title Morpheus - Phase 1
echo.
echo Phase 1: Installing Redpill licenses and keys...
echo.

rem Call the script that copies tokens to the SPP license directory and installs our key.
call "%~dp0Scripts\install_key.cmd"

rem Sanity check before we go and blindly set SystemSetupInProgress...
if %RP_DATA_LOOKS_RIGHT% == 1 (
	set PHASE2_READY=1
	call "%~dp0Scripts\neo.cmd"
) else (
	rem What the fuck even happened here? Bail before things get worse!
	goto :Failed
) 

if %PILL_COMPLETE% == 1 (
	goto :Done
) else (
	goto :Failed
)

:Done
rem All's good.
title Redpill Sucessfully Enabled
cls
echo.
color 2F
echo     ========================================================
echo     ==                                                    ==
echo     == All Redpill features for tier %RP_LICENSE_TIER% are now enabled.   ==
echo     ==                                                    ==
echo     == Press any key to exit.                             ==
echo     ==                                                    ==
echo     ========================================================
pause > nul
color
cls
title 
rem rem Log off.
rem shutdown /l
start "" "%WINDIR%\explorer.exe"
goto :EOF

:Failed
rem We're fucked. Bail.
title Redpill Attempt Failed
echo.
color 4F
echo     ========================================================
echo     ==                                                    ==
echo     == Something has gone horribly wrong and the Redpill  ==
echo     == process has catastrophically failed.               ==
echo     ==                                                    ==
echo     == Please fix any errors in this prompt and then try  ==
echo     == to redpill this system again.                      ==
echo     ==                                                    ==
echo     == Press any key to exit.                             ==
echo     ==                                                    ==
echo     ========================================================
pause > nul
color
cls
title 
rem Invoke CMD + Explorer as a failsafe
start "Emergency Command Shell" "%WINDIR%\System32\cmd.exe"
start "" "%WINDIR%\explorer.exe"
exit

:TestSignedSPP
rem We can't activate RP01 on testsigned builds. Bail.
title Test-Signed Builds Not Supported
cls
color 4F
echo.
echo     You cannot run this script on a build with test-signed Software
echo     Protection Platform (SPP) licensing policies.
echo.
echo     Please use a Windows 8 build that has production-signed SPP 
echo     policies, preferably from mainline branches (a la WINMAIN).
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

:IsOnARMv7
rem ARM builds not supported yet.
title ARMv7 Not Supported
cls
color 4F
echo.
echo     Windows on ARM builds are currently not supported by Morpheus.
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

:NoNoBuild_Ceiling
rem Current build is too old or new to support Redpill.
title Unsupported Windows Build
cls
color 4F
echo.
echo     Your Windows OS build is too old or too new to support being redpilled.
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

:NoNoBuild
rem Build's either from EEAP or we're running WINMAIN 8020 x86/amd64. Make the script fuck off.
title Cannot Redpill on Non-Redpillable Build
cls
color 4F
echo.
echo     You are running this script on top of a build that does 
echo     not support enabling the Windows 8 shell.
echo.
echo     Please use a Windows 8 build that isn't from the FBL_EEAP
echo     build lab or is not the x86/amd64 compile of WINMAIN 8020.
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

:TheFucksWrongWithYourPC_SPPSvcDisabled
rem Tell the user something's tampered with sppsvc.
title Unsupported System State
cls
color 4F
echo.
echo     Morpheus relies on the Windows Software Protection Platform
echo     service (sppsvc) to function. It appears to be disabled, and
echo     as such this script cannot function.
echo.
echo     Please re-enable sppsvc in the Windows registry from within a
echo     Windows PE environment before attempting to run this script.
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

:TheFucksWrongWithYourPC_NoSPPDir
rem OS is screwed. Only advice is to reinstall at this point.
title Reinstall Windows
cls
color 4F
echo.
echo     This Windows installation is missing required license files
echo     that dictate critical system functionality. You must reinstall
echo     the current OS build to regain these files.
echo.
echo     Press any key to exit.
echo.
pause > nul
color
cls
title 
goto :EOF

rem :shutdown
rem echo Restarting system...
rem shutdown /r /t 0

