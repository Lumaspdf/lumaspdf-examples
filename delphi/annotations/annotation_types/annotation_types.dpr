program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure AddHighlightAnnot(const PDF: TPDF; AnnotType: TAnnotType; Color: Cardinal; x, y: Double; const Text, Subject, Comment: String);
var w: double;
begin
   w := PDF.GetTextWidth(Text);
   PDF.WriteText(x, y, Text);
   PDF.HighlightAnnot(AnnotType, x, y + PDF.GetDescent, w, 20.0, Color, 'Test app', Subject, Comment);
end;

procedure CreateFormFields;
var a: Integer; y: double; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;

         y := 50.0;
         pdf.SetFont('Helvetica', fsRegular, 20.0, false, cp1252);
         AddHighlightAnnot(pdf, atHighlight, clYellow,  50.0, y, 'Highlight Annotation', 'Highlight Annotations', 'This is a highlight annotation');
         AddHighlightAnnot(pdf, atSquiggly,  clRed,    300.0, y, 'Squiggly Annotation',  'Highlight Annotations', 'This is a squiggly annotation');
         y := y + 30.0;
         AddHighlightAnnot(pdf, atStrikeOut, clRed,     50.0, y, 'Strikeout Annotation', 'Highlight Annotations', 'This is a strikeout annotation');
         AddHighlightAnnot(pdf, atUnderline, clRed,    300.0, y, 'Underline Annotation', 'Highlight Annotations', 'This is a underline annotation');

         y := y + 40.0;
         pdf.CircleAnnot( 50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, 'Test app', 'Circle Annotations', 'This is a circle annotation');
         pdf.SquareAnnot(300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, 'Test app', 'Square Annotations', 'This is a square annotation');

         y := y + 130.0;
         pdf.ChangeFontSize(12.0);
         pdf.WriteFTextEx(50.0, y, pdf.GetPageWidth - 100.0, -1.0, taLeft, 'The icon color of text and file attachment annotations can be changed if '
                                                                         +'necessary with SetAnnotColor(). The background color must be set.'#13#13'Text Annotations:');

         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;
         // The default icon color can be changed if necessary
         pdf.TextAnnot(50.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiComment, false);
         a := pdf.TextAnnot(100.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiHelp, false);
         pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, rgb(200, 20, 30));

         pdf.TextAnnot(150.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiInsert, false);
         a := pdf.TextAnnot(200.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiKey, false);
         pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, rgb(50, 200, 30));
         pdf.TextAnnot(250.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiNewParagraph, false);
         a := pdf.TextAnnot(300.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiNote, false);
         pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, rgb(70, 120, 210));
         pdf.TextAnnot(350.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiParagraph, false);

         y := y + 50.0;
         pdf.WriteText(50.0, y, 'File Attachment Annotations:');

         y := y + 20.0;
         pdf.FileAttachAnnot( 50.0, y, faiGraph,     'Test app', 'An example attachment', '../../../test_files/gdi.emf', true);
         pdf.FileAttachAnnot(100.0, y, faiPaperClip, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', true);
         a := pdf.FileAttachAnnot(150.0, y, faiPushPin, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', true);
         pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, rgb(70, 120, 210));
         pdf.FileAttachAnnot(200.0, y, faiTag,       'Test app', 'An example attachment', '../../../test_files/gdi.emf', true);

         y := y + 60.0;
         a := pdf.FreeTextAnnot(50.0, y, 200.0, 80.0, 'Test app', 'This is a FreeText Annotation.', taCenter);
         pdf.SetAnnotBorderWidth(a, 3.0);
         pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clGray);

         a := pdf.FreeTextAnnot(400.0, y, 150.0, 45.0, 'Test app', 'This is a FreeText Callout Annotation with a cloudy border.', taCenter);
         pdf.SetAnnotBorderWidth(a, 2.0);
         pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clRed);
         pdf.SetAnnotBorderEffect(a, beCloudy1);
         pdf.ConvToFreeTextCallout(a, 300.0, y + 40.0, 30.0, leOpenArrow);

         y := y + 120.0;
         pdf.WriteText(50.0, y, 'Line Annotations:');

         y := y + 30.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leNone,         leNone, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leButt,         leButt, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leCircle,       leCircle, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leClosedArrow,  leClosedArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leRClosedArrow, leRClosedArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leDiamond,      leDiamond, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leOpenArrow,    leOpenArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leROpenArrow,   leROpenArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leSlash,        leSlash, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
         y := y + 20.0; pdf.LineAnnot(50.0, y, 350.0, y, 1.0, leSquare,       leSquare, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');

      pdf.EndPage;
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
         if pdf.CloseFile then begin
            Writeln(Format('PDF file "%s" successfully created!', [outFile]));
            ShellExecute(0, PChar('open'), PChar(OutFile), nil, nil, SW_SHOWMAXIMIZED);
         end;
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   CreateFormFields;
end.
