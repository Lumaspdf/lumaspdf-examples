program invoice_pro;
// ===========================================================================
//  LumasReport PURE-VCL STATIC example 18 -- Professional FRAMED invoice
//  Static build: engine linked in (LUMAS_STATIC), NO LumasPdf.dll. A print-ready
//  invoice built from the banded model + SECTION-BOUNDED lines (scope="section"):
//  every frame line auto-spans its band. Exports PDF/HTML/SVG/TEXT + CSV/XLSX/XLS.
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
  NAVY  = '005F3A1F';
  INK   = '00222222';
  GREY  = '00808080';
  GRID  = '00B9B9B9';
  HAIR  = '00D8D8D8';
  SHADE = '00F4F1EC';
  WHITE = '00FFFFFF';

  DATA_CSV: AnsiString =
    'Item,Qty,Price'#10 +
    'Precision Widget Assembly,4,42.50'#10 +
    'Gadget Control Module,2,149.50'#10 +
    'Shielded Signal Cable (3m),10,4.75'#10 +
    'Universal Power Adapter,3,28.00'#10 +
    'Steel Mounting Bracket,12,3.25'#10 +
    'Thermal Interface Kit,5,11.20'#10;

function ColGrid(const Tag: AnsiString): AnsiString;
begin
  Result :=
    '   <line name="'+Tag+'a" orient="v" scope="section" x="0"   width="0.35" color="'+GRID+'"/>'#10 +
    '   <line name="'+Tag+'b" orient="v" scope="section" x="95"  width="0.35" color="'+GRID+'"/>'#10 +
    '   <line name="'+Tag+'c" orient="v" scope="section" x="117" width="0.35" color="'+GRID+'"/>'#10 +
    '   <line name="'+Tag+'d" orient="v" scope="section" x="149" width="0.35" color="'+GRID+'"/>'#10 +
    '   <line name="'+Tag+'e" orient="v" scope="section" x="182" width="0.35" color="'+GRID+'"/>'#10;
end;

