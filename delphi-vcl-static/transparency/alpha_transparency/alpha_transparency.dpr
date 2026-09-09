program alpha_transparency;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
// extended graphics states.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  Lumas.Pdf.Types,              // pcTopDown, fsRegular, cp1252, fmFill, TPDFExtGState
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

const
  clWhite = Cardinal($FFFFFF);
  clBlack = Cardinal($0);

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  gs, img: Integer;
  g: TPDFExtGState;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetUseTransparency(False);

    pdf.Append;

    pdf.SetFontA('Helvetica', fsRegular, 12.0, False, cp1252);
    pdf.WriteTextA(50.0, 50.0, 'Fill Alpha = 0.5');

    pdf.Rectangle(50.0, 70.0, 110.0, 160.0, Ord(fmFill));
    pdf.SetFillColor(clWhite);
    pdf.WriteTextA(55.0, 75.0, 'Background');

    pdf.InitExtGState(g);
    g.FillAlpha := 0.5;
    gs := pdf.CreateExtGState(g);
    pdf.SetExtGState(Cardinal(gs));

    img := pdf.InsertImageExA(60.0, 84.0, 200.0, 0.0, '../../../test_files/images/tree-frog-69813_640.jpg', 0);

    g.FillAlpha := 1.0;
    gs := pdf.CreateExtGState(g);
    pdf.SetExtGState(Cardinal(gs));

    pdf.SetFillColor(clBlack);
    pdf.WriteTextA(340.0, 50.0, 'Fill Alpha = 1.0 (default)');
    pdf.Rectangle(340.0, 70.0, 110.0, 160.0, Ord(fmFill));
    pdf.SetFillColor(clWhite);
    pdf.WriteTextA(345.0, 75.0, 'Background');
    pdf.PlaceImage(img, 350.0, 84.0, 200.0, 0.0);

    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA('out.pdf') then Exit;
      if pdf.CloseFile then Writeln('PDF file "out.pdf" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.
