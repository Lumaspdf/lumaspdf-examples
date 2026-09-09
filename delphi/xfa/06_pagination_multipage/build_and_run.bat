@echo off
rem Build + run example 6/10 ("Multi-Page Pagination") of the LumasPDF XFA
rem flavor tour. Links ONLY against the already-built wrappers\delphi\LumasPdf.pas
rem and the already-built LumasPdf.dll -- this script does NOT rebuild the
rem DLL (no call to tools\build_dll.bat anywhere in this file).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\06_pagination_multipage
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 06_pagination_multipage.dpr || exit /b 1
echo 06_pagination_multipage built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\06_pagination_multipage.exe"
