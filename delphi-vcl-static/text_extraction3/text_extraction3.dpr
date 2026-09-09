program text_extraction3;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Imports a PDF and extracts its text page by page with ExtractText, then writes
// the result to out.txt as UTF-16LE (with BOM).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,              // lcm*, if*, ptOpen, aff*, tef*
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure WritePageIdentifier(f: TFileStream; PageNum: Integer);
var s: UnicodeString;
begin
  if PageNum > 1 then s := #13#10 else s := '';
  s := s + '%----------------------- Page ' + IntToStr(PageNum) +
       ' -----------------------------'#13#10;
  f.WriteBuffer(PWideChar(s)^, 2 * Length(s));
end;

var
  pdf: TLumasPDFCore;
  f: TFileStream;
  i, cnt: Integer;
  bom: array[0..1] of Byte;
  textPtr: PWideChar;
  textLen: Cardinal;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetCMapDirA('CMap', lcmRecursive or lcmDelayed);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('in.pdf', Ord(ptOpen), '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;

    pdf.FlattenAnnots(affMarkupAnnots);
    pdf.FlattenForm;

    f := TFileStream.Create('out.txt', fmCreate);
    try
      bom[0] := $FF; bom[1] := $FE;
      f.WriteBuffer(bom, 2);

      cnt := pdf.GetPageCount;
      for i := 1 to cnt do
      begin
        WritePageIdentifier(f, i);
        textPtr := nil; textLen := 0;
        if pdf.ExtractText(i, tefDeleteOverlappingText or tefSortTextX, nil, textPtr, textLen) then
          if (textLen > 0) and (textPtr <> nil) then
            f.WriteBuffer(textPtr^, 2 * textLen);
      end;
    finally
      f.Free;
    end;

    Writeln('Text successfully extracted to out.txt');
  finally
    pdf.Free;
  end;
end.
