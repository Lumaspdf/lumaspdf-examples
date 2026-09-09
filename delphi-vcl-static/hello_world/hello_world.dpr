program hello_world;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums (fsItalic, cp1252, taCenter)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)
var
  pdf: TLumasPDFCore;
begin
  pdf := TLumasPDFCore.Create;  // static mode: DllPath ignored, engine in-process
  try
    pdf.CreateNewPDFA('');
    pdf.Append;
    pdf.SetFontA('Arial', fsItalic, 30, True, cp1252);
    pdf.WriteFTextA(taCenter, PAnsiChar('Pure VCL static build -- engine embedded, no DLL. ' + AnsiString(DateTimeToStr(Now))));
    pdf.EndPage;
    pdf.OpenOutputFileA(PAnsiChar(AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf')));
    pdf.CloseFile;
    Writeln('OK: out.pdf');
  finally
    pdf.Free;
  end;
end.
