@echo off
rem Build + run example 4/10 ("Flow Layout") of the LumasPDF XFA flavor tour.
rem Links ONLY against the already-built wrappers\delphi\LumasPdf.pas and the
rem already-built LumasPdf.dll -- this script does NOT rebuild the DLL (no
rem call to tools\build_dll.bat anywhere in this file).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\04_flow_layout
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 04_flow_layout.dpr || exit /b 1
echo 04_flow_layout built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\04_flow_layout.exe"
