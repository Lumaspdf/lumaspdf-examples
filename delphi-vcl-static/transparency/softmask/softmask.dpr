program softmask;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Creates a transparency group used as a luminosity soft mask (radial shading) and
// applies it to an image.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  Lumas.Pdf.Types,              // pcTopDown, fsRegular, cp1252, es*/cs*, cbfNone, pbMediaBox, smtLuminosity, TPDFExtGState, TPDFRect
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  gs, grp, sh: Integer;
  g: TPDFExtGState;
  bbox: TPDFRect;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetUseTransparency(False);

    pdf.Append;

    pdf.SetFontA('Helvetica', fsRegular, 12.0, False, cp1252);
    pdf.WriteTextA(50.0, 50.0, 'Transparency effect with a soft mask.');

    pdf.InsertImageExA(50.0, 80.0, pdf.GetPageWidth - 100.0, 0.0, '../../../test_files/images/meadow-110719_640.jpg', 1);

    grp := pdf.BeginTransparencyGroup(0.0, 0.0, pdf.GetPageWidth, pdf.GetPageHeight, True, False, esDeviceGray, -1);
      pdf.SetColorSpace(Ord(csDeviceGray));
      sh := pdf.CreateRadialShading(400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, 1, 0);
      pdf.ApplyShading(sh);
      pdf.ComputeBBox(bbox, cbfNone);
      pdf.SetBBox(pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top);
    pdf.EndTemplate;

    pdf.InitExtGState(g);
    g.SoftMask := pdf.CreateSoftMask(Cardinal(grp), smtLuminosity, 0);
    gs := pdf.CreateExtGState(g);

    pdf.SetExtGState(Cardinal(gs));
    pdf.InsertImageExA(220.0, 80.0, 500.0, 0.0, '../../../test_files/images/tree-frog-69813_640.jpg', 1);

    pdf.InitExtGState(g);
    g.SoftMaskNone := True;
    gs := pdf.CreateExtGState(g);
    pdf.SetExtGState(Cardinal(gs));

    pdf.WriteTextA(50.0, 400.0, 'The soft mask is now deactivated.');
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
