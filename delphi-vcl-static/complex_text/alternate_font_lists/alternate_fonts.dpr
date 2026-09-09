program alternate_fonts;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Complex text layout with an alternate font list to improve font substitution.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  TXT_FILE = 'E:\LUMASPDFSDK\examples\test_files\multi_lang.txt';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// Reads a file raw as UTF-16 (2 bytes per char).
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
  altFonts: Integer;
  outFile: string;
  fonts: array[0..4] of PWideChar;
begin
  // Alternate fonts, sorted alphabetically.
  fonts[0] := 'Malgun Gothic';   // Korean
  fonts[1] := 'Mangal';          // Hindi or Marathi
  fonts[2] := 'Nyala';           // Amharic
  fonts[3] := 'Shonar Bangla';   // Bengali
  fonts[4] := 'Shruti';          // Gujarati

  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    txt := GetFileBuffer(TXT_FILE);

    pdf.SetPageCoords(Ord(pcTopDown));
    // Enable complex text layout
    pdf.SetGStateFlags(gfComplexText, False);

    altFonts := pdf.CreateAltFontList;
    pdf.SetAltFontsW(pdf.InstanceHandle, altFonts, @fonts[0], 5);

    pdf.Append;

    // The font must be loaded with cpUnicode.
    pdf.SetFontA('Arial', fsRegular, 10.0, True, cpUnicode);
    // Activate the alternate font list
    pdf.ActivateAltFontList(altFonts, True);

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
