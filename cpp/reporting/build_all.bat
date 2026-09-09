@echo off
setlocal
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
cd /d "%~dp0"
set INC=/I "%~dp0..\..\wrappers\c" /I "%~dp0..\..\examples\cpp"
set LUMASLIB="%~dp0..\..\wrappers\c\LumasPdf.x64.lib"
for %%F in (01_hello_report 02_license_and_errors 03_export_targets 04_bands 05_elements 06_data_csv 07_data_json_xml 08_custom_provider 09_expressions 10_aggregates_groups 11_parameters 12_custom_function 13_plugin 14_open_mem_and_print 15_tags_and_formatting 16_data_odbc_northwind 17_invoice_lines 18_invoice_pro 19_northwind_preview) do (
  echo === Building %%F ===
  cl /nologo /EHsc /MD %INC% %%F.cpp /Fe:%%F.exe /link %LUMASLIB%
  if errorlevel 1 (echo BUILD_FAILED %%F) else (echo BUILD_OK %%F)
)
echo === DONE ===
