@echo off
rem Build + run example 9/10 ("AcroForm Widget Synthesis") of the LumasPDF
rem XFA flavor tour. Links ONLY against the already-built wrappers\delphi\
rem LumasPdf.pas and the already-built LumasPdf.dll -- this script does NOT
rem rebuild the DLL (no call to tools\build_dll.bat anywhere in this file).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\09_acroform_widget_synthesis
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 09_acroform_widget_synthesis.dpr || exit /b 1
echo 09_acroform_widget_synthesis built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\09_acroform_widget_synthesis.exe"
