@echo off
call bat\SetupSDK.bat
echo building WorkerProject
mxmlc.bat -load-config+=WorkerProject.xml +configname=air -debug=false
pause