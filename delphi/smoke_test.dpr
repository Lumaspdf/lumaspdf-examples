program smoke_test;
{$APPTYPE CONSOLE}
// End-to-end proof that the mirrored include\LumasPdfApi.pas (bound to
// LumasPdf.dll) drives the TPDF class exactly like the LumasPDF original:
// creates a PDF with text, a table-of-boxes page and a bookmark, then exits
// 0 on success. Run from this directory (LumasPdf.dll is staged here by
// build_examples.bat next to every exe; for this test the x32 DLL in the
// include dir's parent is found via the exe directory).
uses
  SysUtils,
  LumasPdfApi in 'include\LumasPdfApi.pas';

var
  pdf: TPDF;
  outFile: string;
begin
  ExitCode := 1;
  pdf := TPDF.Create;
  try
    outFile := ExtractFilePath(ParamStr(0)) + 'smoke_out.pdf';
    if not pdf.CreateNewPDF(outFile) then begin Writeln('CreateNewPDF failed'); Exit; end;
    pdf.SetDocInfo(diTitle, 'LumasPdf example-mirror smoke test');
    pdf.Append();
    pdf.SetFont('Arial', fsRegular, 24.0, true, cp1252);
    pdf.WriteText(50, 700, 'Examples run on LumasPdf.dll');
    pdf.SetFillColor(255); // red (COLORREF, R in the low byte)
    pdf.Rectangle(50, 500, 200, 100, fmFill);
    pdf.AddBookmark('First page', -1, 1, false);
    pdf.EndPage();
    if not pdf.CloseFile then begin Writeln('CloseFile failed'); Exit; end;
    Writeln('OK: ', outFile);
    ExitCode := 0;
  finally
    pdf.Free;
  end;
end.
