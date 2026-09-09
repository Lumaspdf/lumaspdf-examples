program northwind_preview;
// ============================================================================
//  LumasReport example 19 -- Build a .lrpt STEP-BY-STEP, bind it to the real
//                            Northwind.mdb, then SHOW it in the embedded viewer.
//
//  This is the "teaching" example. Where the other examples hand you a finished
//  report, this one assembles the .lrpt one labelled block at a time so you can
//  read a report the way the engine does -- top to bottom:
//
//      STEP 1  <report>            the document envelope + tag-language version
//      STEP 2  <page>             paper size, margins (all in millimetres)
//      STEP 3  <datasources>      *** DATA BINDING *** -- the odbc link to the
//                                  Northwind.mdb (Categories INNER JOIN Products)
//      STEP 4  <params>           run-time inputs, referenced with {{var:Name}}
//      STEP 5  <styles>           named, reusable text/box styling
//      STEP 6  <bands> open       the ordered list of horizontal bands
//      STEP 7    reportheader     printed once, at the very top
//      STEP 8    pageheader       column captions, repeated on every page
//      STEP 9    groupheader      one per CategoryName -- the group break key
//      STEP 10   detail           iterates the bound rows (data="d")
//      STEP 11   groupfooter      per-category subtotals via inline SUM()/COUNT()
//      STEP 12   summary          grand totals over the whole dataset
//      STEP 13   pagefooter       page x of y, repeated on every page
//      STEP 14  </bands></report> close the document
//
//  Then the RUN section does the four things every LumasReport job does:
//      boot engine -> rptOpenReport -> rptRender -> rptExport / rptPreview.
//
//  *** EMBEDDED PREVIEW ***
//  rptPreviewA(Job, 'title') renders the job to a temporary PDF and opens it in
//  the SDK's built-in viewer window (vwrShowFile). The call BLOCKS until you
//  close that window, so by default we pop it. Pass --headless (or --no-preview)
//  to skip the window and only write the files -- that is how CI runs this.
//
//  Preview needs the RPT_FEAT_PREVIEW licence bit. Demo mode (the shipped
//  default -- no keys in _shared.inc) grants every feature bit and limits the
//  run by the 3-page cap instead, so preview is enabled there too.
//
//  Build (64-bit -- the Access ODBC driver used here is the 64-bit one):
//      call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
//      dcc64 -B 19_northwind_preview.dpr
//  Copy LumasPdf.dll next to the .exe, then:
//      19_northwind_preview.exe              (renders, writes files, POPS viewer)
//      19_northwind_preview.exe --headless   (renders + writes files, no window)
// ============================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  // The live Access database we bind to. Categories 1--n each own many Products.
  MDB = 'E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb';

// ----------------------------------------------------------------------------
//  STEP 1 + 2 -- The document envelope and the page geometry.
//  * tagLangVersion="1" pins the {{ }} interpolation grammar.
//  * Everything positional in a .lrpt is in MILLIMETRES. A4 is 210 x 297; with
//    15 mm margins all round the printable content width is 180 mm -- every x/w
//    below lives inside that 0..180 band.
// ----------------------------------------------------------------------------
const
  STEP_HEAD: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Northwind Catalog" tagLangVersion="1">'#10 +
    '  <page width="210" height="297" marginLeft="15" marginTop="15"'#10 +
    '        marginRight="15" marginBottom="15"/>'#10;

// ----------------------------------------------------------------------------
//  STEP 3 -- *** DATA BINDING to Northwind.mdb ***
//  A <datasource> gives the engine an alias + a provider + how to reach the data.
//    alias="d"        the handle the bands use: data="d" and {{d.Field}}
//    provider="odbc"  read through an ODBC driver (others: csv/json/xml/custom)
//    conn="..."       a standard ODBC connection string. We name the 64-bit
//                     "Microsoft Access Driver (*.mdb, *.accdb)" and point Dbq
//                     at the .mdb file.
//    query="..."      the SELECT the engine executes once, up front. We JOIN
//                     Categories to Products and ORDER BY category then product
//                     so the group break (STEP 9) sees rows already grouped.
//  The SELECTed column names (CategoryName, ProductName, ...) become the field
//  names you interpolate as {{ProductName}} inside the detail band.
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
//  STEP 4 -- Parameters. Values supplied at run time (see rptSetParamStr in the
//  RUN section) and read back in any band with {{var:Name}}. A default lets the
//  report render stand-alone if the host never sets it.
// ----------------------------------------------------------------------------
const
  STEP_PARAMS: AnsiString =
    '  <params>'#10 +
    '    <param name="Title"   default="''Northwind Product Catalog''"/>'#10 +
    '    <param name="Company" default="''LumasPDF Trading Co.''"/>'#10 +
    '  </params>'#10;

