program license_and_errors;
// ===========================================================================
//  LumasReport example 02 -- License info & structured errors
//  Shows how to read the reporting license entitlement (rptGetLicenseInfo ->
//  TRptLicenseInfoC) and how to inspect structured engine errors
//  (rptGetLastError -> TRptErrorInfoC), including deliberately provoking a
//  format error and nil-handle errors. Still produces a valid PDF at the end.
//
//  Exports covered: rptGetLicenseInfo, rptGetLastError, rptOpenReportA,
//                   rptRender, rptExportA, rptGetPageCount.
//  Records covered: TRptLicenseInfoC, TRptErrorInfoC.
//  Constants: RPT_FEAT_* (feature bitmask), RPT_E_FMT_* (~2xxx codes).
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  GOOD_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="LicDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="16">'#10 +
    '   <text name="t" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">License &amp; error demo</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
  // Content that is not XML at all -> RPT_E_FMT_XML (2001): the parser bails
  // because the body does not begin with a '<' element.
  NOTXML: AnsiString = 'this is not a report at all'#10;
  // Well-formed XML but the wrong root element -> RPT_E_FMT_SCHEMA (2002):
  // the compiler requires the root to be <report>.
  BADROOT: AnsiString = '<notreport><oops/></notreport>'#10;

// Human-readable name for the well-known feature bits.
function FeaturesToStr(F: UInt32): string;
begin
  Result := '';
  if (F and RPT_FEAT_CORE)        <> 0 then Result := Result + 'CORE ';
  if (F and RPT_FEAT_EXPORT_PDF)  <> 0 then Result := Result + 'PDF ';
  if (F and RPT_FEAT_EXPORT_WEB)  <> 0 then Result := Result + 'WEB ';
  if (F and RPT_FEAT_EXPORT_DATA) <> 0 then Result := Result + 'DATA ';
  if (F and RPT_FEAT_PREVIEW)     <> 0 then Result := Result + 'PREVIEW ';
  if (F and RPT_FEAT_PRINT)       <> 0 then Result := Result + 'PRINT ';
  if (F and RPT_FEAT_PLUGINS)     <> 0 then Result := Result + 'PLUGINS ';
  Result := Trim(Result);
end;

// Read the engine's current last-error code (0 if none).
function LastErrorCode(Eng: TRPT): Integer;
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) then Result := Info.Code else Result := 0;
end;

// Print + return the engine's last structured error.
procedure ShowError(const Tag: string; Eng: TRPT);
var Info: TRptErrorInfoC; Has: Boolean;
begin
  FillChar(Info, SizeOf(Info), 0);
  Has := rptGetLastError(Eng, @Info);
  if Has and (Info.Code <> 0) then
    Writeln(Format('  %s -> code %d  module=%s  location=%s  msg=%s',
      [Tag, Info.Code, string(AnsiString(Info.Module_)),
       string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]))
  else
    Writeln(Format('  %s -> (no structured error reported)', [Tag]));
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Info: TRptLicenseInfoC;
  Dir, GoodLrpt, BadLrpt, OutPdf: AnsiString;
  PrevCode: Integer;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir      := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    GoodLrpt := Dir + '02_good.lrpt';
    BadLrpt  := Dir + '02_bad.lrpt';
    OutPdf   := Dir + '02_out.pdf';

    // --- 1. License entitlement -------------------------------------------
    Writeln('== License info ==');
    FillChar(Info, SizeOf(Info), 0);
    Info.StructSize := SizeOf(Info);   // caller-set: lets the DLL version-check
    if rptGetLicenseInfo(Eng, @Info) then
    begin
      Writeln(Format('  Edition  : %d', [Info.Edition]));
      Writeln(Format('  Features : $%.8x (%s)',
        [Info.Features, FeaturesToStr(Info.Features)]));
      Writeln(Format('  LicClass : %d', [Info.LicClass]));
      Writeln(Format('  LockClass: %d', [Info.LockClass]));
      if Info.Expiry = 0 then
        Writeln('  Expiry   : 0 (perpetual / unbound)')
      else
        Writeln(Format('  Expiry   : %d', [Info.Expiry]));
      Writeln(Format('  Customer : %s', [string(AnsiString(Info.Customer))]));
    end
    else
    begin
      Writeln('  rptGetLicenseInfo failed');
      DumpRptError(Eng);
    end;

    // --- 2. Deliberate errors ---------------------------------------------
    Writeln('== Deliberate errors ==');

    // (a) not-XML content -> RPT_E_FMT_XML (2001).
    WriteText(BadLrpt, NOTXML);
    Job := rptOpenReportA(Eng, PAnsiChar(BadLrpt));
    if Job = nil then
      ShowError('open(not-XML .lrpt)', Eng)
    else
    begin
      Writeln('  open(not-XML .lrpt) -> unexpectedly succeeded');
      rptCloseReport(Job);
    end;

    // (b) well-formed XML, wrong root element -> RPT_E_FMT_SCHEMA (2002).
    WriteText(BadLrpt, BADROOT);
    Job := rptOpenReportA(Eng, PAnsiChar(BadLrpt));
    if Job = nil then
      ShowError('open(wrong-root .lrpt)', Eng)
    else
    begin
      Writeln('  open(wrong-root .lrpt) -> unexpectedly succeeded');
      rptCloseReport(Job);
    end;

    // (c) operating on a nil job handle: the call is rejected (returns False),
    //     but there is no engine bound to a nil handle, so no NEW error is
    //     recorded -- the engine's last-error code stays whatever it was.
    //     We detect that by snapshotting the code before the probe.
    PrevCode := LastErrorCode(Eng);
    if rptRender(nil) then
      Writeln('  rptRender(nil) -> unexpectedly succeeded')
    else if LastErrorCode(Eng) = PrevCode then
      Writeln(Format('  rptRender(nil) -> returned False; no new engine error (last code still %d)', [PrevCode]))
    else
      ShowError('rptRender(nil)', Eng);

    PrevCode := LastErrorCode(Eng);
    if rptExportA(nil, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
      Writeln('  rptExportA(nil) -> unexpectedly succeeded')
    else if LastErrorCode(Eng) = PrevCode then
      Writeln(Format('  rptExportA(nil) -> returned False; no new engine error (last code still %d)', [PrevCode]))
    else
      ShowError('rptExportA(nil)', Eng);

    // --- 3. Valid report so the example still produces output --------------
    Writeln('== Valid render ==');
    WriteText(GoodLrpt, GOOD_XML);
    Job := rptOpenReportA(Eng, PAnsiChar(GoodLrpt));
    if Job = nil then begin Writeln('  open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('  render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('  rendered %d page(s)', [rptGetPageCount(Job)]));
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('  export failed'); DumpRptError(Eng); Halt(4); end;
      Writeln('  wrote ' + string(OutPdf));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
