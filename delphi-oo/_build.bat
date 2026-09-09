@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" >nul
cd /d "%~1"
dcc64 -B -NSSystem;Winapi;System.Win "%~2"
echo EXIT=%ERRORLEVEL%
