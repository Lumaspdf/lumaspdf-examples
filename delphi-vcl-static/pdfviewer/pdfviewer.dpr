program pdfviewer;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Opens 18_invoice.pdf in the SDK's EMBEDDED viewer via the flat export vwrShowFileW.
// The call BLOCKS until the user closes the viewer window (8s-timeout run = PASS).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Wrap.Imports;       // flat vwrShowFileW proc pointer (bound in static mode)

var
  path: string;
  title: WideString;
  ok: LongBool;
begin
  path := ExtractFilePath(ParamStr(0)) + '18_invoice.pdf';
  title := '18_invoice.pdf - LumasPDF embedded preview';
  Writeln('Opening embedded viewer for: ' + path);
  ok := vwrShowFileW(PWideChar(WideString(path)), PWideChar(title));
  if not ok then
  begin
    Writeln('The embedded viewer could not be shown for: ' + path);
    Halt(1);
  end;
end.
