@echo off
rem Build + run example 2/10 of the LumasPDF XFA "flavor tour" (data binding).
rem Does NOT rebuild LumasPdf.dll -- only copies the already-built, gate-green
rem engine DLL next to this exe (Windows DLL search order checks the exe's own
rem directory first; every examples\* dir in this project follows the same
rem copy-DLL-next-to-exe convention, see e.g. cpp\tools\build_xfa_render_test.bat).
setlocal
set T=%~dp0..\..\examples\delphi\xfa\02_data_binding
cd /d %T%
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 02_data_binding.dpr || exit /b 1
echo 02_data_binding built (x64)
copy /y %~dp0..\..\LumasPdf.dll %T%\LumasPdf.dll >nul
"%T%\02_data_binding.exe"
