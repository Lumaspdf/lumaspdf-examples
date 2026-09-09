program open_mem_and_print;
// ===========================================================================
//  LumasReport example 14 -- In-memory open + headless print
//  Two things this example proves:
//    1. The .lrpt does NOT have to live on disk. We build the report markup as
//       an AnsiString in code and hand the raw bytes straight to the engine
//       with rptOpenReportMem(Eng, @Blob[1], Length(Blob)) -- no temp file.
//    2. A report can be sent to a physical printer head-less. We drive the
//       Windows "Microsoft Print to PDF" printer via rptPrintA and pass an
//       absolute OutputFile, which routes the spooled output to that file with
//       NO save dialog. If the printer is not installed the call fails softly:
//       we print the structured rpt error and keep going (never hard-fail).
//
//  Exports covered: rptOpenReportMem, rptRender, rptGetPageCount, rptExportA,
//                   rptPrintA  (+ rptPreviewA documented, never called).
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  // The whole report as an in-memory blob -- this string is the "file".
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="InMem" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="24">'#10 +
    '   <text name="title" x="0" y="0"  w="180" h="12" fontSize="20" hAlign="center">In-memory report</text>'#10 +
    '   <text name="sub"   x="0" y="14" w="180" h="6"  fontSize="10" hAlign="center">Opened with rptOpenReportMem -- no file on disk.</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="ph1" x="0" y="0" w="180" h="6" fontSize="9" hAlign="left">LumasReport example 14</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="8">'#10 +
    '   <text name="d1" x="0" y="0" w="180" h="6" fontSize="11" hAlign="left">This band was rendered from bytes handed to the engine directly.</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pagefooter" name="pf" height="8">'#10 +
    '   <text name="pf1" x="0" y="0" w="180" h="6" fontSize="8" hAlign="right">page {{var:PageNo}} of {{var:TotalPages}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, OutPdf, OutPrint: AnsiString;
  Pages: Integer;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir      := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    OutPdf   := Dir + '14_open_mem.pdf';
    OutPrint := Dir + '14_printed.pdf';

    // --- 1. Open straight from memory (no WriteText / no temp file) ---------
    Writeln('== Open from memory ==');
    Writeln(Format('  blob is %d bytes', [Length(REPORT_XML)]));
    Job := rptOpenReportMem(Eng, @REPORT_XML[1], Length(REPORT_XML));
    if Job = nil then
    begin
      Writeln('  rptOpenReportMem failed'); DumpRptError(Eng); Halt(2);
    end;
    try
      if not rptRender(Job) then
      begin
        Writeln('  render failed'); DumpRptError(Eng); Halt(3);
      end;
      Pages := rptGetPageCount(Job);
      Writeln(Format('  rendered %d page(s) from the in-memory report', [Pages]));

      // --- 2a. Export the in-memory report to a PDF -------------------------
      Writeln('== Export ==');
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
      begin
        Writeln('  export failed'); DumpRptError(Eng); Halt(4);
      end;
      Writeln('  wrote ' + string(OutPdf));

      // --- 2b. Headless print via "Microsoft Print to PDF" -----------------
      //  Passing an absolute OutputFile makes that printer spool to the file
      //  instead of popping a "Save As" dialog -- fully unattended. On a box
      //  without the printer this returns False; we report and carry on.
      Writeln('== Headless print ==');
      if rptPrintA(Job, PAnsiChar(AnsiString('Microsoft Print to PDF')),
                        PAnsiChar(OutPrint)) then
        Writeln('  "Microsoft Print to PDF" -> ' + string(OutPrint))
      else
      begin
        Writeln('  "Microsoft Print to PDF" not available / print failed'
              + ' (continuing -- this is not fatal):');
        DumpRptError(Eng);
      end;

      // --- 2c. Preview (documented, deliberately NOT called) ---------------
      //  rptPreviewA(Job, 'In-memory report') would pop the built-in modal
      //  viewer window. We keep this example head-less, so it stays a comment.
      //    rptPreviewA(Job, PAnsiChar(AnsiString('In-memory report')));
    finally
      rptCloseReport(Job);
    end;

    // --- 3. Verify the in-memory PDF is real ------------------------------
    Writeln('== Verify ==');
    if FileExists(string(OutPdf)) and (Pages >= 1) then
      Writeln(Format('  OK: %s exists, report has %d page(s)',
        [string(OutPdf), Pages]))
    else
    begin
      Writeln('  VERIFY FAILED: in-memory PDF missing or zero pages'); Halt(5);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
