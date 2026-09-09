program northwind_preview;
// ============================================================================
//  LumasReport OO example 19 -- Build a .lrpt STEP-BY-STEP, bind it to the real
//                               Northwind.mdb, then SHOW it in the embedded viewer.
//  OO port: boots via TPDF (see _oo_shared.inc). The .lrpt is assembled one
//  labelled block at a time (STEP 1..14). Then: rptOpenReport -> rptRender ->
//  rptExport / rptPreview.
//  rptPreviewA BLOCKS until the viewer window is closed; pass --headless
//  (or --no-preview) to skip the window and only write the files (CI mode).
//  Build (64-bit -- the Access ODBC driver used here is the 64-bit one).
// ============================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

{$I _oo_shared.inc}

const
  MDB = 'E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb';

// STEP 1 + 2 -- document envelope + page geometry (millimetres).
const
  STEP_HEAD: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Northwind Catalog" tagLangVersion="1">'#10 +
    '  <page width="210" height="297" marginLeft="15" marginTop="15"'#10 +
    '        marginRight="15" marginBottom="15"/>'#10;

// STEP 3 -- DATA BINDING to Northwind.mdb (odbc, Categories INNER JOIN Products).
const
  STEP_DATA: AnsiString =
    '  <datasources>'#10 +
    '    <datasource alias="d" provider="odbc"'#10 +
    '      conn="Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=' + MDB + ';"'#10 +
    '      query="SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit,'#10 +
    '                    p.UnitPrice, p.UnitsInStock'#10 +
    '             FROM Categories c INNER JOIN Products p'#10 +
    '               ON c.CategoryID = p.CategoryID'#10 +
    '             ORDER BY c.CategoryName, p.ProductName"/>'#10 +
    '  </datasources>'#10;

// STEP 4 -- Parameters, read back in any band with {{var:Name}}.
const
  STEP_PARAMS: AnsiString =
    '  <params>'#10 +
    '    <param name="Title"   default="''Northwind Product Catalog''"/>'#10 +
    '    <param name="Company" default="''LumasPDF Trading Co.''"/>'#10 +
    '  </params>'#10;

// STEP 5 -- Named styles (00BBGGRR colours).
const
  STEP_STYLES: AnsiString =
    '  <styles>'#10 +
    '    <style name="Bar"     backColor="005F3A1F" borderWidth="0"/>'#10 +
    '    <style name="GrpBar"  backColor="002A170F" borderWidth="0"/>'#10 +
    '    <style name="Title"   fontName="Helvetica" fontSize="22" bold="1" textColor="00FFFFFF" vAlign="1"/>'#10 +
    '    <style name="Sub"     fontName="Helvetica" fontSize="9"  textColor="00FFFFFF" hAlign="2" vAlign="1"/>'#10 +
    '    <style name="ColH"    fontName="Helvetica" fontSize="8"  bold="1" textColor="00FFFFFF" vAlign="1"/>'#10 +
    '    <style name="ColHR"   fontName="Helvetica" fontSize="8"  bold="1" textColor="00FFFFFF" hAlign="2" vAlign="1"/>'#10 +
    '    <style name="Grp"     fontName="Helvetica" fontSize="12" bold="1" textColor="00FFFFFF" vAlign="1"/>'#10 +
    '    <style name="Cell"    fontName="Helvetica" fontSize="9"  textColor="002A170F" vAlign="1"/>'#10 +
    '    <style name="CellR"   fontName="Helvetica" fontSize="9"  textColor="002A170F" hAlign="2" vAlign="1"/>'#10 +
    '    <style name="Muted"   fontName="Helvetica" fontSize="8"  textColor="008B7464" vAlign="1"/>'#10 +
    '    <style name="Sub L"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="005F3A1F"/>'#10 +
    '    <style name="SubR"    fontName="Helvetica" fontSize="8.5" bold="1" textColor="005F3A1F" hAlign="2"/>'#10 +
    '    <style name="GTotL"   fontName="Helvetica" fontSize="11" bold="1" textColor="00FFFFFF"/>'#10 +
    '    <style name="GTotR"   fontName="Helvetica" fontSize="11" bold="1" textColor="00FFFFFF" hAlign="2"/>'#10 +
    '    <style name="Foot"    fontName="Helvetica" fontSize="7.5" textColor="008B7464"/>'#10 +
    '    <style name="FootR"   fontName="Helvetica" fontSize="7.5" textColor="008B7464" hAlign="2"/>'#10 +
    '  </styles>'#10 +
    '  <bands>'#10;

