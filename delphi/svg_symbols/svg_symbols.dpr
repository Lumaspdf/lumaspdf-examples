program svg_symbols;

{$APPTYPE CONSOLE}

{
   svg_symbols -- the 2026-08-09 SVG parser-instance API, buffer + symbols:

     pdfLoadSVGFromBuffer     parse SVG straight from memory
     pdfGetSVGSymbolCount     number of <symbol id="..."> definitions
     pdfGetSVGSymbolNameA     name lookup (TPDF.GetSVGSymbolName wraps the
                              C-level two-step: NULL-buffer size query first,
                              then a fetch into a length+1 buffer)
     pdfInsertSVGEx           draw the same buffer onto the page
     pdfDeleteSVG             free the instance

   The page renders a symbol catalog (index, name, name length, plus an
   out-of-range probe showing the error contract), then the artwork itself
   via pdfInsertSVGEx.
}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0;
end;

// Same artwork as ../../test_files/lumas_symbols.svg, embedded so the whole
// example runs from ONE self-contained buffer (no file I/O).
const SVG_SRC: AnsiString =
   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 120" width="320" height="120">' + sLineBreak +
   '  <symbol id="marker_star">' + sLineBreak +
   '    <polygon points="20,2 25,14 38,14 28,22 32,36 20,28 8,36 12,22 2,14 15,14" fill="#ffb300"/>' + sLineBreak +
   '  </symbol>' + sLineBreak +
   '  <symbol id="marker_dot">' + sLineBreak +
   '    <circle cx="20" cy="20" r="14" fill="#43a047"/>' + sLineBreak +
   '  </symbol>' + sLineBreak +
   '  <symbol id="marker_flag">' + sLineBreak +
   '    <polygon points="6,2 34,10 6,18" fill="#e53935"/>' + sLineBreak +
   '    <rect x="4" y="2" width="4" height="36" fill="#6d4c41"/>' + sLineBreak +
   '  </symbol>' + sLineBreak +
   '  <symbol id="marker_wave">' + sLineBreak +
   '    <path d="M 2 20 C 10 6 18 34 26 20 C 30 13 34 20 38 16" fill="none" stroke="#1e88e5" stroke-width="4"/>' + sLineBreak +
   '  </symbol>' + sLineBreak +
   '  <rect x="0" y="0" width="320" height="120" fill="#f4f6f8"/>' + sLineBreak +
   '  <polygon points="40,22 47,40 66,40 51,52 57,72 40,60 23,72 29,52 14,40 33,40" fill="#ffb300"/>' + sLineBreak +
   '  <circle cx="120" cy="46" r="24" fill="#43a047"/>' + sLineBreak +
   '  <polygon points="182,20 226,34 182,48" fill="#e53935"/>' + sLineBreak +
   '  <rect x="178" y="20" width="6" height="58" fill="#6d4c41"/>' + sLineBreak +
   '  <path d="M 250 46 C 262 22 274 70 286 46 C 292 35 298 46 306 40" fill="none" stroke="#1e88e5" stroke-width="6"/>' + sLineBreak +
   '  <line x1="14" y1="92" x2="306" y2="92" stroke="#90a4ae" stroke-width="2"/>' + sLineBreak +
   '</svg>';

var
   pdf: TPDF;
   h, cnt, i: Integer;
   name, oob: AnsiString;
   y: Double;
   outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      outFile := ExtractFilePath(ParamStr(0)) + 'svg_symbols_out.pdf';
      pdf.CreateNewPDF(outFile);
      pdf.SetDocInfo(diTitle, 'SVG symbol catalog demo');
      pdf.SetPageCoords(pcTopDown);

      h := pdf.LoadSVGFromBuffer(PAnsiChar(SVG_SRC), Length(SVG_SRC));
      if h < 0 then
      begin
         Writeln('LoadSVGFromBuffer failed!');
         Exit;
      end;
      cnt := pdf.GetSVGSymbolCount(h);
      Writeln('handle ', h, ': ', cnt, ' symbols');

      pdf.Append;
         pdf.SetFont('Helvetica', fsBold, 18, true, cp1252);
         pdf.WriteText(50, 40, 'SVG symbol catalog from a memory buffer');
         pdf.SetFont('Helvetica', fsRegular, 12, true, cp1252);
         pdf.WriteText(50, 66, Format('pdfLoadSVGFromBuffer -> handle %d;  pdfGetSVGSymbolCount -> %d',
            [h, cnt]));

         // ---- catalog table ----------------------------------------------
         pdf.SetFont('Courier', fsBold, 11, true, cp1252);
         pdf.WriteText(50,  100, 'idx  symbol name             length');
         pdf.SetFont('Courier', fsRegular, 11, true, cp1252);
         y := 120;
         for i := 0 to cnt - 1 do
         begin
            // GetSVGSymbolName wraps pdfGetSVGSymbolNameA's two-step contract:
            // NULL-buffer size query first, then a fetch into a len+1 buffer.
            name := pdf.GetSVGSymbolName(h, i);
            pdf.WriteText(50, y, Format('%3d  %-22s  %6d', [i, string(name), Length(name)]));
            Writeln(Format('%d: %s (len %d)', [i, string(name), Length(name)]));
            y := y + 18;
         end;
         // out-of-range probe: index cnt does not exist -> empty result (-1
         // at the C level), no exception
         oob := pdf.GetSVGSymbolName(h, cnt);
         pdf.WriteText(50, y, Format('%3d  <out of range>          -> "%s" (empty)', [cnt, string(oob)]));
         y := y + 18;

         // ---- the artwork itself, from the SAME buffer --------------------
         pdf.SetFont('Helvetica', fsRegular, 12, true, cp1252);
         pdf.WriteText(50, y + 24, 'pdfInsertSVGEx renders the same buffer (preview row of the 4 symbols):');
         pdf.InsertSVGFromBuffer(PAnsiChar(SVG_SRC), Length(SVG_SRC), 50, y + 44, 400, 150);

         pdf.DeleteSVG(h);
      pdf.EndPage;

      if pdf.CloseFile then
         Writeln('wrote ', outFile);
   finally
      pdf.Free;
   end;
end.
