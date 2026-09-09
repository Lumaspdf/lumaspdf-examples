program annotation_types;
// PURE VCL static example -- engine linked into this exe (LUMAS_STATIC), no LumasPdf.dll.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  clYellow = 65535;
  clRed    = 255;
  clCream  = 15793151;
  clBlack  = 0;
  clGray   = 8421504;

function RGB(r, g, b: Cardinal): Cardinal;
begin
  Result := r or (g shl 8) or (b shl 16);
end;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure AddHighlightAnnot(pdf: TLumasPDFCore; AnnotType: TAnnotType; Color: Cardinal; x, y: Double;
  const Text, Subject, Comment: PAnsiChar);
var
  w: Double;
begin
  w := pdf.GetTextWidthA(Text);
  pdf.WriteTextA(x, y, Text);
  pdf.HighlightAnnotA(AnnotType, x, y + pdf.GetDescent, w, 20.0, Color, 'Test app', Subject, Comment);
end;

var
  pdf: TLumasPDFCore;
  a: Integer;
  y: Double;
  outFile: AnsiString;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;

    y := 50.0;
    pdf.SetFontA('Helvetica', fsRegular, 20.0, False, cp1252);
    AddHighlightAnnot(pdf, atHighlight, clYellow, 50.0, y, 'Highlight Annotation', 'Highlight Annotations', 'This is a highlight annotation');
    AddHighlightAnnot(pdf, atSquiggly, clRed, 300.0, y, 'Squiggly Annotation', 'Highlight Annotations', 'This is a squiggly annotation');
    y := y + 30.0;
    AddHighlightAnnot(pdf, atStrikeOut, clRed, 50.0, y, 'Strikeout Annotation', 'Highlight Annotations', 'This is a strikeout annotation');
    AddHighlightAnnot(pdf, atUnderline, clRed, 300.0, y, 'Underline Annotation', 'Highlight Annotations', 'This is a underline annotation');

    y := y + 40.0;
    pdf.CircleAnnotA(50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, 'Test app', 'Circle Annotations', 'This is a circle annotation');
    pdf.SquareAnnotA(300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, 'Test app', 'Square Annotations', 'This is a square annotation');

    y := y + 130.0;
    pdf.ChangeFontSize(12.0);
    pdf.WriteFTextExA(50.0, y, pdf.GetPageWidth - 100.0, -1.0, Ord(taLeft),
      'The icon color of text and file attachment annotations can be changed if ' +
      'necessary with SetAnnotColor(). The background color must be set.'#13#13'Text Annotations:');

    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;
    pdf.TextAnnotA(50.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiComment, False);
    a := pdf.TextAnnotA(100.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiHelp, False);
    pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, RGB(200, 20, 30));

    pdf.TextAnnotA(150.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiInsert, False);
    a := pdf.TextAnnotA(200.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiKey, False);
    pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, RGB(50, 200, 30));
    pdf.TextAnnotA(250.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiNewParagraph, False);
    a := pdf.TextAnnotA(300.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiNote, False);
    pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, RGB(70, 120, 210));
    pdf.TextAnnotA(350.0, y, 200.0, 100.0, 'Test app', 'This is a text annotation', aiParagraph, False);

    y := y + 50.0;
    pdf.WriteTextA(50.0, y, 'File Attachment Annotations:');

    y := y + 20.0;
    pdf.FileAttachAnnotA(50.0, y, faiGraph, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', True);
    pdf.FileAttachAnnotA(100.0, y, faiPaperClip, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', True);
    a := pdf.FileAttachAnnotA(150.0, y, faiPushPin, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', True);
    pdf.SetAnnotColor(a, fcBackColor, csDeviceRGB, RGB(70, 120, 210));
    pdf.FileAttachAnnotA(200.0, y, faiTag, 'Test app', 'An example attachment', '../../../test_files/gdi.emf', True);

    y := y + 60.0;
    a := pdf.FreeTextAnnotA(50.0, y, 200.0, 80.0, 'Test app', 'This is a FreeText Annotation.', taCenter);
    pdf.SetAnnotBorderWidth(a, 3.0);
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clGray);

    a := pdf.FreeTextAnnotA(400.0, y, 150.0, 45.0, 'Test app', 'This is a FreeText Callout Annotation with a cloudy border.', taCenter);
    pdf.SetAnnotBorderWidth(a, 2.0);
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clRed);
    pdf.SetAnnotBorderEffect(a, beCloudy1);
    pdf.ConvToFreeTextCallout(a, 300.0, Single(y + 40.0), 30.0, leOpenArrow);

    y := y + 120.0;
    pdf.WriteTextA(50.0, y, 'Line Annotations:');

    y := y + 30.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leNone, leNone, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leButt, leButt, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leCircle, leCircle, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leClosedArrow, leClosedArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leRClosedArrow, leRClosedArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leDiamond, leDiamond, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leOpenArrow, leOpenArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leROpenArrow, leROpenArrow, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leSlash, leSlash, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');
    y := y + 20.0; pdf.LineAnnotA(50.0, y, 350.0, y, 1.0, leSquare, leSquare, clRed, clBlack, csDeviceRGB, 'Test app', 'Line Annotations', 'This is a line annotation');

    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      outFile := AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf');
      if not pdf.OpenOutputFileA(PAnsiChar(outFile)) then Exit;
      if pdf.CloseFile then
        Writeln('PDF file "' + string(outFile) + '" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.
