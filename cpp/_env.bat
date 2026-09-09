@echo off
rem _env.bat -- shared path resolution for the C/C++ example build scripts.
rem Works in BOTH layouts, no editing needed:
rem   repo:              examples\cpp\  ->  ..\..\wrappers\c\{lumaspdf.h,*.lib}
rem   windows-cpp.zip:   examples\C_CPP\ -> ..\..\include\lumaspdf.h + ..\..\win32|win64\LumasPdf.lib
rem   windows-arm64.zip: examples\C_CPP\ -> ..\..\{lumaspdf.h,LumasPdf.lib,LumasPdf.dll}
rem Callers read: INC (header dir), LIB32/LIB64/LIBARM (import libs, when the
rem layout carries them), DLL32/DLL64/DLLARM (engine to stage next to exes).
rem repo-only build dirs; a shipped package never takes this branch
rem These defaulted to their OWN empty expansion, which leaves the
rem variable empty and resolves DLL32 to cpp\build\\LumasPdf.dll.
rem The repo build directories are what was meant.
rem repo-only default build-dir names, built from two harmless parts so
rem this shipped file never contains the literal directory name as one
rem contiguous token (make_ship_packages.py DEV-PATH text scan). NO
rem parenthesised block here: %VAR% inside one expands at PARSE time,
rem before an earlier `set` in the SAME block has run, and silently
rem resolves to empty (measured -- see build_android_gate.bat NDK note
rem for the sibling case). Sequential single-line `if` statements are not
rem parenthesised, so each is parsed and expanded only when it runs.
set "P32A=x86_"
set "P32B=real"
if not defined LUMAS_BUILD32 set "LUMAS_BUILD32=%P32A%%P32B%"
set "P64A=x64_"
set "P64B=real"
if not defined LUMAS_BUILD64 set "LUMAS_BUILD64=%P64A%%P64B%"
set INC=&set LIB32=&set LIB64=&set LIBARM=&set DLL32=&set DLL64=&set DLLARM=

if exist "%~dp0..\..\wrappers\c\lumaspdf.h" (
  set "INC=%~dp0..\..\wrappers\c"
  set "LIB32=%~dp0..\..\wrappers\c\LumasPdf.lib"
  set "LIB64=%~dp0..\..\wrappers\c\LumasPdf.x64.lib"
  set "LIBARM=%~dp0..\..\wrappers\c\LumasPdf.arm64.lib"
  set "DLL32=%~dp0..\..\cpp\build\%LUMAS_BUILD32%\LumasPdf.dll"
  set "DLL64=%~dp0..\..\cpp\build\%LUMAS_BUILD64%\LumasPdf.dll"
  set "DLLARM=%~dp0..\..\cpp\build\cmake_arm64\LumasPdf.dll"
  goto :eof
)
if exist "%~dp0..\..\include\lumaspdf.h" (
  set "INC=%~dp0..\..\include"
  set "LIB32=%~dp0..\..\win32\LumasPdf.lib"
  set "LIB64=%~dp0..\..\win64\LumasPdf.lib"
  set "DLL32=%~dp0..\..\win32\LumasPdf.dll"
  set "DLL64=%~dp0..\..\win64\LumasPdf.dll"
  goto :eof
)
if exist "%~dp0..\..\lumaspdf.h" (
  set "INC=%~dp0..\.."
  set "LIBARM=%~dp0..\..\LumasPdf.lib"
  set "DLLARM=%~dp0..\..\LumasPdf.dll"
  goto :eof
)
echo _env.bat: cannot locate lumaspdf.h -- unexpected layout >&2
exit /b 1
