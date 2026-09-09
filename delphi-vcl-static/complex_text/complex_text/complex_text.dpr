program complex_text;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Complex text layout of a right-to-left (Pashto) text.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  TXT_FILE = 'E:\LUMASPDFSDK\examples\test_files\pashto.txt';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function GetFileBuffer(const FileName: string): WideString;
var
  strm: TFileStream;
begin
  Result := '';
  strm := nil;
  try
    strm := TFileStream.Create(FileName, fmOpenRead);
    SetLength(Result, strm.Size div 2);
    if strm.Size > 0 then strm.Read(Result[1], strm.Size);
  except
    if strm <> nil then strm.Free;
    Exit;
  end;
  strm.Free;
end;

var
  pdf: TLumasPDFCore;
  txt: WideString;
  outFile: string;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    txt := GetFileBuffer(TXT_FILE);

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetGStateFlags(gfComplexText, False);
    pdf.SetBidiMode(Ord(bmRightToLeft));

    pdf.Append;

    pdf.SetFontA('Arial', fsRegular, 10.0, True, cpUnicode);
    pdf.SetLeading(pdf.GetTypoLeading);
    pdf.WriteFTextExW(50.0, 50.0, pdf.GetPageWidth - 100.0, pdf.GetPageHeight - 100.0,
                      taJustify, PWideChar(txt));

    txt := '';
    pdf.EndPage;

    outFile := '';
    if pdf.HaveOpenDoc then
    begin
      outFile := ExtractFilePath(ParamStr(0)) + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    end;
    if pdf.CloseFile then
      Writeln(Format('PDF file "%s" successfully created!', [outFile]));
  finally
    pdf.Free;
  end;
end.