function REPORT_XML(const Csv: AnsiString): AnsiString;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="InvoicePro" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="14" marginTop="14" marginRight="14" marginBottom="16"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + Csv + '"/></datasources>'#10 +
    ' <variables><variable name="PageNo" init="1"/></variables>'#10 +
    ' <styles>'#10 +
    '  <style name="brand"  fontName="Helvetica" fontSize="20" bold="1" textColor="'+NAVY+'"/>'#10 +
    '  <style name="addr"   fontName="Helvetica" fontSize="8"  textColor="'+GREY+'"/>'#10 +
    '  <style name="title"  fontName="Helvetica" fontSize="30" bold="1" textColor="'+NAVY+'" hAlign="right"/>'#10 +
    '  <style name="mlbl"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="'+GREY+'" hAlign="right"/>'#10 +
    '  <style name="mval"   fontName="Helvetica" fontSize="8.5" textColor="'+INK+'" hAlign="right"/>'#10 +
    '  <style name="billto" fontName="Helvetica" fontSize="8" bold="1" textColor="'+NAVY+'"/>'#10 +
    '  <style name="cust"   fontName="Helvetica" fontSize="9.5" textColor="'+INK+'"/>'#10 +
    '  <style name="colh"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="'+WHITE+'"/>'#10 +
    '  <style name="colhr"  fontName="Helvetica" fontSize="8.5" bold="1" textColor="'+WHITE+'" hAlign="right"/>'#10 +
    '  <style name="cell"   fontName="Helvetica" fontSize="9.5" textColor="'+INK+'"/>'#10 +
    '  <style name="cellr"  fontName="Helvetica" fontSize="9.5" textColor="'+INK+'" hAlign="right"/>'#10 +
    '  <style name="tlbl"   fontName="Helvetica" fontSize="9.5" bold="1" textColor="'+INK+'" hAlign="right"/>'#10 +
    '  <style name="tval"   fontName="Helvetica" fontSize="9.5" textColor="'+INK+'" hAlign="right"/>'#10 +
    '  <style name="glbl"   fontName="Helvetica" fontSize="13" bold="1" textColor="'+WHITE+'"/>'#10 +
    '  <style name="gval"   fontName="Helvetica" fontSize="13" bold="1" textColor="'+WHITE+'" hAlign="right"/>'#10 +
    '  <style name="note"   fontName="Helvetica" fontSize="8.5" textColor="'+GREY+'"/>'#10 +
    '  <style name="foot"   fontName="Helvetica" fontSize="8" textColor="'+GREY+'"/>'#10 +
    '  <style name="footr"  fontName="Helvetica" fontSize="8" textColor="'+GREY+'" hAlign="right"/>'#10 +
    ' </styles>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="42">'#10 +
    '   <text name="co"   x="0"  y="0"  w="110" h="9" style="brand" wordWrap="0">ACME Corporation</text>'#10 +
    '   <text name="a1"   x="0"  y="10" w="120" h="4" style="addr" wordWrap="0">123 Industrial Way  ·  Springfield, IL 62704</text>'#10 +
    '   <text name="a2"   x="0"  y="14" w="120" h="4" style="addr" wordWrap="0">+1 (555) 018-2245  ·  billing@acme.example</text>'#10 +
    '   <text name="ti"   x="92" y="0"  w="90"  h="13" style="title" wordWrap="0">INVOICE</text>'#10 +
    '   <text name="ml1"  x="108" y="15" w="40" h="4" style="mlbl" wordWrap="0">INVOICE #</text>'#10 +
    '   <text name="mv1"  x="150" y="15" w="32" h="4" style="mval" wordWrap="0">INV-1042</text>'#10 +
    '   <text name="ml2"  x="108" y="20" w="40" h="4" style="mlbl" wordWrap="0">ISSUE DATE</text>'#10 +
    '   <text name="mv2"  x="150" y="20" w="32" h="4" style="mval" wordWrap="0">2026-07-19</text>'#10 +
    '   <text name="ml3"  x="108" y="25" w="40" h="4" style="mlbl" wordWrap="0">DUE DATE</text>'#10 +
    '   <text name="mv3"  x="150" y="25" w="32" h="4" style="mval" wordWrap="0">2026-08-18</text>'#10 +
    '   <text name="bt"   x="0"  y="25" w="60" h="4" style="billto" wordWrap="0">BILL TO</text>'#10 +
    '   <text name="c1"   x="0"  y="29.5" w="95" h="4.5" style="cust" wordWrap="0">Globex Manufacturing Co.</text>'#10 +
    '   <text name="c2"   x="0"  y="33.5" w="95" h="4" style="addr" wordWrap="0">500 Commerce Blvd, Metropolis, NY 10001</text>'#10 +
    '   <line name="rht" orient="h" scope="section" vAlign="top"    width="0.3" color="'+HAIR+'"/>'#10 +
    '   <line name="rhb" orient="h" scope="section" vAlign="bottom" width="1.1" color="'+NAVY+'"/>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <shape name="bar" x="0" y="0" w="182" h="8" shape="0" backColor="'+NAVY+'"/>'#10 +
    '   <text name="hI" x="3"   y="2" w="88" h="5" style="colh"  wordWrap="0">DESCRIPTION</text>'#10 +
    '   <text name="hQ" x="97"  y="2" w="16" h="5" style="colhr" wordWrap="0">QTY</text>'#10 +
    '   <text name="hP" x="119" y="2" w="26" h="5" style="colhr" wordWrap="0">UNIT PRICE</text>'#10 +
    '   <text name="hA" x="151" y="2" w="29" h="5" style="colhr" wordWrap="0">AMOUNT</text>'#10 +
    ColGrid('phg') +
    ' </band>'#10 +
    '  <band kind="detail" name="det" height="7" data="d">'#10 +
    '   <shape name="zebra" x="0" y="0" w="182" h="7" shape="0" backColor="'+SHADE+'" visible="RowNum % 2 = 0"/>'#10 +
    '   <text name="dI" x="3"   y="1.6" w="90" h="4" style="cell"  wordWrap="0">{{Item}}</text>'#10 +
    '   <text name="dQ" x="97"  y="1.6" w="16" h="4" style="cellr" wordWrap="0">{{Qty}}</text>'#10 +
    '   <text name="dP" x="119" y="1.6" w="26" h="4" style="cellr" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Price)}}</text>'#10 +
    '   <text name="dA" x="151" y="1.6" w="29" h="4" style="cellr" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Qty*Price)}}</text>'#10 +
    ColGrid('dg') +
    '   <line name="drb" orient="h" scope="section" vAlign="bottom" width="0.2" color="'+HAIR+'"/>'#10 +
    '  </band>'#10 +
    '  <band kind="summary" name="sm" height="46">'#10 +
    '   <line name="stop" orient="h" scope="section" vAlign="top" width="0.6" color="'+NAVY+'"/>'#10 +
    '   <text name="nh" x="0" y="4"  w="95" h="4" style="billto" wordWrap="0">NOTES</text>'#10 +
    '   <text name="n1" x="0" y="8.5" w="100" h="4" style="note" wordWrap="0">Payment due within 30 days. Bank transfer to</text>'#10 +
    '   <text name="n2" x="0" y="12"  w="100" h="4" style="note" wordWrap="0">ACME Corp · IBAN GB00 ACME 0000 1042 · Ref INV-1042.</text>'#10 +
    '   <text name="s1l" x="100" y="4"  w="45" h="4.5" style="tlbl" wordWrap="0">Subtotal</text>'#10 +
    '   <text name="s1v" x="149" y="4"  w="31" h="4.5" style="tval" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price))}}</text>'#10 +
    '   <text name="s2l" x="100" y="9.5" w="45" h="4.5" style="tlbl" wordWrap="0">Tax (8.5%)</text>'#10 +
    '   <text name="s2v" x="149" y="9.5" w="31" h="4.5" style="tval" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*0.085)}}</text>'#10 +
    '   <shape name="gbar" x="100" y="16" w="82" h="10" shape="0" backColor="'+NAVY+'"/>'#10 +
    '   <text name="gl" x="104" y="18.5" w="40" h="6" style="glbl" wordWrap="0">TOTAL</text>'#10 +
    '   <text name="gv" x="149" y="18.5" w="29" h="6" style="gval" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*1.085)}}</text>'#10 +
    '   <text name="gc" x="100" y="28" w="82" h="4" style="footr" wordWrap="0">USD · Total items {{expr: COUNT()}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pagefooter" name="pf" height="12">'#10 +
    '   <line name="pft" orient="h" scope="section" vAlign="top" width="0.3" color="'+GRID+'"/>'#10 +
    '   <text name="ty" x="0"   y="3" w="120" h="4" style="foot"  wordWrap="0">Thank you for your business.  Questions? billing@acme.example</text>'#10 +
    '   <text name="pg" x="120" y="3" w="62"  h="4" style="footr" wordWrap="0">Page {{var:PageNo}} of {{var:TotalPages}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
