@echo off
cd /d "%~dp0"
set D=%~dp0
for %%F in (01_hello_report 02_license_and_errors 03_export_targets 04_bands 05_elements 06_data_csv 07_data_json_xml 08_custom_provider 09_expressions 10_aggregates_groups 11_parameters 12_custom_function 13_plugin 14_open_mem_and_print 15_tags_and_formatting 16_data_odbc_northwind 17_invoice_lines 18_invoice_pro) do (
  echo ===RUN %%F===
  call "%D%%%F.exe"
  echo ===EXIT %%F=%errorlevel%===
)
echo ===RUN 19_northwind_preview===
call "%D%19_northwind_preview.exe" --headless
echo ===EXIT 19=%errorlevel%===
echo ===SMOKE DONE===
