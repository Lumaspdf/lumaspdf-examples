program personalize;
// Delphi OO example -- imports a tax form, fills in the fields, adds a web link.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

const
  RGB_FF6666 = $6666FF; // RGB(0xFF,0x66,0x66) = R | G<<8 | B<<16

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := -1;
end;

var
  pdf: TPDF;
  dir, inFile, outFile: string;
  nowbuf: AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.CreateNewPDFA('');

    pdf.SetViewerPreferences(vpDisplayDocTitle, avNone);
    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    inFile := dir + 'taxform.pdf';
    if pdf.OpenImportFileA(PAnsiChar(AnsiString(inFile)), ptOpen, '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);

    pdf.EditPage(1);
    pdf.SetFontA('Courier', fsBold, 14.0, False, cp1252);
    pdf.WriteTextA(72.5, 748.5, 'X');
    pdf.WriteTextA(74.0, 701.0, 'Musterstadt');
    pdf.WriteTextA(74.0, 677.0, '252/1062/3323');
    pdf.BeginContinueText(74.0, 628.0);
    pdf.SetLeading(24.0);
    pdf.SetCharacterSpacing(5.8);
    pdf.AddContinueTextA('Mustermann');
    pdf.AddContinueTextA('Hermann');
    pdf.AddContinueTextA('22021963keineKaufmann');
    pdf.AddContinueTextA(PAnsiChar(AnsiString('Musterstra'#$DF'e 145')));
    pdf.AddContinueTextA('12345Musterstadt');
    pdf.SetCharacterSpacing(0.0);
    pdf.SetFontA('Courier', fsBold, 10.0, False, cp1252);
    pdf.SetLeading(48.0);
    pdf.AddContinueTextA('04.05.1994');
    pdf.SetFontA('Courier', fsBold, 14.0, False, cp1252);
    pdf.SetCharacterSpacing(5.8);
    pdf.AddContinueTextA('Sabine');
    pdf.SetLeading(47.5);
    pdf.AddContinueTextA('18121966 ev  Hausfrau');
    pdf.EndContinueText;
    pdf.WriteTextA(72.5, 365.0, 'X');
    pdf.WriteTextA(396.0, 365.0, 'X');
    pdf.BeginContinueText(74.0, 316.0);
    pdf.SetLeading(24.0);
    pdf.AddContinueTextA('2346256780     76834560');
    pdf.AddContinueTextA('Sparkasse Musterstadt');
    pdf.EndContinueText;
    pdf.WriteTextA(72.5, 269.0, 'X');
    pdf.SetCharacterSpacing(0.0);
    pdf.SetFontA('Courier', fsNone, 10.0, False, cp1252);
    nowbuf := AnsiString(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now));
    pdf.WriteTextA(53.0, 48.0, PAnsiChar(nowbuf));
    pdf.SetFillColor(RGB_FF6666);
    pdf.SetFontA('Helvetica', fsBold, 22.0, False, cp1252);
    pdf.WriteTextA(340.0, 70.0, 'www.dynaforms.de');
    pdf.SetLineWidth(0.0);
    pdf.SetLinkHighlightMode(Ord(hmPush));
    pdf.SetAnnotFlags(afReadOnly);
    pdf.WebLinkA(340.0, 64.0, 204.0, 22.0, 'http://www.dynaforms.de');
    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      pdf.SetOnErrorProc(nil, nil);
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
      pdf.SetOnErrorProc(nil, @ErrProc);
    end;
    if pdf.CloseFile then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    pdf.Free;
  end;
end.
