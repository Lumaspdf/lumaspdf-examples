program signature_ap;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Builds a page with a digitally-signed signature field whose appearance
// template is drawn with normal PDF functions, then signs the file with a
// self-signed certificate.
{$APPTYPE CONSOLE}
uses
  System.SysUtils, Winapi.Windows,
  LumasPdf,
  LumasPdfOO;

function ErrProc(const Data: Pointer; ErrCode: Integer;
  const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;   // try to continue if an error occurs
end;

const
  Body: PAnsiChar =
    'This file is digitally signed with a self sign certificate. ' +
    'The appearance of the signature field is created with normal DynaPDF functions. However, it ' +
    'would also be possible to import a PDF page, an EMF file, or an image into the ' +
    'appearance template.'#10#10 +
    'When creating an individual signature appearance make sure to place the validation icon ' +
    'properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon ' +
    'depends on the Acrobat version with which the file is opened. However, the unscaled size ' +
    'of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want ' +
    'but it is usually best to preserve the aspect ratio and the icon must be placed fully ' +
    'inside the appearance template.';

var
  pdf: TPDF;
  sigField, sh: Integer;
begin
  pdf := TPDF.Create;
  try
    pdf.CreateNewPDFA('');           // The output file is opened later
    pdf.SetOnErrorProc(nil, @ErrProc);

    pdf.Append;
    pdf.SetFontA('Arial', fsNone, 14.0, True, cp1252);
    pdf.WriteFTextA(taLeft, Body);

    // ---------------------- Signature field appearance ----------------------
    sigField := pdf.CreateSigField('Signature', -1, 200.0, 500.0, 200.0, 80.0);
    pdf.SetFieldColor(sigField, Ord(fcBorderColor), Ord(csDeviceRGB), NO_COLOR);
    pdf.PlaceSigFieldValidateIcon(sigField, 0.0, 15.0, 50.0, 50.0);
    pdf.CreateSigFieldAP(sigField);

    pdf.SaveGraphicState;
    pdf.Rectangle(0.0, 0.0, 200.0, 80.0, Ord(fmNoFill));
    pdf.ClipPath(cmWinding, fmNoFill);
    sh := pdf.CreateAxialShading(0.0, 0.0, 200.0, 0.0, 0.5, RGB(120,120,220), RGB(255,255,255), 1, 1);
    pdf.ApplyShading(sh);
    pdf.RestoreGraphicState;

    pdf.SaveGraphicState;
    pdf.Ellipse(50.5, 1.0, 148.5, 78.0, Ord(fmNoFill));
    pdf.ClipPath(cmWinding, fmNoFill);
    sh := pdf.CreateAxialShading(0.0, 0.0, 0.0, 78.0, 2.0, RGB(255,255,255), RGB(120,120,220), 1, 1);
    pdf.ApplyShading(sh);
    pdf.RestoreGraphicState;

    pdf.SetFontA('Arial', fsBold or fsUnderlined, 11.0, True, cp1252);
    pdf.SetFillColor(RGB(120,120,220));
    pdf.WriteFTextExA(50.0, 60.0, 150.0, -1.0, Integer(taCenter), 'Digitally signed by:');
    pdf.SetFontA('Arial', fsBold or fsItalic, 18.0, True, cp1252);
    pdf.SetFillColor(RGB(100,100,200));
    pdf.WriteFTextExA(50.0, 45.0, 150.0, -1.0, Integer(taCenter), 'DynaPDF');

    pdf.EndTemplate;                 // Close the appearance template.
    // ------------------------------------------------------------------------

    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA('out.pdf') then
      begin
        pdf.Free;
        Halt(1);
      end;
    end;
    if pdf.CloseAndSignFile('test_cert.pfx', '123456', 'Test', '') then
      Writeln('PDF file "out.pdf" successfully created!');
  finally
    pdf.Free;
  end;
end.
