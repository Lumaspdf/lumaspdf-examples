program signed_pdfa;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Creates a PDF/A-1b compatible file with a digitally-signed signature field, checks
// conformance, adds the matching output intent, then signs the file (test_cert.pfx,
// pw 123456). Mirrors examples\c\signed_pdfa\signed_pdfa.c.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first -- binds every engine entry point in-process
  System.SysUtils, Winapi.Windows,
  Lumas.Pdf.Types,              // fs*, cp1252, ta*, fc*, cs*, NO_COLOR, cmWinding, fmNoFill, ctPDFA_1b_2005
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function ErrProc(const Data: Pointer; ErrCode: Integer;
  const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

const
  Body: PAnsiChar =
    'This is a PDF/A 1b compatible PDF file that was digitally signed with ' +
    'a self sign certificate. Because PDF/A requires that all fonts are embedded it is important ' +
    'to avoid the usage of the 14 Standard fonts.'#13#13 +
    'When signing a PDF/A compliant PDF file with the default settings the font Arial must be ' +
    'available on the system because it is used to print the certificate properties into the ' +
    'signature field.'#13#13 +
    '\FC[255]Notice:\FC[0]'#13 +
    'It makes no sense to execute CheckConformance() without an error callback function. ' +
    'CheckConformance() should be used to find the right settings to create PDF/A compatible files.';

var
  pdf: TLumasPDFCore;
  sigField, sh: Integer;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.CreateNewPDFA('');           // The output file is opened later
    pdf.SetOnErrorProc(nil, @ErrProc);

    pdf.Append;
    pdf.SetFontA('Arial', fsNone, 10.0, True, cp1252);
    pdf.WriteFTextA(taLeft, Body);

    // ---------------------- Signature field appearance ----------------------
    sigField := pdf.CreateSigField('Signature', -1, 200.0, 400.0, 200.0, 80.0);
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
    pdf.WriteFTextExA(50.0, 60.0, 150.0, -1.0, Ord(taCenter), 'Digitally signed by:');
    pdf.SetFontA('Arial', fsBold or fsItalic, 18.0, True, cp1252);
    pdf.SetFillColor(RGB(100,100,200));
    pdf.WriteFTextExA(50.0, 45.0, 150.0, -1.0, Ord(taCenter), 'DynaPDF');

    pdf.EndTemplate;
    // ------------------------------------------------------------------------

    pdf.EndPage;

    case pdf.CheckConformance(Ord(ctPDFA_1b_2005), 0, nil, nil, nil) of
      1, 3: pdf.AddOutputIntentA('sRGB.icc');             // Gray, RGB
      2:    pdf.AddOutputIntentA('ISOcoated_v2_bas.ICC'); // CMYK
    end;

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
