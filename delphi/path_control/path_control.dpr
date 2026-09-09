program path_control;

{$APPTYPE CONSOLE}

{
   path_control -- the 2026-08-09 path-construction control API:

     pdfHaveOpenPath()  is a path currently under construction?
     pdfAbortPath()     drop the open path WITHOUT painting it

   Three panels on one page:
     1. a normal path finished with ClosePath(fmFillStroke)
     2. the SAME path built again, then AbortPath -> the canvas stays clean
     3. a HaveOpenPath-guarded finisher: paints when a path is open,
        silently skips when none is (no error 20 raised)
}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

// The demo path: a diamond with an inner notch, interesting enough to
// visibly disappear in panel 2.
procedure BuildDemoPath(pdf: TPDF; X, Y: Double);
begin
   pdf.MoveTo(X + 70,  Y);
   pdf.LineTo(X + 140, Y + 60);
   pdf.LineTo(X + 105, Y + 60);
   pdf.LineTo(X + 70,  Y + 30);
   pdf.LineTo(X + 35,  Y + 60);
   pdf.LineTo(X,       Y + 60);
end;

// Panel 3's point: finish a path ONLY if one is open. Without the guard the
// second call would raise error 20 (no open path).
procedure FinishIfOpen(pdf: TPDF; const What: String);
begin
   if pdf.HaveOpenPath then
   begin
      pdf.ClosePath(fmFillStroke);
      Writeln(What, ': path was open -> painted');
   end
   else
      Writeln(What, ': no open path -> skipped (no error raised)');
end;

var
   pdf: TPDF;
   f: Integer;
   stateBefore, stateAfter: Boolean;
   outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      outFile := ExtractFilePath(ParamStr(0)) + 'path_control_out.pdf';
      pdf.CreateNewPDF(outFile);
      pdf.SetDocInfo(diTitle, 'AbortPath / HaveOpenPath demo');
      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         f := pdf.SetFont('Helvetica', fsBold, 18, true, cp1252);
         pdf.WriteText(50, 40, 'Path construction control: pdfHaveOpenPath + pdfAbortPath');

         pdf.SetFont('Helvetica', fsRegular, 12, true, cp1252);

         // ---- panel 1: normal finish --------------------------------------
         pdf.WriteText(50, 90, '1. Path built, then ClosePath(fmFillStroke) - the path paints:');
         pdf.SetLineWidth(2.0);
         pdf.SetStrokeColor(RGB(30, 58, 95));
         pdf.SetFillColor(RGB(255, 211, 77));
         BuildDemoPath(pdf, 120, 115);
         stateBefore := pdf.HaveOpenPath;
         pdf.ClosePath(fmFillStroke);
         stateAfter := pdf.HaveOpenPath;
         pdf.SetFillColor(RGB(0, 0, 0));
         pdf.WriteText(320, 140, Format('HaveOpenPath before: %s', [BoolToStr(stateBefore, true)]));
         pdf.WriteText(320, 158, Format('HaveOpenPath after:  %s', [BoolToStr(stateAfter, true)]));
         Writeln('panel 1: before=', stateBefore, ' after=', stateAfter);

         // ---- panel 2: AbortPath ------------------------------------------
         pdf.WriteText(50, 230, '2. The SAME path built again, then AbortPath - nothing paints:');
         pdf.SetFillColor(RGB(216, 67, 21));
         BuildDemoPath(pdf, 120, 255);
         stateBefore := pdf.HaveOpenPath;
         pdf.AbortPath;                       // <- drop it, paint nothing
         stateAfter := pdf.HaveOpenPath;
         pdf.SetFillColor(RGB(0, 0, 0));
         pdf.WriteText(320, 280, Format('HaveOpenPath before: %s', [BoolToStr(stateBefore, true)]));
         pdf.WriteText(320, 298, Format('HaveOpenPath after:  %s (path dropped)', [BoolToStr(stateAfter, true)]));
         // a light frame showing WHERE the aborted path would have painted
         pdf.SetLineWidth(0.5);
         pdf.SetStrokeColor(RGB(160, 160, 160));
         pdf.Rectangle(115, 250, 150, 72, fmStroke);
         pdf.WriteText(122, 285, '(stays empty)');
         Writeln('panel 2: before=', stateBefore, ' after=', stateAfter);

         // ---- panel 3: guarded finish -------------------------------------
         pdf.WriteText(50, 370, '3. HaveOpenPath-guarded finisher - safe to call with or without a path:');
         pdf.SetLineWidth(2.0);
         pdf.SetStrokeColor(RGB(30, 58, 95));
         pdf.SetFillColor(RGB(67, 160, 71));
         BuildDemoPath(pdf, 120, 395);
         FinishIfOpen(pdf, 'call #1 (path open)');      // paints
         FinishIfOpen(pdf, 'call #2 (nothing open)');   // skips, no error 20
         pdf.SetFillColor(RGB(0, 0, 0));
         pdf.WriteText(320, 420, 'call #1: path open -> painted');
         pdf.WriteText(320, 438, 'call #2: nothing open -> skipped, no error');
      pdf.EndPage;

      if pdf.CloseFile then
      begin
         Writeln('wrote ', outFile);
         // ShellExecute(0, 'open', PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   finally
      pdf.Free;
   end;
end.
