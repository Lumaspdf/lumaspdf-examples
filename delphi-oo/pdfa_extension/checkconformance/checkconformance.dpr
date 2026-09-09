program checkconformance;
// Delphi OO example -- imports a PDF, converts it to PDF/A-3b via CheckConformance
// with font-not-found and ICC-replacement callbacks, then writes the result.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// Data is the PDF handle passed as UserData to CheckConformance.
function FontNotFoundProc(const Data, PDFFont: Pointer; const FontName: PAnsiChar;
  Style: TFStyle; StdFontIndex: Integer; IsSymbolFont: LongBool): Integer; stdcall;
begin
  // Replace with Arial preserving Style.
  Result := pdfReplaceFontA(PPDF(Data), PDFFont, 'Arial', Integer(Style), True);
end;

function ReplaceICCProfileProc(const Data: Pointer; ProfileType: TICCProfileType; ColorSpace: Integer): Integer; stdcall;
begin
  case ProfileType of
    ictRGB:  Result := pdfReplaceICCProfileA(PPDF(Data), Cardinal(ColorSpace), '../../../test_files/sRGB.icc');
    ictCMYK: Result := pdfReplaceICCProfileA(PPDF(Data), Cardinal(ColorSpace), '../../../test_files/ISOcoated_v2_bas.ICC');
  else
    Result := pdfReplaceICCProfileA(PPDF(Data), Cardinal(ColorSpace), '../../../test_files/gray.icc');
  end;
end;

function ConvertFile(pdf: TPDF; ConvType: Integer; const InFile, OutFile: AnsiString): Boolean;
var
  i, n, retval: Integer;
  convFlags: Cardinal;
  e: TPDFError;
begin
  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');

  case ConvType of
    Ord(ctNormalize):    convFlags := coAllowDeviceSpaces;
    Ord(ctPDFA_1b_2005): convFlags := coDefault or coFlattenLayers;
    Ord(ctPDFA_2b), Ord(ctPDFA_2u): convFlags := coDefault or coDeletePresentation;
  else
    convFlags := (coDefault or coDeletePresentation) and not coDeleteEmbeddedFiles;
  end;
  convFlags := convFlags or coCheckImages;
  convFlags := convFlags or coRepairDamagedImages;

  if ConvType <> Ord(ctNormalize) then
  begin
    pdf.SetImportFlags(ifImportAll or ifImportAsPage or ifPrepareForPDFA);
    pdf.SetImportFlags2(if2UseProxy or if2DuplicateCheck);
  end
  else
    pdf.SetImportFlags(ifImportAll or ifImportAsPage);

  retval := pdf.CheckConformance(ConvType, convFlags, pdf.Handle, @FontNotFoundProc, @ReplaceICCProfileProc);
  case retval of
    1: pdf.AddOutputIntentA('../../../test_files/sRGB.icc');
    2: pdf.AddOutputIntentA('../../../test_files/ISOcoated_v2_bas.ICC');
    3: pdf.AddOutputIntentA('../../../test_files/gray.icc');
  end;

  FillChar(e, SizeOf(e), 0);
  e.StructSize := SizeOf(e);
  n := pdf.GetErrLogMessageCount;
  for i := 0 to n - 1 do
  begin
    pdf.GetErrLogMessage(i, e);
    if e.Msg <> nil then Writeln(string(AnsiString(e.Msg)));
  end;

  if pdf.HaveOpenDoc then
  begin
    if not pdf.OpenOutputFileA(PAnsiChar(OutFile)) then Exit(False);
    Exit(pdf.CloseFile);
  end;
  Result := False;
end;

var
  pdf: TPDF;
  dir, outFile, cmap: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    cmap := dir + '..\..\..\Resource\CMap';
    pdf.SetCMapDirA(PAnsiChar(AnsiString(cmap)), lcmDelayed or lcmRecursive);
    outFile := dir + 'out.pdf';

    if ConvertFile(pdf, Ord(ctPDFA_3b), '../../../../dynapdf_help.pdf', AnsiString(outFile)) then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    pdf.Free;
  end;
end.
