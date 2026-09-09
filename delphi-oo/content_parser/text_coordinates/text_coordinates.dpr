program text_coordinates;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Imports dynapdf_help.pdf; for every page runs ParseContent with a callback
// interface. The MarkText callback draws lines under each text record.
{$APPTYPE CONSOLE}
{$POINTERMATH ON}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  IN_FILE = 'E:\LUMASPDFSDK\dynapdf_help.pdf';
  clRed  = $0000FF;
  clBlue = $FF0000;

type
  TGState = record
    ActiveFont: PFNT;
    CharSpacing: Single;
    FontSize: Single;
    FontType: TFontType;
    Matrix: TCTM;
    SpaceWidth: Single;
    TextDrawMode: Integer;
    TextScale: Single;
    WordSpacing: Single;
  end;

var
  gPdf: TPDF;
  m_Count: Integer;
  m_GState: TGState;
  m_Items: array of TGState;
  m_StackCap: Integer;
  m_StackCount: Integer;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function MulMatrix(const M1, M2: TCTM): TCTM;
begin
  Result.a := M2.a * M1.a + M2.b * M1.c;
  Result.b := M2.a * M1.b + M2.b * M1.d;
  Result.c := M2.c * M1.a + M2.d * M1.c;
  Result.d := M2.c * M1.b + M2.d * M1.d;
  Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
  Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

procedure Transform(const m: TCTM; var x, y: Double);
var tx: Double;
begin
  tx := x;
  x := tx * m.a + y * m.c + m.x;
  y := tx * m.b + y * m.d + m.y;
end;

function RestoreGState: Boolean;
begin
  if m_StackCount > 0 then
  begin
    Dec(m_StackCount);
    m_GState := m_Items[m_StackCount];
    Result := True;
  end
  else
    Result := False;
end;

function SaveGState: Integer;
begin
  if m_StackCount = m_StackCap then
  begin
    Inc(m_StackCap, 28);
    SetLength(m_Items, m_StackCap);
  end;
  m_Items[m_StackCount] := m_GState;
  Inc(m_StackCount);
  Result := 0;
end;

procedure ResetGState;
begin
  m_GState.ActiveFont := nil;
  m_GState.CharSpacing := 0.0;
  m_GState.FontSize := 1.0;
  m_GState.FontType := ftType1;
  m_GState.Matrix.a := 1.0; m_GState.Matrix.b := 0.0;
  m_GState.Matrix.c := 0.0; m_GState.Matrix.d := 1.0;
  m_GState.Matrix.x := 0.0; m_GState.Matrix.y := 0.0;
  m_GState.TextDrawMode := Ord(dmNormal);
  m_GState.TextScale := 100.0;
  m_GState.WordSpacing := 0.0;
end;

procedure TCInit;
begin
  while RestoreGState do ;
  m_Count := 0;
  ResetGState;
end;

function BeginTemplateImpl(Matrix: PCTM): Integer;
begin
  if SaveGState < 0 then begin Result := -1; Exit; end;
  if Matrix <> nil then
    m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix^);
  Result := 0;
end;

procedure SetFontImpl(IFont: PFNT; FontType: TFontType; FontSize: Double);
begin
  m_GState.ActiveFont := IFont;
  m_GState.FontSize := FontSize;
  m_GState.FontType := FontType;
  m_GState.SpaceWidth := fntGetSpaceWidth(IFont, FontSize);
end;

function MarkText(const Matrix: TCTM; Source: TTextRecordAPtr; Kerning: TTextRecordWPtr;
                  Count: Cardinal; AWidth: Double; Decoded: LongBool): Integer;
var
  i: Cardinal;
  j, last, rlen: Integer;
  x1, x2, y1, y2, textWidth: Double;
  m: TCTM;
  krec: TTextRecordW;
  srec: TTextRecordA;
