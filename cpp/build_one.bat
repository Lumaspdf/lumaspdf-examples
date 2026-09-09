@echo off
REM %1 = source .cpp path, %2 = output .exe path
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
cl /nologo /EHsc /I "%~dp0..\..\wrappers\c" /I "%~dp0..\..\examples\cpp" "%~1" /Fe:"%~2" /Fo:"%~2.obj" /link "%~dp0..\..\wrappers\c\LumasPdf.x64.lib"
