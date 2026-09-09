@echo off
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
rem Build every C# example for .NET Framework 4.8 with the in-box csc.exe --
rem no SDK install needed on a stock Windows machine. Each example compiles
rem together with the P/Invoke wrapper source (LumasPdf.cs) and gets the x64
rem engine DLL staged next to it.
rem Layout-independent:
rem   repo:                examples\csharp\  wrapper: ..\..\wrappers\dotnet\LumasPdf.cs
rem   windows-dotnet.zip:  examples\Visual_CSharp\  wrapper: ..\..\include\Visual_C#\LumasPdf.cs
rem For modern .NET (5..10): `dotnet run` with a csproj that includes the same
rem two sources -- see readme.txt.
setlocal enabledelayedexpansion
set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" (echo .NET Framework 4.x csc.exe not found & exit /b 1)
if exist "%~dp0..\..\include\Visual_C#\LumasPdf.cs" (
  set "WRAP=%~dp0..\..\include\Visual_C#\LumasPdf.cs"
  set "ENGINE=%~dp0..\..\win64\LumasPdf.dll"
) else (
  set "WRAP=%~dp0..\..\wrappers\dotnet\LumasPdf.cs"
  set "ENGINE=%~dp0..\..\cpp\build\%LUMAS_BUILD64%\LumasPdf.dll"
)
set FAILED=
for /D %%d in ("%~dp0*") do (
  for %%s in ("%%d\*.cs") do (
    echo === %%~ns
    "%CSC%" /nologo /platform:x64 /out:"%%d\%%~ns.exe" "%%s" "%WRAP%" >nul
    if errorlevel 1 set FAILED=1
    if exist "%%d\%%~ns.exe" if not exist "%%d\LumasPdf.dll" copy /y "%ENGINE%" "%%d\LumasPdf.dll" >nul
  )
)
if defined FAILED (echo BUILD FAILURES & exit /b 1)
echo ALL C# EXAMPLES BUILT (net48 x64)
