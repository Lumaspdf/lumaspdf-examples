@echo off
rem Build every Delphi (flat LumasPdfApi) example for x86 and stage a
rem matching-bitness engine DLL next to each exe.
rem Layout-independent -- no repo paths:
rem   repo:        examples\delphi\  (engine: ..\..\x32\LumasPdf.dll)
rem   pascal.zip:  examples\Delphi\  (engine: ..\..\win32\LumasPdf.dll)
rem The LumasPdfApi unit ships INSIDE this tree (include\LumasPdfApi.pas), so no
rem external unit path is needed; dcc resolves `in '..'` against each
rem project's own folder, which is why every dpr is compiled from inside it.
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
if errorlevel 1 (echo RAD Studio not found & exit /b 1)
cd /d "%~dp0"
if exist "%~dp0..\..\win32\LumasPdf.dll" (set "ENGINE=%~dp0..\..\win32\LumasPdf.dll") else set "ENGINE=%~dp0..\..\x32\LumasPdf.dll"
if exist "%~dp0..\..\include\LumasPdf.pas" (set "UDIR=%~dp0..\..\include;%~dp0..\..\dcu32") else set "UDIR=%~dp0..\..\wrappers\delphi"
set NSLIST=Winapi;System;System.Win;Vcl;Vcl.Imaging;Vcl.Shell;Data
set FAILED=
for /R %%f in (*.dpr) do if /I "%%~xf"==".dpr" (
  echo === %%~nxf
  pushd "%%~dpf"
  dcc32 -B -Q -NS%NSLIST% -U"%UDIR%" "%%~nxf"
  if errorlevel 1 set FAILED=1
  popd
)
for /R %%e in (*.exe) do (
  copy /y "%ENGINE%" "%%~dpeLumasPdf.dll" >nul
)
if defined FAILED (echo BUILD FAILURES & exit /b 1)
echo ALL EXAMPLES BUILT (x86)
