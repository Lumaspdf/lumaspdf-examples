@echo off
rem x64 counterpart of build_examples.bat -- dcc64 + the 64-bit engine DLL.
rem
rem WHY THIS EXISTS ALONGSIDE build_examples.bat: the C#/VB.NET ports build
rem -platform:x64, and a byte-for-byte comparison against a 32-bit reference
rem would measure engine x86/x64 codegen differences, not the ports. This
rem builds the reference at the same bitness so the comparison measures what
rem it claims to.
rem Layout-independent -- no repo paths (see build_examples.bat).
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
if errorlevel 1 (echo RAD Studio not found & exit /b 1)
cd /d "%~dp0"
if exist "%~dp0..\..\win64\LumasPdf.dll" (set "ENGINE=%~dp0..\..\win64\LumasPdf.dll") else set "ENGINE=%~dp0..\..\LumasPdf.dll"
if exist "%~dp0..\..\include\LumasPdf.pas" (set "UDIR=%~dp0..\..\include;%~dp0..\..\dcu64") else set "UDIR=%~dp0..\..\wrappers\delphi"
set NSLIST=Winapi;System;System.Win;Vcl;Vcl.Imaging;Vcl.Shell;Data
set FAILED=
for /R %%f in (*.dpr) do if /I "%%~xf"==".dpr" (
  echo === %%~nxf
  pushd "%%~dpf"
  dcc64 -B -Q -NS%NSLIST% -U"%UDIR%" "%%~nxf"
  if errorlevel 1 set FAILED=1
  popd
)
for /R %%e in (*.exe) do (
  copy /y "%ENGINE%" "%%~dpeLumasPdf.dll" >nul
)
if defined FAILED (echo BUILD FAILURES & exit /b 1)
echo ALL EXAMPLES BUILT (x64)
