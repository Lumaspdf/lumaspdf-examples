@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
cd /d "%~1"
cl /nologo /I "%~dp0..\..\wrappers\c" "%~2" /Fe:"%~3" /link "%~dp0..\..\wrappers\c\LumasPdf.x64.lib"