end;

var
  JobC: TLumasPDFReportJobCore;

procedure ExportOne(Target: Integer; const Path: AnsiString);
begin
  if JobC.ExportA(Target, PAnsiChar(Path)) then Writeln('  wrote ', string(Path))
  else Writeln('  EXPORT FAILED: ', string(Path));
end;

var
  Pdf: TLumasPDFCore; Eng: TRPT;
  EC: TLumasPDFReportEngineCore; Job: TRPTJOB;
  Dir, Csv, Lrpt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    EC := TLumasPDFReportEngineCore.Create(Eng);
    try
      Dir := ExeDir;
      Csv := Dir + '18_items.csv'; WriteText(Csv, DATA_CSV);
      Lrpt := Dir + '18_invoice.lrpt'; WriteText(Lrpt, REPORT_XML(Csv));

      Job := EC.OpenReportA(PAnsiChar(Lrpt));
      if Job = nil then begin Writeln('open failed'); DumpRptError(Pdf, Eng); Halt(2); end;
      JobC := TLumasPDFReportJobCore.Create(Job);
      try
        if not JobC.Render then begin Writeln('render failed'); DumpRptError(Pdf, Eng); Halt(3); end;
        Writeln(Format('rendered %d page(s); exporting:', [JobC.GetPageCount]));
        ExportOne(RPT_EXP_PDF,  Dir + '18_invoice.pdf');
        ExportOne(RPT_EXP_HTML, Dir + '18_invoice.html');
        ExportOne(RPT_EXP_SVG,  Dir + '18_invoice.svg');
        ExportOne(RPT_EXP_TEXT, Dir + '18_invoice.txt');
        ExportOne(RPT_EXP_CSV,  Dir + '18_invoice.csv');
        ExportOne(RPT_EXP_XLSX, Dir + '18_invoice.xlsx');
        ExportOne(RPT_EXP_XLS,  Dir + '18_invoice.xls');
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
