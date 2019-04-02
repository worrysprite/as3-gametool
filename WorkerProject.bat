@echo off
echo building WorkerProject
call bat\SetupSDK.bat
mxmlc -load-config+=WorkerProject.xml +configname=air -debug=false
pause