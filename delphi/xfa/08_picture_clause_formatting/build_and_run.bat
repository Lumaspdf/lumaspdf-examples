@echo off
rem Build + run example 8/10 ("Picture-Clause Formatting") of the LumasPDF XFA
rem flavor tour. Links ONLY against the already-built wrappers\delphi\LumasPdf.pas
rem and the already-built LumasPdf.dll -- this script does NOT rebuild the DLL
rem (no call to tools\build_dll.bat anywhere in this file).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\08_picture_clause_formatting
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 08_picture_clause_formatting.dpr || exit /b 1
echo 08_picture_clause_formatting built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\08_picture_clause_formatting.exe"