begin
  if not Decoded then begin Result := 0; Exit; end;

  x1 := 0.0; y1 := 0.0;
  m := MulMatrix(m_GState.Matrix, Matrix);
  Transform(m, x1, y1);

  textWidth := 0.0;
  x2 := 0.0; y2 := 0.0;

  if m_GState.FontType = ftType0 then
  begin
    // Word spacing must be ignored if a CID font is selected!
    for i := 0 to Count - 1 do
    begin
      krec := Kerning[i];
      if krec.Advance <> 0.0 then
      begin
        textWidth := textWidth - krec.Advance;
        x1 := textWidth; y1 := 0.0;
        Transform(m, x1, y1);
      end;
      textWidth := textWidth + krec.Width;
      x2 := textWidth; y2 := 0.0;
      Transform(m, x2, y2);
      gPdf.MoveTo(x1, y1);
      gPdf.LineTo(x2, y2);
      if (m_Count and 1) <> 0 then gPdf.SetStrokeColor(clRed) else gPdf.SetStrokeColor(clBlue);
      if not gPdf.StrokePath then begin Result := -1; Exit; end;
      x1 := x2; y1 := y2;
    end;
  end
  else
  begin
    for i := 0 to Count - 1 do
    begin
      srec := Source[i];
      j := 0; last := 0;
      if srec.Advance <> 0.0 then
      begin
        textWidth := textWidth - srec.Advance;
        x1 := textWidth; y1 := 0.0;
        Transform(m, x1, y1);
      end;
      rlen := srec.Length;
      if srec.Text = nil then rlen := 0;
      while j < rlen do
      begin
        if Ord(srec.Text[j]) <> 32 then
          Inc(j)
        else
        begin
          if j > last then
          begin
            textWidth := textWidth + fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
              Cardinal(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
            x2 := textWidth; y2 := 0.0;
            Transform(m, x2, y2);
            gPdf.MoveTo(x1, y1);
            gPdf.LineTo(x2, y2);
            if (m_Count and 1) <> 0 then gPdf.SetStrokeColor(clRed) else gPdf.SetStrokeColor(clBlue);
            if not gPdf.StrokePath then begin Result := -1; Exit; end;
          end;
          last := j;
          Inc(j);
          while (j < rlen) and (Ord(srec.Text[j]) = 32) do Inc(j);
          textWidth := textWidth + fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
            Cardinal(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
          last := j;
          x1 := textWidth; y1 := 0.0;
          Transform(m, x1, y1);
        end;
      end;
      if j > last then
      begin
        textWidth := textWidth + fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
          Cardinal(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
        x2 := textWidth; y2 := 0.0;
        Transform(m, x2, y2);
        gPdf.MoveTo(x1, y1);
        gPdf.LineTo(x2, y2);
        if (m_Count and 1) <> 0 then gPdf.SetStrokeColor(clRed) else gPdf.SetStrokeColor(clBlue);
        if not gPdf.StrokePath then begin Result := -1; Exit; end;
      end;
      x1 := x2; y1 := y2;
    end;
  end;
  Inc(m_Count);
  Result := 0;
end;

// ---- parse* callback thunks ----
function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
  Result := BeginTemplateImpl(Matrix);
end;
procedure parseEndTemplate(const Data: Pointer); stdcall;
begin
  RestoreGState;
end;
procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
begin
  m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix);
end;
function parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
begin
  RestoreGState; Result := 0;
end;
function parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
begin
  SaveGState; Result := 0;
end;
procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_GState.CharSpacing := Value;
end;
procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool;
                       const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: PFNT); stdcall;
begin
  SetFontImpl(Font, FontType, FontSize);
end;
procedure parseSetTextDrawMode(const Data, PDFObject: Pointer; Mode: TDrawMode); stdcall;
begin
  m_GState.TextDrawMode := Ord(Mode);
end;
procedure parseSetTextScale(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_GState.TextScale := Value;
end;
procedure parseSetWordSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_GState.WordSpacing := Value;
end;
function parseShowTextArrayW(const Data: Pointer; const Source: TTextRecordAPtr; var Matrix: TCTM;
                             const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: LongBool): Integer; stdcall;
begin
  Result := MarkText(Matrix, Source, Kerning, Count, Width, Decoded);
end;

var
  pdf: TPDF;
  stack: TPDFParseInterface;
  dir, outFile, cmapDir: string;
  i: Integer;
begin
  dir := ExtractFilePath(ParamStr(0));

  FillChar(stack, SizeOf(stack), 0);
  stack.BeginTemplate := parseBeginTemplate;
  stack.EndTemplate := parseEndTemplate;
  stack.MulMatrix := parseMulMatrix;
  stack.RestoreGraphicState := parseRestoreGraphicState;
  stack.SaveGraphicState := parseSaveGraphicState;
  stack.SetCharSpacing := parseSetCharSpacing;
  stack.SetFont := parseSetFont;
  stack.SetTextDrawMode := parseSetTextDrawMode;
  stack.SetTextScale := parseSetTextScale;
  stack.SetWordSpacing := parseSetWordSpacing;
  stack.ShowTextArrayW := parseShowTextArrayW;

  pdf := TPDF.Create;
  gPdf := pdf;
  m_StackCount := 0;
  m_StackCap := 0;
  m_Count := 0;
  ResetGState;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    // External cmaps should always be loaded when extracting text.
    cmapDir := dir + 'CMap';
    pdf.SetCMapDirA(PAnsiChar(AnsiString(cmapDir)), lcmRecursive or lcmDelayed);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);

    if pdf.OpenImportFileA(IN_FILE, Ord(ptOpen), '') < 0 then
    begin
      Writeln('Input file "' + IN_FILE + '" not found!');
      Exit;
    end;
    if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then Exit;

    pdf.FlattenAnnots(affMarkupAnnots);
    pdf.FlattenForm;

    for i := 1 to pdf.GetPageCount do
    begin
      pdf.EditPage(i);
      pdf.SetLineWidth(0.5);
      TCInit;
      pdf.ParseContent(nil, stack, pfNone);
      pdf.EndPage;
    end;

    outFile := '';
    if pdf.HaveOpenDoc then
    begin
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    end;
    if pdf.CloseFile then
      Writeln(Format('PDF file "%s" successfully created!', [outFile]));
  finally
    pdf.Free;
  end;
end.
