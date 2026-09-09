@echo off
rem Build every Delphi OO (TPDF class) example for x86.
rem The LumasPdf/LumasPdfOO units come from -U so the SAME sources build in
rem both layouts:
rem   repo:        ..\..\wrappers\delphi\
rem   pascal.zip:  ..\..\include\   (with prebuilt units in ..\..\dcu32\)
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
if errorlevel 1 (echo RAD Studio not found & exit /b 1)
cd /d "%~dp0"
if exist "%~dp0..\..\include\LumasPdf.pas" (
  set "UDIR=%~dp0..\..\include;%~dp0..\..\dcu32"
  set "ENGINE=%~dp0..\..\win32\LumasPdf.dll"
) else (
  set "UDIR=%~dp0..\..\wrappers\delphi"
  set "ENGINE=%~dp0..\..\x32\LumasPdf.dll"
)
set FAILED=
for /R %%f in (*.dpr) do if /I "%%~xf"==".dpr" (
  echo === %%~nxf
  pushd "%%~dpf"
  dcc32 -B -Q -NSSystem;Winapi;System.Win -U"%UDIR%" "%%~nxf"
  if errorlevel 1 set FAILED=1
  popd
)
for /R %%e in (*.exe) do (
  copy /y "%ENGINE%" "%%~dpeLumasPdf.dll" >nul
)
if defined FAILED (echo BUILD FAILURES & exit /b 1)
echo ALL OO EXAMPLES BUILT (x86)
