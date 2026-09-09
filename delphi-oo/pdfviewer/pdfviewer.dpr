program pdfviewer;
// Delphi OO example -- opens 18_invoice.pdf in the SDK's EMBEDDED viewer window.
// Calls the flat export vwrShowFileW(FileName, Title). The call BLOCKS until the
// user closes the viewer window.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

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
