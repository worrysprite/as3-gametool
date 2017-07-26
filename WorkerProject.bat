@echo off
echo Éú³ÉWorkerProject
call bat\SetupSDK.bat
mxmlc -load-config+=WorkerProject.xml +configname=air -debug=false
pause