@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
set INC=/I "%~dp0..\..\wrappers\c" /I "%~dp0..\..\examples\cpp"
set LIB="%~dp0..\..\wrappers\c\LumasPdf.x64.lib"
set LP=/LIBPATH:"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.51.36231\lib\x64" /LIBPATH:"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64" /LIBPATH:"C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
set BASE=%~dp0..\..\examples\cpp
setlocal enabledelayedexpansion

for %%P in (
  "rendering_engine\render_page\render_page"
  "rendering_engine\render_page_ex\render_page_ex"
  "rendering_engine\render_page_to_image\render_page_to_image"
  "split_pdf\split_pdf"
  "signature_ap\signature_ap"
  "signed_pdfa\signed_pdfa"
  "text_extraction\text_extraction"
  "text_extraction3\text_extraction3"
  "text_formatting\text_formatting"
) do (
  echo ===== BUILD %%~P =====
  cl /nologo /EHsc %INC% "%BASE%\%%~P.cpp" /Fo:"%BASE%\%%~P.obj" /Fe:"%BASE%\%%~P.exe" /link %LIB% user32.lib gdi32.lib %LP%
  if errorlevel 1 ( echo FAILED %%~P ) else ( echo OK %%~P )
)
echo ALL DONE
