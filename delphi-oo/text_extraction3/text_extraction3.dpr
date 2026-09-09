program text_extraction3;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF), NOT the flat API.
// Imports a PDF and extracts its text page by page with ExtractText, then writes
// the result to out.txt as UTF-16LE (with BOM).
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  System.Classes,
  LumasPdf,
  LumasPdfOO;

var
  m_File: TFileStream;

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure WritePageIdentifier(PageNum: Integer);
var s: UnicodeString;
begin
  if PageNum > 1 then s := #13#10 else s := '';
  s := s + '%----------------------- Page ' + IntToStr(PageNum) +
       ' -----------------------------'#13#10;
  m_File.WriteBuffer(PWideChar(s)^, 2 * Length(s));
end;

var
  pdf: TPDF;
  i, cnt: Integer;
  bom: array[0..1] of Byte;
  textPtr: PWideChar;
  textLen: Cardinal;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetCMapDirA('CMap', lcmRecursive or lcmDelayed);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('in.pdf', ptOpen, '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;

    pdf.FlattenAnnots(affMarkupAnnots);
    pdf.FlattenForm;

    m_File := TFileStream.Create('out.txt', fmCreate);
    try
      bom[0] := $FF; bom[1] := $FE;
      m_File.WriteBuffer(bom, 2);

      cnt := pdf.GetPageCount;
      for i := 1 to cnt do
      begin
        WritePageIdentifier(i);
        textPtr := nil; textLen := 0;
        if pdf.ExtractText2(i, tefDeleteOverlappingText or tefSortTextX, nil, textPtr, textLen) then
          if (textLen > 0) and (textPtr <> nil) then
            m_File.WriteBuffer(textPtr^, 2 * textLen);
      end;
    finally
      m_File.Free;
    end;

    Writeln('Text successfully extracted to out.txt');
  finally
    pdf.Free;
  end;
end.
