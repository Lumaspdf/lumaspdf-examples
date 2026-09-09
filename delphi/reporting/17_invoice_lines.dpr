program invoice_lines;
// ===========================================================================
//  LumasReport example 17 -- Invoice with comprehensive LINE usage,
//  exported to MULTIPLE formats (PDF, HTML, SVG, TEXT).
//
//  Demonstrates the full ekLine surface:
//   * orientation .......... orient="h" (horizontal), "v" (vertical),
//                            "free" (explicit toX/toY -- any angle)
//   * scope ................ scope="band" (box-relative) vs "page"
//                            (full content width/height -- column separators)
//   * alignment ............ hAlign / vAlign place the rule inside its box
//                            (e.g. vAlign=bottom -> row underline;
//                             hAlign=right -> right border)
//   * dash styles .......... dash="solid|dot|dash|dashdot"
//   * double ............... double="1" -> two parallel strokes
//                            (double + dash=dot => "double dotted")
//   * stroke ............... width="mm"   (line thickness)
//   * color ................ color="00BBGGRR" (COLORREF)
//   * cap .................. cap="butt|round|square"
//  ...and ties in inline aggregates: SUM(Qty*Price) for the totals block.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  // Line items: Item, Qty, Price
  DATA_CSV: AnsiString =
    'Item,Qty,Price'#10 +
    'Widget Assembly A,2,25.00'#10 +
    'Gadget Module B,1,149.50'#10 +
    'Shielded Cable C,5,4.75'#10 +
    'Power Adapter D,3,12.00'#10 +
    'Mounting Bracket E,8,3.25'#10;

  // Colors are COLORREF $00BBGGRR (low byte = red).
  //   blue = 00CC0000 ; red = 000000CC ; midgray = 00999999 ; navy = 00703000
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

    // --- report header: title + meta + thick blue full-width rule ---
    '  <band kind="reportheader" name="rh" height="30">'#10 +
    '   <text name="co"  x="0"   y="0"  w="110" h="10" fontSize="20" bold="1" wordWrap="0">ACME Corporation</text>'#10 +
    '   <text name="ti"  x="110" y="0"  w="70"  h="10" style="h1" hAlign="right" wordWrap="0">INVOICE</text>'#10 +
    '   <text name="m1"  x="0"   y="13" w="120" h="5"  fontSize="9" wordWrap="0">Invoice #: INV-1042    Date: 2026-07-19</text>'#10 +
    '   <text name="m2"  x="110" y="13" w="70"  h="5"  fontSize="9" hAlign="right" wordWrap="0">Terms: Net 30</text>'#10 +
    // thick blue rule, page scope -> spans full content width (margin..margin)
    '   <line name="hr1" orient="h" scope="page" x="0" y="24" w="0" h="2" vAlign="middle" width="1.2" color="00CC0000"/>'#10 +
    '  </band>'#10 +

    // --- page header: column captions + underline (repeats every page) ---
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="ci" x="0"   y="0" w="78"  h="5" style="lbl" wordWrap="0">Description</text>'#10 +
    '   <text name="cq" x="80"  y="0" w="23"  h="5" style="lbl" hAlign="right" wordWrap="0">Qty</text>'#10 +
    '   <text name="cp" x="105" y="0" w="33"  h="5" style="lbl" hAlign="right" wordWrap="0">Unit Price</text>'#10 +
    '   <text name="ca" x="140" y="0" w="40"  h="5" style="lbl" hAlign="right" wordWrap="0">Amount</text>'#10 +
    // SECTION-scoped column separators (bounded to this band; stacked with the
    // detail band''s they form a continuous table grid over the rows only)
    '   <line name="phv1" orient="v" scope="section" x="79"  width="0.2" color="00909090"/>'#10 +
    '   <line name="phv2" orient="v" scope="section" x="104" width="0.2" color="00909090"/>'#10 +
    '   <line name="phv3" orient="v" scope="section" x="139" width="0.2" color="00909090"/>'#10 +
    // solid rule under the captions (band scope, full box width, bottom aligned)
    '   <line name="hr2" orient="h" x="0" y="6" w="180" h="1" vAlign="middle" width="0.5" color="00404040"/>'#10 +
    '  </band>'#10 +

    // --- detail rows: values + light dotted row underline (vAlign=bottom) ---
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="Description" x="0"   y="0" w="78"  h="5" fontSize="9" wordWrap="0">{{Item}}</text>'#10 +
    '   <text name="Qty"         x="80"  y="0" w="23"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{Qty}}</text>'#10 +
    '   <text name="UnitPrice"   x="105" y="0" w="33"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Price)}}</text>'#10 +
    '   <text name="Amount"      x="140" y="0" w="40"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Qty*Price)}}</text>'#10 +
    // section-scoped column separators (span each row -> continuous over the body)
    '   <line name="dv1" orient="v" scope="section" x="79"  width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="dv2" orient="v" scope="section" x="104" width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="dv3" orient="v" scope="section" x="139" width="0.2" color="00CCCCCC"/>'#10 +
    '   <line name="rr" orient="h" x="0" y="0" w="180" h="5.5" vAlign="bottom" dash="dot" width="0.2" color="00AAAAAA"/>'#10 +
    '  </band>'#10 +

    // --- summary: totals block with double / dotted / dashed / free lines ---
    '  <band kind="summary" name="sm" height="52">'#10 +
    // (section-scoped vertical rules are demonstrated by the table column
    //  separators phv*/dv* above -- bounded to the header/detail bands)
    '   <text name="sl1" x="115" y="1" w="30" h="5" style="lbl" wordWrap="0">Subtotal</text>'#10 +
    '   <text name="sv1" x="145" y="1" w="35" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price))}}</text>'#10 +
    '   <text name="sl2" x="115" y="7" w="30" h="5" style="lbl" wordWrap="0">Tax (10%)</text>'#10 +
    '   <text name="sv2" x="145" y="7" w="35" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*0.1)}}</text>'#10 +
    // DOUBLE line above the grand total
    '   <line name="dl" orient="h" x="115" y="14" w="65" h="1" double="1" width="0.4" color="00404040"/>'#10 +
    '   <text name="tl" x="115" y="16" w="30" h="6" style="tot" wordWrap="0">TOTAL</text>'#10 +
    '   <text name="tv" x="140" y="16" w="40" h="6" style="tot" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', SUM(Qty*Price)*1.1)}}</text>'#10 +
    // DOUBLE DOTTED accent under the total (double + dash=dot), red
    '   <line name="ac" orient="h" x="115" y="24" w="65" h="1" double="1" dash="dot" width="0.35" color="000000CC"/>'#10 +
    // DASHED signature rule + label (left side), round cap
    '   <line name="sg" orient="h" x="0" y="40" w="70" h="1" dash="dash" width="0.4" cap="round" color="00404040"/>'#10 +
    '   <text name="sgl" x="0" y="41" w="70" h="5" fontSize="8" wordWrap="0">Authorized Signature</text>'#10 +
    // PAID stamp: text + a FREE-orientation accent rule UNDERLINING it (a gentle
    // diagonal via explicit toX/toY -- still shows orient="free" without crossing
    // the word)
    '   <text name="pd" x="127" y="34" w="40" h="7" style="tot" wordWrap="0">PAID</text>'#10 +
    '   <line name="fr" orient="h" x="127" y="43" length="24" width="1.0" cap="round" color="000000CC"/>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

