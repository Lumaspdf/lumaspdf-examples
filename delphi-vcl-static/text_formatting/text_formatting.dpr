program text_formatting;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Lays out sample.txt into N columns using a page-break callback and writes out.pdf.
// The column count is a constant (3).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,              // pcTopDown, di*, fsNone, cp1252, taJustify
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

type
  TOutRect = record
    PosX, PosY, Width_, Height_, Distance: Double;
    Column, ColCount: Integer;
  end;

var
  gRect: TOutRect;
  gPDF: TLumasPDFCore;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := -1;   // break processing if an error occurred
end;

function OnPageBreakProc(const Data: Pointer; LastPosX, LastPosY: Double; PageBreak: LongBool): Integer; stdcall;
var x: Double;
begin
  gPDF.SetPageCoords(Ord(pcTopDown));
  Inc(gRect.Column);
  if (not PageBreak) and (gRect.Column < gRect.ColCount) then
  begin
    x := gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance);
    gPDF.SetTextRect(x, gRect.PosY, gRect.Width_, gRect.Height_);
    Result := 0;
  end
  else
  begin
    gPDF.EndPage;
    gPDF.Append;
    gPDF.SetTextRect(gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
    gRect.Column := 0;
    Result := 0;
  end;
end;

function LoadTextFile(const fn: string): AnsiString;
var fs: TFileStream;
begin
  Result := '';
  if not FileExists(fn) then Exit;
  fs := TFileStream.Create(fn, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(Result[1], fs.Size);
  finally
    fs.Free;
  end;
end;

const
  outFile = 'out.pdf';
var
  fText: AnsiString;
begin
  fText := LoadTextFile('sample.txt');

  gPDF := TLumasPDFCore.Create;
  try
    gPDF.SetOnErrorProc(nil, @ErrProc);
    gPDF.SetDocInfoA(diCreator, 'VCL static test app');
    gPDF.SetDocInfoA(diSubject, 'Multi-column text');
    gPDF.SetDocInfoA(diTitle, 'Multi-column text');
    gPDF.SetPageCoords(Ord(pcTopDown));

    if not gPDF.CreateNewPDFA('') then Exit;

    gRect.ColCount := 3;
    gRect.Column := 0;
    gRect.Distance := 10.0;
    gRect.PosX := 50.0;
    gRect.PosY := 50.0;
    gRect.Height_ := gPDF.GetPageHeight - 100.0;
    gRect.Width_ := (gPDF.GetPageWidth - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount;

    gPDF.SetOnPageBreakProc(@gRect, @OnPageBreakProc);
    gPDF.Append;
    gPDF.SetTextRect(gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
    gPDF.SetFontA('Arial', fsNone, 9.0, True, cp1252);
    gPDF.WriteFTextA(taJustify, PAnsiChar(fText));

    gPDF.EndPage;
    if gPDF.HaveOpenDoc then
    begin
      gPDF.SetOnErrorProc(nil, nil);
      if not gPDF.OpenOutputFileA(outFile) then Exit;
      gPDF.SetOnErrorProc(nil, @ErrProc);
    end;
    if gPDF.CloseFile then
      Writeln('OK: ' + outFile);
  finally
    gPDF.Free;
  end;
end.
