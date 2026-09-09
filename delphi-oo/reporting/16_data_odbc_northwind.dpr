program data_odbc_northwind;
// ===========================================================================
//  LumasReport OO example 16 -- ODBC data provider over the real Northwind.mdb
//  OO port: boots via TPDF (see _oo_shared.inc). Covers the "odbc" data
//  provider, a live DB connection + JOIN + ORDER BY, grouping, field interp.
//  Uses the 64-bit "Microsoft Access Driver (*.mdb, *.accdb)".
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

{$I _oo_shared.inc}

const
  MDB = 'E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb';

  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Northwind" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources>'#10 +
    '  <datasource alias="d" provider="odbc"'#10 +
    '    conn="Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=' + MDB + ';"'#10 +
    '    query="SELECT c.CategoryName, p.ProductName, p.UnitPrice, p.UnitsInStock ' +
             'FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ' +
             'ORDER BY c.CategoryName, p.ProductName"/>'#10 +
    ' </datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="14">'#10 +
    '   <text name="t" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center" wordWrap="0">Northwind Product Catalog</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="c1" x="0"   y="0" w="110" h="5" fontSize="9" bold="1" wordWrap="0">Product</text>'#10 +
    '   <text name="c2" x="120" y="0" w="30"  h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Price</text>'#10 +
    '   <text name="c3" x="152" y="0" w="28"  h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Stock</text>'#10 +
    '  </band>'#10 +
    '  <band kind="groupheader" name="gh" group="d.CategoryName" height="8">'#10 +
    '   <text name="g" x="0" y="1" w="180" h="6" fontSize="12" bold="1" wordWrap="0">{{expr: d.CategoryName}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="p"  x="4"   y="0" w="110" h="5" fontSize="9" wordWrap="0">{{ProductName}}</text>'#10 +
    '   <text name="pr" x="120" y="0" w="30"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', UnitPrice) }}</text>'#10 +
    '   <text name="sk" x="152" y="0" w="28"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{UnitsInStock}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="groupfooter" name="gf" group="d.CategoryName" height="4">'#10 +
    '   <text name="ge" x="4" y="0" w="176" h="4" fontSize="7" wordWrap="0">-- end of {{expr: d.CategoryName}} --</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pagefooter" name="pf" height="6">'#10 +
    '   <text name="f" x="0" y="0" w="180" h="5" fontSize="7" hAlign="right" wordWrap="0">printed {{expr: FORMATDATE(''yyyy-mm-dd'', TODAY()) }}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: TPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Lrpt, OutPdf, OutTxt: AnsiString;
begin
  if not FileExists(MDB) then begin Writeln('Northwind.mdb not found: ' + MDB); Halt(1); end;
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '16_northwind.lrpt';
    OutPdf := Dir + '16_northwind.pdf';
    OutTxt := Dir + '16_northwind.txt';
    WriteText(Lrpt, REPORT_XML);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s) from Northwind.mdb (odbc)', [rptGetPageCount(Job)]));
      if not rptExportA(Job, RPT_EXP_PDF,  PAnsiChar(OutPdf)) then begin Writeln('pdf export failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then begin Writeln('text export failed'); DumpRptError(Eng); Halt(5); end;
      Writeln('wrote ' + string(OutPdf) + '  +  ' + string(OutTxt));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    Pdf.Free;
  end;
end.
