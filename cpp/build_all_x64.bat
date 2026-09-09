@echo off
rem Build EVERY C/C++ example for x64 and stage the engine DLL next to each exe.
rem Layout-independent: paths come from _env.bat (repo or shipped package).
setlocal enabledelayedexpansion
call "%~dp0_env.bat" || exit /b 1
if not defined LIB64 (echo this layout has no x64 import library & exit /b 1)
call :find_vcvars vcvars64.bat || exit /b 1
set FAILED=
for /D %%d in ("%~dp0*") do (
  for %%s in ("%%d\*.cpp") do (
    echo === %%~ns
    pushd "%%d"
    cl /nologo /EHsc /std:c++17 /I "%INC%" /I "%~dp0." "%%~nxs" /Fe:"%%~ns.exe" /link "%LIB64%" user32.lib gdi32.lib >nul
    if errorlevel 1 set FAILED=1
    if exist "%%~ns.exe" copy /y "%DLL64%" "%%d\LumasPdf.dll" >nul
    popd
  )
)
if defined FAILED (echo BUILD FAILURES & exit /b 1)
echo ALL x64 EXAMPLES BUILT
exit /b 0

:find_vcvars
for %%r in ("%ProgramFiles%\Microsoft Visual Studio\18" "%ProgramFiles%\Microsoft Visual Studio\2022") do (
  for %%e in (Enterprise Professional Community BuildTools) do (
    if exist "%%~r\%%e\VC\Auxiliary\Build\%~1" (
      call "%%~r\%%e\VC\Auxiliary\Build\%~1" >nul
      exit /b 0
    )
  )
)
echo Visual Studio (%~1) not found -- install VS 2022+ with C++ tools >&2
exit /b 1
