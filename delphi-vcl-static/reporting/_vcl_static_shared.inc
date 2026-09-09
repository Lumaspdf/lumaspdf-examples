// ===========================================================================
//  Shared helpers for the PURE-VCL STATIC LumasReport examples.
//  The whole engine (src, src\rpt, besen) is linked INTO the exe via
//  LUMAS_STATIC (runtime packages OFF) -> single self-contained exe, NO
//  LumasPdf.dll at run time. Boots through TLumasPDFCore (in-process instance)
//  and drives reports via the report CORE classes (TLumasPDFReportEngineCore /
//  TLumasPDFReportJobCore), exactly as wrappers\vcl\Examples\ReportDemoMain.pas.
//  Enums / consts / records come from the ENGINE units (Lumas.Rpt.Types,
//  Lumas.Rpt.Errors), never from the DLL-binding LumasPdf unit.
// ===========================================================================
const
  PDF_DEMO_KEY: AnsiString = 'LUMAS-LumasReportExamples-DD5D40E0';
  RPT_DEMO_KEY: AnsiString =
    'LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM' +
    '.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA';

// The exe's own directory (outputs land next to the exe regardless of cwd).
function ExeDir: AnsiString;
begin
  Result := AnsiString(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))));
end;

// Write a UTF-8 text blob to disk (drops a .lrpt / .csv next to the exe).
procedure WriteText(const Path, Content: AnsiString);
var FS: TFileStream;
begin
  FS := TFileStream.Create(string(Path), fmCreate);
  try
    if Content <> '' then FS.WriteBuffer(Content[1], Length(Content));
  finally
    FS.Free;
  end;
end;

// Print the engine's last structured error (code / module / location / message).
procedure DumpRptError(Pdf: TLumasPDFCore; Eng: TRPT);
var Info: TRptErrorInfoC;
begin
  if Pdf = nil then Exit;
  FillChar(Info, SizeOf(Info), 0);
  if Pdf.RptGetLastError(Eng, @Info) and (Info.Code <> 0) then
    Writeln(Format('  ! rpt error %d [%s] at %s: %s',
      [Info.Code, string(AnsiString(Info.Module_)),
       string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]));
end;

// STATIC lifecycle boilerplate: new TLumasPDFCore (engine in-process) -> store
// demo keys -> create the reporting engine. Returns False (and prints) on fail.
function BootEngine(out Pdf: TLumasPDFCore; out Eng: TRPT): Boolean;
begin
  Result := False;
  Eng := nil;
  Pdf := TLumasPDFCore.Create;                        // static: DllPath ignored
  Pdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));          // stage 1: PDF SDK licence
  Pdf.RptSetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));   // stage 2: reporting licence
  Eng := Pdf.RptCreateEngineA(nil);                    // nil -> use the stored key
  if Eng = nil then
  begin
    Writeln('rptCreateEngine failed:');
    DumpRptError(Pdf, nil);
    Exit;
  end;
  Result := True;
end;