// STEP 7 -- reportheader (printed once at the top).
const
  STEP_REPORTHEADER: AnsiString =
    '    <band kind="reportheader" name="rh" height="26">'#10 +
    '      <shape name="hbar"  x="0" y="0" w="180" h="18" style="Bar" shape="0"/>'#10 +
    '      <text  name="ttl"   x="5"  y="1"  w="120" h="10" style="Title" wordWrap="0">{{var:Title}}</text>'#10 +
    '      <text  name="sub"   x="95" y="6"  w="80"  h="6"  style="Sub"   wordWrap="0">{{var:Company}}</text>'#10 +
    '      <text  name="asof"  x="0"  y="20" w="180" h="4"  style="Muted" wordWrap="0">Generated {{expr: FORMATDATE(''yyyy-mm-dd'', TODAY()) }} from Northwind.mdb (live ODBC)</text>'#10 +
    '    </band>'#10;

// STEP 8 -- pageheader (column captions, repeated each page).
const
  STEP_PAGEHEADER: AnsiString =
    '    <band kind="pageheader" name="ph" height="8">'#10 +
    '      <shape name="cbar" x="0" y="0" w="180" h="7" style="GrpBar" shape="0"/>'#10 +
    '      <text name="hP"  x="3"   y="1.5" w="64" h="4" style="ColH"  wordWrap="0">PRODUCT</text>'#10 +
    '      <text name="hK"  x="69"  y="1.5" w="44" h="4" style="ColH"  wordWrap="0">PACK</text>'#10 +
    '      <text name="hU"  x="114" y="1.5" w="21" h="4" style="ColHR" wordWrap="0">PRICE</text>'#10 +
    '      <text name="hS"  x="137" y="1.5" w="18" h="4" style="ColHR" wordWrap="0">STOCK</text>'#10 +
    '      <text name="hV"  x="157" y="1.5" w="20" h="4" style="ColHR" wordWrap="0">VALUE</text>'#10 +
    '    </band>'#10;

// STEP 9 -- groupheader (new group per CategoryName).
const
  STEP_GROUPHEADER: AnsiString =
    '    <band kind="groupheader" name="gh" group="d.CategoryName" height="9">'#10 +
    '      <shape name="gbar" x="0" y="1" w="180" h="7" style="GrpBar" shape="0"/>'#10 +
    '      <text  name="gname" x="4" y="1.7" w="140" h="5" style="Grp" wordWrap="0">{{expr: d.CategoryName}}</text>'#10 +
    '    </band>'#10;

// STEP 10 -- detail (data-bound band; zebra on even rows).
const
  STEP_DETAIL: AnsiString =
    '    <band kind="detail" name="det" height="6" data="d">'#10 +
    '      <shape name="zebra" x="0" y="0" w="180" h="6" shape="0" backColor="00F9F5F1" visible="RowNum % 2 = 0"/>'#10 +
    '      <text name="cP" x="3"   y="1" w="64" h="4" style="Cell"  wordWrap="0">{{ProductName}}</text>'#10 +
    '      <text name="cK" x="69"  y="1" w="44" h="4" style="Muted" wordWrap="0">{{QuantityPerUnit}}</text>'#10 +
    '      <text name="cU" x="114" y="1" w="21" h="4" style="CellR" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', UnitPrice) }}</text>'#10 +
    '      <text name="cS" x="137" y="1" w="18" h="4" style="CellR" wordWrap="0">{{UnitsInStock}}</text>'#10 +
    '      <text name="cV" x="157" y="1" w="20" h="4" style="CellR" wordWrap="0">{{expr: FORMATNUM(''#,##0'', UnitPrice*UnitsInStock) }}</text>'#10 +
    '      <line name="drow" orient="h" scope="section" vAlign="bottom" width="0.15" color="00E2D8CE"/>'#10 +
    '    </band>'#10;

// STEP 11 -- groupfooter (per-category subtotals).
const
  STEP_GROUPFOOTER: AnsiString =
    '    <band kind="groupfooter" name="gf" group="d.CategoryName" height="7">'#10 +
    '      <line name="gtop" orient="h" scope="section" vAlign="top" width="0.4" color="005F3A1F"/>'#10 +
    '      <text name="sl" x="3"   y="1.5" w="110" h="4" style="Sub L" wordWrap="0">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>'#10 +
    '      <text name="sv" x="137" y="1.5" w="40"  h="4" style="SubR"  wordWrap="0">{{expr: FORMATNUM(''#,##0'', SUM(UnitPrice*UnitsInStock)) }}</text>'#10 +
    '    </band>'#10;