// ----------------------------------------------------------------------------
//  STEP 5 -- Named styles. Define font / colour / alignment once, reference by
//  name from any element (style="Cell"). Colours are 00BBGGRR hex. Keeping the
//  look here (not on every element) is what makes the bands below readable.
// ----------------------------------------------------------------------------
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
    '  <bands>'#10;                              // STEP 6: open the band list

// ----------------------------------------------------------------------------
//  STEP 7 -- reportheader: printed ONCE at the very top of the report. Holds the
//  brand bar, the parameterised title ({{var:Title}}), and the company subtitle.
// ----------------------------------------------------------------------------
const
  STEP_REPORTHEADER: AnsiString =
    '    <band kind="reportheader" name="rh" height="26">'#10 +
    '      <shape name="hbar"  x="0" y="0" w="180" h="18" style="Bar" shape="0"/>'#10 +
    '      <text  name="ttl"   x="5"  y="1"  w="120" h="10" style="Title" wordWrap="0">{{var:Title}}</text>'#10 +
    '      <text  name="sub"   x="95" y="6"  w="80"  h="6"  style="Sub"   wordWrap="0">{{var:Company}}</text>'#10 +
    '      <text  name="asof"  x="0"  y="20" w="180" h="4"  style="Muted" wordWrap="0">Generated {{expr: FORMATDATE(''yyyy-mm-dd'', TODAY()) }} from Northwind.mdb (live ODBC)</text>'#10 +
    '    </band>'#10;

// ----------------------------------------------------------------------------
//  STEP 8 -- pageheader: the column captions. A pageheader repeats at the top of
//  EVERY page, so the grid stays labelled when the product list flows over. The
//  x/w here line up with the detail cells in STEP 10.
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
//  STEP 9 -- groupheader: opens a new group every time d.CategoryName changes.
//  group="d.CategoryName" is the break key -- because the query is ORDER BY
//  CategoryName, each distinct category produces exactly one header band, whose
//  {{expr: d.CategoryName}} prints the current category name.
// ----------------------------------------------------------------------------
const
  STEP_GROUPHEADER: AnsiString =
    '    <band kind="groupheader" name="gh" group="d.CategoryName" height="9">'#10 +
    '      <shape name="gbar" x="0" y="1" w="180" h="7" style="GrpBar" shape="0"/>'#10 +
    '      <text  name="gname" x="4" y="1.7" w="140" h="5" style="Grp" wordWrap="0">{{expr: d.CategoryName}}</text>'#10 +
    '    </band>'#10;

// ----------------------------------------------------------------------------
//  STEP 10 -- detail: THE data-bound band. data="d" makes the engine emit this
//  band once per row of datasource "d". Bare {{Field}} pulls the current row's
//  column; {{expr: ...}} runs the expression language (FORMATNUM formats a
//  number; UnitPrice*UnitsInStock is the per-line stock value). The zebra shape
//  is drawn only on even rows via visible="RowNum % 2 = 0".
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
//  STEP 11 -- groupfooter: closes each category. Aggregates in a GROUP FOOTER
//  are scoped to the current group, so SUM/COUNT here are PER-CATEGORY subtotals:
//    COUNT()                      products in this category
//    SUM(UnitPrice*UnitsInStock)  stock value of this category
// ----------------------------------------------------------------------------
const
  STEP_GROUPFOOTER: AnsiString =
    '    <band kind="groupfooter" name="gf" group="d.CategoryName" height="7">'#10 +
    '      <line name="gtop" orient="h" scope="section" vAlign="top" width="0.4" color="005F3A1F"/>'#10 +
    '      <text name="sl" x="3"   y="1.5" w="110" h="4" style="Sub L" wordWrap="0">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>'#10 +
    '      <text name="sv" x="137" y="1.5" w="40"  h="4" style="SubR"  wordWrap="0">{{expr: FORMATNUM(''#,##0'', SUM(UnitPrice*UnitsInStock)) }}</text>'#10 +
    '    </band>'#10;

// ----------------------------------------------------------------------------
//  STEP 12 -- summary: printed ONCE at the end. Aggregates in the SUMMARY band
//  span the WHOLE dataset -> grand totals across every category.
// ----------------------------------------------------------------------------
const
  STEP_SUMMARY: AnsiString =
    '    <band kind="summary" name="sm" height="16">'#10 +
    '      <shape name="tbar" x="0" y="2" w="180" h="10" style="Bar" shape="0"/>'#10 +
    '      <text name="gl" x="4"   y="4.2" w="120" h="6" style="GTotL" wordWrap="0">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>'#10 +
    '      <text name="gv" x="120" y="4.2" w="56"  h="6" style="GTotR" wordWrap="0">{{expr: FORMATNUM(''#,##0'', SUM(UnitPrice*UnitsInStock)) }}</text>'#10 +
    '    </band>'#10;

