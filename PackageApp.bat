@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

::set AIR_TARGET=-native
::set AIR_TARGET=-captive-runtime
set OPTIONS=-target native
call bat\Packager.bat

pause