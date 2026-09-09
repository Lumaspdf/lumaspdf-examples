@echo off
rem Build + run example 3/10 of the LumasPDF XFA "flavor tour" (FormCalc calculations).
rem Does NOT rebuild LumasPdf.dll -- only copies the already-built, gate-green
rem engine DLL next to this exe (Windows DLL search order checks the exe's own
rem directory first; every examples\* dir in this project follows the same
rem copy-DLL-next-to-exe convention, see e.g. cpp\tools\build_xfa_render_test.bat).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\03_formcalc_calculations
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 03_formcalc_calculations.dpr || exit /b 1
echo 03_formcalc_calculations built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\_03_formcalc_calculations.exe"
