program invoice_lines;
// ===========================================================================
//  LumasReport PURE-VCL STATIC example 17 -- Invoice with comprehensive LINE
//  usage, exported to MULTIPLE formats (PDF, HTML, SVG, TEXT, CSV, XLSX, XLS).
//  Static build: engine linked in (LUMAS_STATIC), NO LumasPdf.dll. Demonstrates
//  the full ekLine surface (orientation / scope / alignment / dash / double /
//  stroke / colour / cap) + inline aggregates SUM(Qty*Price).
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils, System.Classes,
  Lumas.Rpt.Types,
  Lumas.Rpt.Errors,
  Lumas.Pdf.Wrap.Core,
  Lumas.Pdf.Wrap.Classes;

{$I _vcl_static_shared.inc}

const
  DATA_CSV: AnsiString =
    'Item,Qty,Price'#10 +
    'Widget Assembly A,2,25.00'#10 +
    'Gadget Module B,1,149.50'#10 +
    'Shielded Cable C,5,4.75'#10 +
    'Power Adapter D,3,12.00'#10 +
    'Mounting Bracket E,8,3.25'#10;

  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Invoice" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="{{CSV}}"/></datasources>'#10 +
    ' <styles>'#10 +
    '  <style name="h1" fontName="Helvetica" fontSize="22" bold="1"/>'#10 +
    '  <style name="lbl" fontName="Helvetica" fontSize="9" bold="1"/>'#10 +
    '  <style name="tot" fontName="Helvetica" fontSize="12" bold="1"/>'#10 +
    ' </styles>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="30">'#10 +
    '   <text name="co"  x="0"   y="0"  w="110" h="10" fontSize="20" bold="1" wordWrap="0">ACME Corporation</text>'#10 +
    '   <text name="ti"  x="110" y="0"  w="70"  h="10" style="h1" hAlign="right" wordWrap="0">INVOICE</text>'#10 +
    '   <text name="m1"  x="0"   y="13" w="120" h="5"  fontSize="9" wordWrap="0">Invoice #: INV-1042    Date: 2026-07-19</text>'#10 +
    '   <text name="m2"  x="110" y="13" w="70"  h="5"  fontSize="9" hAlign="right" wordWrap="0">Terms: Net 30</text>'#10 +
    '   <line name="hr1" orient="h" scope="page" x="0" y="24" w="0" h="2" vAlign="middle" width="1.2" color="00CC0000"/>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="ci" x="0"   y="0" w="78"  h="5" style="lbl" wordWrap="0">Description</text>'#10 +
    '   <text name="cq" x="80"  y="0" w="23"  h="5" style="lbl" hAlign="right" wordWrap="0">Qty</text>'#10 +
    '   <text name="cp" x="105" y="0" w="33"  h="5" style="lbl" hAlign="right" wordWrap="0">Unit Price</text>'#10 +
    '   <text name="ca" x="140" y="0" w="40"  h="5" style="lbl" hAlign="right" wordWrap="0">Amount</text>'#10 +
    '   <line name="phv1" orient="v" scope="section" x="79"  width="0.2" color="00909090"/>'#10 +
    '   <line name="phv2" orient="v" scope="section" x="104" width="0.2" color="00909090"/>'#10 +
    '   <line name="phv3" orient="v" scope="section" x="139" width="0.2" color="00909090"/>'#10 +
    '   <line name="hr2" orient="h" x="0" y="6" w="180" h="1" vAlign="middle" width="0.5" color="00404040"/>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="Description" x="0"   y="0" w="78"  h="5" fontSize="9" wordWrap="0">{{Item}}</text>'#10 +
    '   <text name="Qty"         x="80"  y="0" w="23"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{Qty}}</text>'#10 +
    '   <text name="UnitPrice"   x="105" y="0" w="33"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Price)}}</text>'#10 +
    '   <text name="Amount"      x="140" y="0" w="40"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Qty*Price)}}</text>'#10 +
    '   <line name="dv1" orient="v" scope="section" x="79"  width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="dv2" orient="v" scope="section" x="104" width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="dv3" orient="v" scope="section" x="139" width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="rr" orient="h" x="0" y="0" w="180" h="5.5" vAlign="bottom" dash="dot" width="0.2" color="00AAAAAA"/>'#10 +
    '  </band>'#10 +
    '  <band kind="summary" name="sm" height="52">'#10 +
    '   <text name="sl1" x="115" y="1" w="30" h="5" style="lbl" wordWrap="0">Subtotal</text>'#10 +
    '   <text name="sv1" x="145" y="1" w="35" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price))}}</text>'#10 +
    '   <text name="sl2" x="115" y="7" w="30" h="5" style="lbl" wordWrap="0">Tax (10%)</text>'#10 +
    '   <text name="sv2" x="145" y="7" w="35" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*0.1)}}</text>'#10 +
    '   <line name="dl" orient="h" x="115" y="14" w="65" h="1" double="1" width="0.4" color="00404040"/>'#10 +
    '   <text name="tl" x="115" y="16" w="30" h="6" style="tot" wordWrap="0">TOTAL</text>'#10 +
    '   <text name="tv" x="140" y="16" w="40" h="6" style="tot" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*1.1)}}</text>'#10 +
    '   <line name="ac" orient="h" x="115" y="24" w="65" h="1" double="1" dash="dot" width="0.35" color="000000CC"/>'#10 +
    '   <line name="sg" orient="h" x="0" y="40" w="70" h="1" dash="dash" width="0.4" cap="round" color="00404040"/>'#10 +
    '   <text name="sgl" x="0" y="41" w="70" h="5" fontSize="8" wordWrap="0">Authorized Signature</text>'#10 +
    '   <text name="pd" x="127" y="34" w="40" h="7" style="tot" wordWrap="0">PAID</text>'#10 +
    '   <line name="fr" orient="h" x="127" y="43" length="24" width="1.0" cap="round" color="000000CC"/>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  JobC: TLumasPDFReportJobCore;

