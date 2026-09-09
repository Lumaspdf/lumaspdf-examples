@echo off
REM Builds all 10 XFA "flavor tour" C++ examples. Mirrors the top-level
REM examples\cpp\build_mine.bat convention: cl against wrappers\c\lumaspdf.h,
REM linked to wrappers\c\LumasPdf.x64.lib (x64, matching every other
REM examples\cpp\* program in this project -- LumasPdf.dll is copied into
REM each example folder already, dropped-in at project-setup time).
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
set INC=/I "%~dp0..\..\wrappers\c" /I "%~dp0..\..\examples\cpp"
set LLIB=%~dp0..\..\wrappers\c\LumasPdf.x64.lib
set CF=/nologo /EHsc /std:c++17 %INC%
cd /d %~dp0..\..\examples\cpp\xfa

for %%F in (
  "01_basic_positioned_form\01_basic_positioned_form"
  "02_data_binding\02_data_binding"
  "03_formcalc_calculations\03_formcalc_calculations"
  "04_flow_layout\04_flow_layout"
  "05_occur_repeating_rows\05_occur_repeating_rows"
  "06_pagination_multipage\06_pagination_multipage"
  "07_table_layout\07_table_layout"
  "08_picture_clause_formatting\08_picture_clause_formatting"
  "09_acroform_widget_synthesis\09_acroform_widget_synthesis"
  "10_javascript_scripting\10_javascript_scripting"
) do (
  echo === BUILD %%~F ===
  cl %CF% "%%~F.cpp" /Fe:"%%~F.exe" /Fo:"%%~F.obj" /link "%LLIB%"
  if errorlevel 1 ( echo FAILED %%~F ) else ( echo OK %%~F )
)
echo ALL DONE
