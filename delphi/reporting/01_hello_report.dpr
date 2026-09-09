program hello_report;
// ===========================================================================
//  LumasReport example 01 -- Hello Report
//  The minimal end-to-end flow: engine -> open .lrpt -> render -> export PDF.
//  Exports covered: rptGetVersion, rptSetRptLicenseKeyA, rptCreateEngineA,
//                   rptOpenReportA, rptRender, rptGetPageCount, rptExportA,
//                   rptCloseReport, rptDeleteEngine.
//  Tags covered: <report>, <page>, band kind "reportheader", <text>.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Hello" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="20">'#10 +
    '   <text name="title" x="0" y="0" w="180" h="10" fontSize="20" hAlign="center">Hello, LumasReport!</text>'#10 +
    '   <text name="sub"   x="0" y="12" w="180" h="6" fontSize="10" hAlign="center">The minimal engine -&gt; render -&gt; PDF flow.</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Mj, Mn, Pt: Integer; Dir, Lrpt, OutPdf: AnsiString;
begin
  Mj := 0; Mn := 0; Pt := 0;
  rptGetVersion(@Mj, @Mn, @Pt);
  Writeln(Format('LumasReport v%d.%d.%d', [Mj, Mn, Pt]));

  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '01_hello.lrpt';
    OutPdf := Dir + '01_hello.pdf';
    WriteText(Lrpt, REPORT_XML);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s)', [rptGetPageCount(Job)]));
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('export failed'); DumpRptError(Eng); Halt(4); end;
      Writeln('wrote ' + string(OutPdf));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
