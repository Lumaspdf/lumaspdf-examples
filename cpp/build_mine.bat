@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
set INC=/I "%~dp0..\..\wrappers\c" /I "%~dp0..\..\examples\cpp"
set LLIB=%~dp0..\..\wrappers\c\LumasPdf.x64.lib
set CF=/nologo /EHsc /std:c++17 %INC%
cd /d %~dp0..\..\examples\cpp

for %%F in (
  "tables\images\table_images"
  "tables\templates\table_templates"
  "tables\text\table_text"
  "transparency\alpha_transparency\alpha_transparency"
  "transparency\softmask\softmask"
  "zugferd_facturx_xrechnung\attach_invoice\attach_invoice"
  "zugferd_facturx_xrechnung\attach_invoice_and_conv_to_zugferd\conv_to_zugferd"
  "zugferd_facturx_xrechnung\extract_invoice\extract_invoice"
) do (
  echo === BUILD %%~F ===
  cl %CF% "%%~F.cpp" /Fe:"%%~F.exe" /Fo:"%%~F.obj" /link "%LLIB%"
  if errorlevel 1 ( echo FAILED %%~F ) else ( echo OK %%~F )
)
echo ALL DONE
