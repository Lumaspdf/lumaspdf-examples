// ===========================================================================
//  Shared helpers for the LumasReport Delphi examples.
//  Included by every example unit. Holds the licence hook-up + tiny utils.
//
//  THESE EXAMPLES RUN IN DEMO MODE, AND SHIP THAT WAY ON PURPOSE.
//
//  Both keys are signed by the licensing server's Ed25519 secret, which is the
//  one secret the whole scheme rests on. Anything this folder contains is in
//  every customer's hands, so a working key here is a key given away -- and an
//  unbound, full-feature, perpetual one is the product given away. There is no
//  revocation (the check is fully offline), so it could never be taken back.
//  The two constants below are therefore EMPTY, and stay empty in the shipped
//  SDK.
//
//  Empty is not a broken example: it is the engine's own trial path, and it is
//  the mode a customer evaluating the SDK is in anyway. rptCreateEngine's
//  stage 1a takes an empty reporting key as "no key was supplied at all" and
//  starts the engine in demo -- every export target works, the run is capped at
//  RPT_DEMO_MAX_PAGES (3) pages, and the host's PDF licence is deliberately
//  WITHHELD from the export engines so the visual targets carry the ordinary
//  PDF trial watermark. The data targets (CSV/JSON/XML/TEXT/XLS/XLSX) carry a
//  demo notice row instead, because a watermark cannot be drawn on a CSV.
//
//  Note the asymmetry, and do not "fix" it by putting a placeholder string in:
//  ONLY an empty key means demo. A key that IS supplied and does not verify is
//  a hard refusal, never a silent demotion -- so a customer whose key is wrong
//  is told so instead of quietly getting capped output.
// ===========================================================================

const
  // PASTE YOUR OWN KEYS HERE to run these examples fully licensed. Reporting
  // needs BOTH: it is an add-on sold on top of the PDF SDK, and rptCreateEngine
  // re-derives both entitlements from the keys themselves rather than from any
  // cached flag, so both have to be genuine signed keys.
  //   PDF_LICENSE_KEY  'LPDF2-...'  emailed with a PDF SDK purchase. Must be a
  //                                 Professional or Enterprise key: reporting
  //                                 is an add-on Starter and Lite do not sell,
  //                                 and the edition is read from the key.
  //   RPT_LICENSE_KEY  'LRPT2-...'  emailed with the LumasReport add-on.
  // Filling in only one of the two is the mismatch case and is refused by
  // design; fill in both, or leave both empty for demo.
  //
  // (Older builds shipped a 'LUMAS-<body>-<FNV1a32hex>' PDF key here. That
  // checksum format predates the Ed25519 scheme and no longer verifies, so it
  // read as no key at all -- every example died at rptCreateEngine with
  // RPT_E_LIC_PDF 1001. If you are carrying one forward, it needs re-issuing.)
  PDF_LICENSE_KEY: AnsiString = '';
  RPT_LICENSE_KEY: AnsiString = '';

// Write a UTF-8 text blob to disk (used to drop a .lrpt / .csv / .json next to
// the exe so the example is self-contained).
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

// Full lifecycle boilerplate: new PDF instance -> apply whatever keys are set
// -> create the reporting engine. Returns False (and prints the boot error) on
// failure.
//
// The setters are SKIPPED when a constant is empty rather than called with an
// empty string, so that the shipped default is "no key was ever supplied" --
// the one state stage 1a accepts as demo.
function BootEngine(out Pdf: PPDF; out Eng: TRPT): Boolean;
begin
  Result := False;
  Pdf := pdfNewPDF;
  if Pdf = nil then begin Writeln('pdfNewPDF failed'); Exit; end;
  if PDF_LICENSE_KEY <> '' then
    pdfSetLicenseKey(Pdf, PAnsiChar(PDF_LICENSE_KEY));    // stage 1: PDF SDK licence
  if RPT_LICENSE_KEY <> '' then
    rptSetRptLicenseKeyA(Pdf, PAnsiChar(RPT_LICENSE_KEY));// stage 2: reporting licence
  Eng := rptCreateEngineA(Pdf, nil);   // nil -> use the stored key
  if Eng = nil then
  begin
    Writeln('rptCreateEngine failed:');
    DumpRptError(nil);                  // nil engine -> thread boot error
    Exit;
  end;
  // Say which mode the output belongs to, so a capped, watermarked PDF is never
  // mistaken for a rendering defect.
  if RPT_LICENSE_KEY = '' then
    Writeln('[demo mode: no reporting licence set -- output is capped at 3 ' +
            'pages and watermarked. Set PDF_LICENSE_KEY + RPT_LICENSE_KEY in ' +
            '_shared.inc to run licensed.]');
  Result := True;
end;