procedure ExportOne(Job: TRPTJOB; Target: Integer; const Path: AnsiString);
begin
  if rptExportA(Job, Target, PAnsiChar(Path)) then
    Writeln('  wrote ', string(Path))
  else
  begin
    Writeln('  EXPORT FAILED for ', string(Path));
  end;
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Csv, Lrpt, Xml: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Csv := Dir + '17_items.csv'; WriteText(Csv, DATA_CSV);

    // splice the CSV path into the report
    Xml := AnsiString(StringReplace(string(REPORT_XML), '{{CSV}}', string(Csv), []));
    Lrpt := Dir + '17_invoice.lrpt'; WriteText(Lrpt, Xml);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s); exporting to 7 formats:', [rptGetPageCount(Job)]));
      // visual formats (lines rendered natively)
      ExportOne(Job, RPT_EXP_PDF,  Dir + '17_invoice.pdf');
      ExportOne(Job, RPT_EXP_HTML, Dir + '17_invoice.html');
      ExportOne(Job, RPT_EXP_SVG,  Dir + '17_invoice.svg');
      ExportOne(Job, RPT_EXP_TEXT, Dir + '17_invoice.txt');
      // native data formats (data-true grid: header + detail rows)
      ExportOne(Job, RPT_EXP_CSV,  Dir + '17_invoice.csv');
      ExportOne(Job, RPT_EXP_XLSX, Dir + '17_invoice.xlsx');
      ExportOne(Job, RPT_EXP_XLS,  Dir + '17_invoice.xls');
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
