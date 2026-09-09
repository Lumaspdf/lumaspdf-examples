program bands;
// ===========================================================================
//  LumasReport example 04 -- Every band kind
//  A grouped, multi-page report that instantiates all nine band kinds, each
//  labelled with the band it represents:
//    background, overlay, reportheader, pageheader, groupheader, detail,
//    groupfooter, pagefooter, summary.
//  Bound to a generated CSV with a group column so grouping fires and the
//  report spans several pages.
//
//  Exports covered: rptOpenReportA, rptRender, rptGetPageCount, rptExportA.
//  Tags covered: full TRptBandKind vocabulary + group="d.grp".
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

// Build a CSV: 3 groups x 30 rows => 90 detail rows (spans multiple pages).
function BuildCsv: AnsiString;
var SB: TStringBuilder; G, R: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('grp,item,val'#10);
    for G := 1 to 3 do
      for R := 1 to 30 do
        SB.Append(Format('Group-%d,Item %d-%.2d,%d'#10, [G, G, R, G * 100 + R]));
    Result := AnsiString(SB.ToString);
  finally
    SB.Free;
  end;
end;

function BuildReportXml(const CsvPath: AnsiString): AnsiString;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="BandsDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + CsvPath + '"/></datasources>'#10 +
    ' <styles>'#10 +
    '  <style name="Wm"  fontSize="48" bold="1" textColor="00EEEEEE" hAlign="1" vAlign="1"/>'#10 +
    '  <style name="Ov"  fontSize="8"  textColor="00B0B0B0" hAlign="2"/>'#10 +
    '  <style name="Grp" fontSize="12" bold="1" textColor="00FFFFFF" backColor="002A6099" vAlign="1"/>'#10 +
    ' </styles>'#10 +
    ' <bands>'#10 +
    // (1) background - behind every page
    '  <band kind="background" name="bg" height="297">'#10 +
    '   <text name="wm" x="20" y="120" w="150" h="40" style="Wm" rotation="45" wordWrap="0">BACKGROUND</text>'#10 +
    '  </band>'#10 +
    // (2) overlay - on top of every page
    '  <band kind="overlay" name="ov" height="297">'#10 +
    '   <text name="ol" x="0" y="150" w="180" h="6" style="Ov" rotation="90" wordWrap="0">overlay band</text>'#10 +
    '  </band>'#10 +
    // (3) reportheader - once at the start
    '  <band kind="reportheader" name="rh" height="16">'#10 +
    '   <text name="rt" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">reportheader band</text>'#10 +
    '  </band>'#10 +
    // (4) pageheader - top of every page
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="pt" x="0" y="0" w="180" h="6" fontSize="9" wordWrap="0">pageheader band - grp / item / val</text>'#10 +
    '  </band>'#10 +
    // (5) groupheader - once per grp value
    '  <band kind="groupheader" name="gh" group="d.grp" height="8">'#10 +
    '   <text name="gt" x="0" y="0" w="180" h="7" style="Grp" wordWrap="0">groupheader band: {{d.grp}}</text>'#10 +
    '  </band>'#10 +
    // (6) detail - once per row
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="di" x="4"   y="0" w="120" h="5" fontSize="9" wordWrap="0">detail band: {{d.item}}</text>'#10 +
    '   <text name="dv" x="130" y="0" w="46"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.val}}</text>'#10 +
    '  </band>'#10 +
    // (7) groupfooter - once per grp value
    '  <band kind="groupfooter" name="gf" group="d.grp" height="7">'#10 +
    '   <text name="ft" x="0" y="1" w="180" h="5" fontSize="9" italic="1" wordWrap="0">groupfooter band: end of {{d.grp}}</text>'#10 +
    '  </band>'#10 +
    // (8) pagefooter - bottom of every page
    '  <band kind="pagefooter" name="pf" height="7">'#10 +
    '   <text name="pft" x="0" y="1" w="180" h="5" fontSize="8" hAlign="center" wordWrap="0">pagefooter band</text>'#10 +
    '  </band>'#10 +
    // (9) summary - once at the very end
    '  <band kind="summary" name="sm" height="16">'#10 +
    '   <text name="st" x="0" y="2" w="180" h="10" fontSize="14" hAlign="center">summary band - report complete</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Csv, Lrpt, OutPdf: AnsiString;
  Pages: Integer;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Csv    := Dir + '04_data.csv';
    Lrpt   := Dir + '04_report.lrpt';
    OutPdf := Dir + '04_out.pdf';
    WriteText(Csv, BuildCsv);
    WriteText(Lrpt, BuildReportXml(Csv));

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Pages := rptGetPageCount(Job);
      Writeln(Format('rendered %d page(s)', [Pages]));
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('export failed'); DumpRptError(Eng); Halt(4); end;
      Writeln('wrote ' + string(OutPdf));
      if Pages < 2 then
        begin Writeln(Format('FAIL: expected >= 2 pages, got %d', [Pages])); Halt(5); end;
      Writeln('OK: multi-page grouped report with all band kinds');
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