// STEP 12 -- summary (grand totals over the whole dataset).
const
  STEP_SUMMARY: AnsiString =
    '    <band kind="summary" name="sm" height="16">'#10 +
    '      <shape name="tbar" x="0" y="2" w="180" h="10" style="Bar" shape="0"/>'#10 +
    '      <text name="gl" x="4"   y="4.2" w="120" h="6" style="GTotL" wordWrap="0">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>'#10 +
    '      <text name="gv" x="120" y="4.2" w="56"  h="6" style="GTotR" wordWrap="0">{{expr: FORMATNUM(''#,##0'', SUM(UnitPrice*UnitsInStock)) }}</text>'#10 +
    '    </band>'#10;

// STEP 13 -- pagefooter (page x of y, repeated).
const
  STEP_PAGEFOOTER: AnsiString =
    '    <band kind="pagefooter" name="pf" height="9">'#10 +
    '      <line name="ft" orient="h" scope="section" vAlign="top" width="0.3" color="00B9B9B9"/>'#10 +
    '      <text name="fl" x="0"   y="2.5" w="120" h="4" style="Foot"  wordWrap="0">{{var:Company}} -- confidential</text>'#10 +
    '      <text name="fr" x="120" y="2.5" w="57"  h="4" style="FootR" wordWrap="0">Page {{var:PageNo}} of {{var:TotalPages}}</text>'#10 +
    '    </band>'#10;

// STEP 14 -- close the band list and the document.
const
  STEP_TAIL: AnsiString =
    '  </bands>'#10 +
    '</report>'#10;

// Assemble the 14 steps into the full .lrpt markup, in document order.
function BuildReportXml: AnsiString;
begin
  Result :=
    STEP_HEAD + STEP_DATA + STEP_PARAMS + STEP_STYLES +
    STEP_REPORTHEADER + STEP_PAGEHEADER + STEP_GROUPHEADER + STEP_DETAIL +
    STEP_GROUPFOOTER + STEP_SUMMARY + STEP_PAGEFOOTER + STEP_TAIL;
end;

// Was --headless / --no-preview passed on the command line?
function WantHeadless: Boolean;
var i: Integer; a: string;
begin
  Result := False;
  for i := 1 to ParamCount do
  begin
    a := LowerCase(ParamStr(i));
    if (a = '--headless') or (a = '--no-preview') or (a = '/headless') then
      Exit(True);
  end;
end;

var
  Pdf: TPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Xml, Lrpt, OutPdf, OutTxt: AnsiString;
  Pages: Integer;
begin
  if not FileExists(MDB) then
  begin
    Writeln('Northwind.mdb not found: ' + MDB);
    Halt(1);
  end;
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '19_northwind.lrpt';
    OutPdf := Dir + '19_northwind.pdf';
    OutTxt := Dir + '19_northwind.txt';

    Xml := BuildReportXml;
    WriteText(Lrpt, Xml);
    Writeln(Format('STEP 1-14: wrote %s (%d bytes)', [string(Lrpt), Length(Xml)]));

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      rptSetParamStr(Job, 'Title',   'Northwind Product Catalog');
      rptSetParamStr(Job, 'Company', 'LumasPDF Trading Co.');

      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Pages := rptGetPageCount(Job);
      Writeln(Format('RENDER: %d page(s) bound from Northwind.mdb', [Pages]));

      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('pdf export failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('text export failed'); DumpRptError(Eng); Halt(5); end;
      Writeln('EXPORT: ' + string(OutPdf) + '  +  ' + string(OutTxt));

      if WantHeadless then
        Writeln('PREVIEW: skipped (--headless). Open ' + string(OutPdf) + ' to view.')
      else
      begin
        Writeln('PREVIEW: opening the embedded viewer -- close the window to continue...');
        if not rptPreviewA(Job, PAnsiChar(AnsiString('Northwind Product Catalog'))) then
        begin
          Writeln('  preview failed (continuing -- not fatal):');
          DumpRptError(Eng);
        end;
      end;
    finally
      rptCloseReport(Job);
    end;

    if FileExists(string(OutPdf)) and (Pages >= 1) then
      Writeln(Format('OK: %s exists, %d page(s).', [string(OutPdf), Pages]))
    else
      begin Writeln('VERIFY FAILED: PDF missing or zero pages'); Halt(6); end;
  finally
    rptDeleteEngine(Eng);
    Pdf.Free;
  end;
end.