procedure ExportOne(Target: Integer; const Path: AnsiString);
begin
  if JobC.ExportA(Target, PAnsiChar(Path)) then
    Writeln('  wrote ', string(Path))
  else
    Writeln('  EXPORT FAILED for ', string(Path));
end;

var
  Pdf: TLumasPDFCore; Eng: TRPT;
  EC: TLumasPDFReportEngineCore; Job: TRPTJOB;
  Dir, Csv, Lrpt, Xml: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    EC := TLumasPDFReportEngineCore.Create(Eng);
    try
      Dir := ExeDir;
      Csv := Dir + '17_items.csv'; WriteText(Csv, DATA_CSV);

      Xml := AnsiString(StringReplace(string(REPORT_XML), '{{CSV}}', string(Csv), []));
      Lrpt := Dir + '17_invoice.lrpt'; WriteText(Lrpt, Xml);

      Job := EC.OpenReportA(PAnsiChar(Lrpt));
      if Job = nil then begin Writeln('open failed'); DumpRptError(Pdf, Eng); Halt(2); end;
      JobC := TLumasPDFReportJobCore.Create(Job);
      try
        if not JobC.Render then begin Writeln('render failed'); DumpRptError(Pdf, Eng); Halt(3); end;
        Writeln(Format('rendered %d page(s); exporting to 7 formats:', [JobC.GetPageCount]));
        ExportOne(RPT_EXP_PDF,  Dir + '17_invoice.pdf');
        ExportOne(RPT_EXP_HTML, Dir + '17_invoice.html');
        ExportOne(RPT_EXP_SVG,  Dir + '17_invoice.svg');
        ExportOne(RPT_EXP_TEXT, Dir + '17_invoice.txt');
        ExportOne(RPT_EXP_CSV,  Dir + '17_invoice.csv');
        ExportOne(RPT_EXP_XLSX, Dir + '17_invoice.xlsx');
        ExportOne(RPT_EXP_XLS,  Dir + '17_invoice.xls');
        JobC.CloseReport;
      finally
        JobC.Free;
      end;
    finally
      EC.DeleteEngine;
      EC.Free;
    end;
  finally
    Pdf.Free;
  end;
end.
