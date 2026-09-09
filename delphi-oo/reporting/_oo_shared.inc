// ===========================================================================
//  Shared helpers for the LumasReport Delphi *OO* examples.
//  Included by every reporting OO example. Same demo licence keys as the flat
//  delphi\reporting examples, but boots through the OO TPDF class instead of the
//  flat pdfNewPDF/pdfSetLicenseKey calls. The reporting surface itself is the
//  flat rpt* externals (they live in the LumasPdf unit and take a PPDF/TRPT).
// ===========================================================================
const
  PDF_DEMO_KEY: AnsiString = 'LUMAS-LumasReportExamples-DD5D40E0';
  RPT_DEMO_KEY: AnsiString =
    'LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM' +
    '.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA';

// Write a UTF-8 text blob to disk (drops a .lrpt / .csv / .json next to the exe).
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
procedure DumpRptError(Eng: TRPT);
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) and (Info.Code <> 0) then
    Writeln(Format('  ! rpt error %d [%s] at %s: %s',
      [Info.Code, string(AnsiString(Info.Module_)),
       string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]));
end;

// OO lifecycle boilerplate: new TPDF instance -> store demo keys -> create the
// reporting engine (via the OO methods). Returns False (and prints) on failure.
function BootEngine(out Pdf: TPDF; out Eng: TRPT): Boolean;
begin
  Result := False;
  Pdf := TPDF.Create;                                   // = pdfNewPDF
  if Pdf.Handle = nil then begin Writeln('pdfNewPDF failed'); Exit; end;
  Pdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));           // stage 1: PDF SDK licence
  Pdf.SetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));       // stage 2: reporting licence
  Eng := Pdf.CreateEngineA(nil);                        // nil -> use the stored key
  if Eng = nil then
  begin
    Writeln('rptCreateEngine failed:');
    DumpRptError(nil);
    Exit;
  end;
  Result := True;
end;