// ----------------------------------------------------------------------------
//  STEP 13 -- pagefooter: repeats at the bottom of every page. Page numbering is
//  via the built-in {{var:PageNo}} / {{var:TotalPages}} variables (there is no
//  PAGENUMBER() function).
// ----------------------------------------------------------------------------
const
  STEP_PAGEFOOTER: AnsiString =
    '    <band kind="pagefooter" name="pf" height="9">'#10 +
    '      <line name="ft" orient="h" scope="section" vAlign="top" width="0.3" color="00B9B9B9"/>'#10 +
    '      <text name="fl" x="0"   y="2.5" w="120" h="4" style="Foot"  wordWrap="0">{{var:Company}} -- confidential</text>'#10 +
    '      <text name="fr" x="120" y="2.5" w="57"  h="4" style="FootR" wordWrap="0">Page {{var:PageNo}} of {{var:TotalPages}}</text>'#10 +
    '    </band>'#10;

// ----------------------------------------------------------------------------
//  STEP 14 -- close the band list and the document.
// ----------------------------------------------------------------------------
const
  STEP_TAIL: AnsiString =
    '  </bands>'#10 +
    '</report>'#10;

// Assemble the 14 steps into the full .lrpt markup, in document order.
function BuildReportXml: AnsiString;
begin
  Result :=
    STEP_HEAD +          // 1 + 2  <report> + <page>
    STEP_DATA +          // 3      <datasources> -> Northwind.mdb
    STEP_PARAMS +        // 4      <params>
    STEP_STYLES +        // 5 + 6  <styles> + open <bands>
    STEP_REPORTHEADER +  // 7
    STEP_PAGEHEADER +    // 8
    STEP_GROUPHEADER +   // 9
    STEP_DETAIL +        // 10
    STEP_GROUPFOOTER +   // 11
    STEP_SUMMARY +       // 12
    STEP_PAGEFOOTER +    // 13
    STEP_TAIL;           // 14     close </bands></report>
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

// ============================================================================
//  RUN -- boot the engine, write the .lrpt, open + render, export, then preview.
// ============================================================================
var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Xml, Lrpt, OutPdf, OutTxt: AnsiString;
  Pages: Integer;
begin
  if not FileExists(MDB) then
  begin
    Writeln('Northwind.mdb not found: ' + MDB);
    Halt(1);
  end;
  if not BootEngine(Pdf, Eng) then Halt(1);   // _shared.inc: PDF+RPT licence -> engine
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '19_northwind.lrpt';
    OutPdf := Dir + '19_northwind.pdf';
    OutTxt := Dir + '19_northwind.txt';

    // -- Emit the assembled .lrpt to disk so you can open and study it --------
    Xml := BuildReportXml;
    WriteText(Lrpt, Xml);
    Writeln(Format('STEP 1-14: wrote %s (%d bytes)', [string(Lrpt), Length(Xml)]));

    // -- Open the report file. Returns a job handle (nil on parse/schema error).
    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      // -- Supply the run-time parameters read as {{var:Title}}/{{var:Company}}.
      rptSetParamStr(Job, 'Title',   'Northwind Product Catalog');
      rptSetParamStr(Job, 'Company', 'LumasPDF Trading Co.');

      // -- Render: run the query, break groups, lay out every band into pages.
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Pages := rptGetPageCount(Job);
      Writeln(Format('RENDER: %d page(s) bound from Northwind.mdb', [Pages]));

      // -- Export the paginated result to PDF + a plain-text proof.
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('pdf export failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('text export failed'); DumpRptError(Eng); Halt(5); end;
      Writeln('EXPORT: ' + string(OutPdf) + '  +  ' + string(OutTxt));

      // -- *** EMBEDDED PREVIEW *** -----------------------------------------
      //  rptPreviewA renders the job to a temp PDF and opens the SDK's built-in
      //  viewer window; the call BLOCKS until the window is closed. Skipped when
      //  --headless is passed so this example can also run unattended.
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

    // -- Headless sanity check.
    if FileExists(string(OutPdf)) and (Pages >= 1) then
      Writeln(Format('OK: %s exists, %d page(s).', [string(OutPdf), Pages]))
    else
      begin Writeln('VERIFY FAILED: PDF missing or zero pages'); Halt(6); end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
