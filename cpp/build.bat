@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
rem %~dp0 is examples\cpp\, which holds repo_root.h -- 24 of the 85 examples
rem include it. Without this second -I those all die with
rem "C1083: Cannot open include file: 'repo_root.h'". build_slice.bat already
rem passed both paths; this one did not, so anything driving build.bat could
rem only ever compile the other 61.
cd /d %1
rem /std:c++17 -- build_run_linux.sh already compiles EVERY example with
rem -std=c++17, and build_mine.bat used /std:c++17 on Windows. build.bat did not,
rem so tables\images\table_images.cpp (<filesystem>) could not compile here.
rem Purely additive: no example uses anything C++17 removed.
rem user32.lib gdi32.lib -- apputil.h declares GetDC/ReleaseDC/GetDeviceCaps as
rem dllimport, but cl's default libs are kernel32-only, so the three
rem rendering_engine examples died with LNK2019. build_slice.bat already linked
rem both; build.bat did not.
cl /nologo /EHsc /std:c++17 /I "%~dp0..\..\wrappers\c" /I "%~dp0." %2 /Fe:%3 /link "%~dp0..\..\wrappers\c\LumasPdf.x64.lib" user32.lib gdi32.lib
