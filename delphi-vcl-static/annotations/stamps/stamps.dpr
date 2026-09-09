program stamps;
// PURE VCL static example -- engine linked into this exe (LUMAS_STATIC), no LumasPdf.dll.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

function RGB(r, g, b: Cardinal): Cardinal;
begin
  Result := r or (g shl 8) or (b shl 16);
end;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  a: Integer;
  outFile: AnsiString;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;

    a := pdf.StampAnnotA(rsApproved, 135.0, 50.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The default language is English!');
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, RGB(120, 190, 92));

    pdf.SetLanguage('DE');
    a := pdf.StampAnnotA(rsApproved, 135.0, 150.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The same stamp in German!');
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, RGB(230, 65, 132));

    pdf.SetLanguage('FR');
    a := pdf.StampAnnotA(rsApproved, 135.0, 250.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The same stamp in French!');
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, RGB(78, 157, 232));
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
