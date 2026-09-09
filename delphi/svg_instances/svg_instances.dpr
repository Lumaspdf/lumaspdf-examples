program svg_instances;

{$APPTYPE CONSOLE}

{
   svg_instances -- the 2026-08-09 SVG parser-instance API:

     pdfLoadSVGA / pdfLoadSVGW   parse an SVG file into a reusable instance
     pdfGetSVGSize               its intrinsic size (viewBox / width/height)
     pdfDeleteSVG                free an instance (dead handles do NOT get reused)
     pdfInsertSVGA               draw the SVG onto the page

   The page shows the SAME artwork placed four times, each box aspect-fitted
   from the size pdfGetSVGSize reported, plus a handle-lifecycle ledger
   proving delete + no-reuse semantics.
}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

const
   SVG_FILE = '../../test_files/lumas_logo.svg';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0;
end;

var
   pdf: TPDF;
   h1, h2, h3: Integer;
   svgW, svgH, w2, h2d: Double;
   boxW, drawW, drawH, x, y: Double;
   i: Integer;
   aliveAfterDelete: Boolean;
   outFile: String;
const
   BOXES: array[0..3] of Double = (55, 95, 140, 190);   // fits A4 width (595pt)
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      outFile := ExtractFilePath(ParamStr(0)) + 'svg_instances_out.pdf';
      pdf.CreateNewPDF(outFile);
      pdf.SetDocInfo(diTitle, 'SVG instance API demo');
      pdf.SetPageCoords(pcTopDown);

      // ---- load once, measure --------------------------------------------
      h1 := pdf.LoadSVGA(SVG_FILE);
      if h1 < 0 then
      begin
         Writeln('Input file "', SVG_FILE, '" not found or not parsable!');
         Exit;
      end;
      svgW := 0; svgH := 0;
      pdf.GetSVGSize(h1, svgW, svgH);
      Writeln(Format('handle %d: intrinsic size %.0f x %.0f', [h1, svgW, svgH]));

      pdf.Append;
         pdf.SetFont('Helvetica', fsBold, 18, true, cp1252);
         pdf.WriteText(50, 40, 'SVG instances: load once, measure, place aspect-fitted');
         pdf.SetFont('Helvetica', fsRegular, 12, true, cp1252);
         pdf.WriteText(50, 66, Format('pdfLoadSVGA -> handle %d;  pdfGetSVGSize -> %.0f x %.0f units',
            [h1, svgW, svgH]));

         // ---- four aspect-fitted placements ------------------------------
         x := 50;
         for i := 0 to High(BOXES) do
         begin
            boxW := BOXES[i];
            // aspect-fit into a boxW x boxW square from the REPORTED size
            if svgW >= svgH then
            begin drawW := boxW; drawH := boxW * svgH / svgW; end
            else
            begin drawH := boxW; drawW := boxW * svgW / svgH; end;
            y := 100 + (210 - drawH);          // bottom-aligned row
            pdf.SetLineWidth(0.5);
            pdf.SetStrokeColor(RGB(160, 160, 160));
            pdf.Rectangle(x, 100 + (210 - boxW), boxW, boxW, fmStroke);
            pdf.InsertSVGA(SVG_FILE, x, y, drawW, drawH);
            pdf.SetFillColor(RGB(0, 0, 0));
            pdf.WriteText(x, 320, Format('%.0f px', [boxW]));
            x := x + boxW + 14;
         end;

         // ---- handle lifecycle: delete + no-reuse -------------------------
         h2 := pdf.LoadSVGW(WideString(SVG_FILE));       // W variant, same file
         w2 := 0; h2d := 0;
         pdf.GetSVGSize(h2, w2, h2d);
         pdf.DeleteSVG(h2);
         aliveAfterDelete := pdf.GetSVGSize(h2, w2, h2d);
         h3 := pdf.LoadSVGA(SVG_FILE);                   // dead slot must NOT come back

         pdf.SetFont('Helvetica', fsBold, 13, true, cp1252);
         pdf.WriteText(50, 370, 'Handle lifecycle (pdfDeleteSVG, dead slots never reused):');
         pdf.SetFont('Courier', fsRegular, 11, true, cp1252);
         pdf.WriteText(50, 396, Format('pdfLoadSVGA  -> handle %d   (in use for the row above)', [h1]));
         pdf.WriteText(50, 414, Format('pdfLoadSVGW  -> handle %d   size %.0fx%.0f', [h2, w2, h2d]));
         pdf.WriteText(50, 432, Format('pdfDeleteSVG(%d); GetSVGSize(%d) afterwards -> %s',
            [h2, h2, BoolToStr(aliveAfterDelete, true)]));
         pdf.WriteText(50, 450, Format('pdfLoadSVGA  -> handle %d   (fresh handle, %d stays dead)', [h3, h2]));

         Writeln(Format('h1=%d h2=%d (deleted, alive=%s) h3=%d',
            [h1, h2, BoolToStr(aliveAfterDelete, true), h3]));

         pdf.DeleteSVG(h1);
         pdf.DeleteSVG(h3);
      pdf.EndPage;

      if pdf.CloseFile then
         Writeln('wrote ', outFile);
   finally
      pdf.Free;
   end;
end.
