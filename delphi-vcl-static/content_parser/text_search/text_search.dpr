program text_search;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Imports dynapdf_help.pdf, searches for the Unicode string "PDF" across the
// content stream via ParseContent + a flattened CTextSearch state machine, and
// draws yellow multiply-blend rectangles over each match.
{$APPTYPE CONSOLE}
{$POINTERMATH ON}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.Math,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core,
  Lumas.Pdf.Wrap.Imports;   // fnt* helper proc pointers (bound in-process by Wrap.Static)

const
  IN_FILE = 'E:\LUMASPDFSDK\dynapdf_help.pdf';
  tfNotInitialized = 5;
  MAX_LINE_ERROR = 4.0;

type
  GStateT = record
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
  gPdf: TLumasPDFCore;

  m_ActiveFont: PFNT;
  m_CharSpacing: Single;
  m_FontSize: Single;
  m_FontType: TFontType;
  m_Matrix: TCTM;
  m_SpaceWidth: Single;
  m_TextDrawMode: Integer;
  m_TextScale: Single;
  m_WordSpacing: Single;

  m_Items: array of GStateT;
  m_Count: Integer;
  m_Capacity: Integer;

  m_EndX1, m_EndY1, m_EndX4, m_EndY4: Double;
  m_HavePos: Boolean;
  m_LastTextDir: Integer;
  m_LastTextInfX, m_LastTextInfY: Double;
  m_OutBuf: array[0..31] of WideChar;
  m_SearchChars: array of WideChar;
  m_SearchTextLen: Integer;
  m_SearchPos: Integer;
  m_SelCount: Integer;
  m_x1, m_y1, m_x4, m_y4: Double;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// ---- matrix / geometry ----
function MulMatrix(const M1, M2: TCTM): TCTM;
begin
  Result.a := M2.a * M1.a + M2.b * M1.c;
  Result.b := M2.a * M1.b + M2.b * M1.d;
  Result.c := M2.c * M1.a + M2.d * M1.c;
  Result.d := M2.c * M1.b + M2.d * M1.d;
  Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
  Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

procedure Transform(const M: TCTM; var x, y: Double);
var tx: Double;
begin
  tx := x;
  x := tx * M.a + y * M.c + M.x;
  y := tx * M.b + y * M.d + M.y;
end;

function CalcDistance(x1, y1, x2, y2: Double): Double;
var dx, dy: Double;
begin
  dx := x2 - x1; dy := y2 - y1;
  Result := Sqrt(dx * dx + dy * dy);
end;

function IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
var dx, dy, di: Double;
begin
  x := x - x0; y := y - y0;
  dx := x1 - x0; dy := y1 - y0;
  if (dx * dx + dy * dy) = 0.0 then
  begin
    Result := (x * x + y * y) < MAX_LINE_ERROR;
    Exit;
  end;
  di := (x * dx + y * dy) / (dx * dx + dy * dy);
  if di < 0.0 then di := 0.0
  else if di > 1.0 then di := 1.0;
  dx := x - di * dx;
  dy := y - di * dy;
  di := dx * dx + dy * dy;
  Result := di < MAX_LINE_ERROR;
end;

// ---- search string handling ----
procedure SetSearchText(const Txt: AnsiString);
var i: Integer;
begin
  m_SearchTextLen := Length(Txt);
  if m_SearchTextLen > 0 then
  begin
    SetLength(m_SearchChars, m_SearchTextLen);
    for i := 0 to m_SearchTextLen - 1 do
      m_SearchChars[i] := WideChar(Byte(Txt[i + 1]));
  end;
  m_SearchPos := 0;
end;

function SPCode: Integer;
begin
  if m_SearchPos >= m_SearchTextLen then Result := 0
  else Result := Integer(Word(m_SearchChars[m_SearchPos]));
end;

procedure Reset_;
begin
  m_HavePos := False;
  m_SearchPos := 0;
end;

function Compare(TextPtr: PWideChar; Len_: Integer): Boolean;
var
  endPtr: PWideChar;
  wc: Integer;
begin
  endPtr := TextPtr + Len_;
  while TextPtr < endPtr do
  begin
    wc := Integer(Word(TextPtr^));
    if SPCode <> wc then
    begin
      m_HavePos := False;
      m_SearchPos := 0;
      Result := False;
      Exit;
    end;
    Inc(TextPtr);
    Inc(m_SearchPos);
    if SPCode = 0 then
    begin
      m_SearchPos := 0;
      Result := (TextPtr = endPtr);
      Exit;
    end;
  end;
  Result := True;
end;

// ---- graphics-state stack ----
function SaveGState: Integer;
var g: ^GStateT;
begin
  if m_Count = m_Capacity then
  begin
    Inc(m_Capacity, 28);
    SetLength(m_Items, m_Capacity);
  end;
  g := @m_Items[m_Count];
  g^.ActiveFont := m_ActiveFont;
  g^.CharSpacing := m_CharSpacing;
  g^.FontSize := m_FontSize;
  g^.FontType := m_FontType;
  g^.Matrix := m_Matrix;
  g^.SpaceWidth := m_SpaceWidth;
  g^.TextDrawMode := m_TextDrawMode;
  g^.TextScale := m_TextScale;
  g^.WordSpacing := m_WordSpacing;
  Inc(m_Count);
  Result := 0;
end;

function RestoreGState: Boolean;
var g: ^GStateT;
begin
  if m_Count > 0 then
  begin
    Dec(m_Count);
    g := @m_Items[m_Count];
    m_ActiveFont := g^.ActiveFont;
    m_CharSpacing := g^.CharSpacing;
    m_FontSize := g^.FontSize;
    m_FontType := g^.FontType;
    m_Matrix := g^.Matrix;
    m_SpaceWidth := g^.SpaceWidth;
    m_TextDrawMode := g^.TextDrawMode;
    m_TextScale := g^.TextScale;
    m_WordSpacing := g^.WordSpacing;
    Result := True;
  end
  else
    Result := False;
end;

// ---- rectangle drawing ----
procedure SetStartCoord(const Matrix: TCTM; x: Double);
begin
  m_x1 := x; m_y1 := 0.0;
  m_x4 := x; m_y4 := m_FontSize;
  Transform(Matrix, m_x1, m_y1);
  Transform(Matrix, m_x4, m_y4);
  m_HavePos := True;
end;

function DrawRectEx(x2, y2, x3, y3: Double): Boolean;
begin
  gPdf.MoveTo(m_x1, m_y1);
  gPdf.LineTo(x2, y2);
  gPdf.LineTo(x3, y3);
  gPdf.LineTo(m_x4, m_y4);
  m_HavePos := False;
  Inc(m_SelCount);
  Result := gPdf.ClosePath(fmFill);
end;

function DrawRect(const Matrix: TCTM; EndX: Double): Boolean;
var x2, y2, x3, y3: Double;
begin
  x2 := EndX; y2 := 0.0; x3 := EndX; y3 := m_FontSize;
  Transform(Matrix, x2, y2);
  Transform(Matrix, x3, y3);
  Result := DrawRectEx(x2, y2, x3, y3);
end;

// ---- init / reset ----
procedure InitGState;
begin
  while RestoreGState do ;
  m_ActiveFont := nil;
  m_CharSpacing := 0.0;
  m_FontSize := 1.0;
  m_Matrix.a := 1.0; m_Matrix.b := 0.0; m_Matrix.c := 0.0;
  m_Matrix.d := 1.0; m_Matrix.x := 0.0; m_Matrix.y := 0.0;
  m_SpaceWidth := 0.0;
  m_TextDrawMode := Ord(dmNormal);
  m_TextScale := 100.0;
  m_WordSpacing := 0.0;
  m_LastTextDir := tfNotInitialized;
  m_LastTextInfX := 0.0;
  m_LastTextInfY := 0.0;
end;

procedure TS_Create;
begin
  m_ActiveFont := nil;
  m_CharSpacing := 0.0;
  m_FontSize := 1.0;
  m_FontType := ftType1;
  m_Matrix.a := 1.0; m_Matrix.b := 0.0; m_Matrix.c := 0.0;
  m_Matrix.d := 1.0; m_Matrix.x := 0.0; m_Matrix.y := 0.0;
  m_SpaceWidth := 0.0;
  m_TextDrawMode := Ord(dmNormal);
  m_TextScale := 100.0;
  m_WordSpacing := 0.0;
  m_Count := 0;
  m_Capacity := 0;
end;

procedure TS_Init;
begin
  InitGState;
  Reset_;
  m_SelCount := 0;
end;

// ---- text-matching core ----
function MarkSubString(var x: Double; const Matrix: TCTM; srec: TTextRecordAPtr): Boolean;
var
  i, maxLen, outLen: Integer;
  decoded: LongBool;
  spaceWidth2: Single;
  w: Double;
  consumed: Cardinal;
  srcPtr: PAnsiChar;
begin
  i := 0;
  spaceWidth2 := -m_SpaceWidth * 6.0;
  maxLen := srec^.Length;
  srcPtr := srec^.Text;
  if srec^.Advance < -m_SpaceWidth then
  begin
    // If the distance is too large then no space was emulated here.
    if (srec^.Advance > spaceWidth2) and (SPCode = 32) then
    begin
      if not m_HavePos then
      begin
        SetStartCoord(Matrix, x);
        Inc(m_SearchPos);
        if SPCode = 0 then
        begin
          if not DrawRect(Matrix, x - srec^.Advance) then begin Result := False; Exit; end;
          Reset_;
        end;
      end
      else if SPCode = 0 then
      begin
        if not DrawRect(Matrix, 0.0) then begin Result := False; Exit; end;
        Reset_;
      end
      else
        Inc(m_SearchPos);
    end
    else
      Reset_;
  end;
  x := x - srec^.Advance;
  outLen := 0;
  while i < maxLen do
  begin
    w := 0.0; decoded := False;
    consumed := fntTranslateRawCode(m_ActiveFont, srcPtr + i, Cardinal(maxLen - i),
      w, @m_OutBuf[0], outLen, decoded, m_CharSpacing, m_WordSpacing, m_TextScale);
    if Integer(consumed) <= 0 then Break;   // safety: never let i stall
    Inc(i, Integer(consumed));
    if not decoded then begin Result := True; Exit; end;  // skip record; must return TRUE
    if Compare(@m_OutBuf[0], outLen) then
    begin
      if not m_HavePos then SetStartCoord(Matrix, x);
      x := x + w;
      if m_SearchPos = 0 then
      begin
        if not DrawRect(Matrix, x - m_CharSpacing) then begin Result := False; Exit; end;
      end;
    end
    else
      x := x + w;
  end;
  Result := True;
end;

function MarkText(const Matrix: TCTM; Source: TTextRecordAPtr; Count: Cardinal; Width_: Double): Integer;
var
  i: Cardinal;
  x, x1, x2, x3, y1, y2, y3, distance, spaceWidth: Double;
  textDir: Integer;
  m: TCTM;
  wrongLine: Boolean;
begin
  x1 := 0.0; y1 := 0.0;
  x2 := 0.0; y2 := m_FontSize;
  m := MulMatrix(m_Matrix, Matrix);
  Transform(m, x1, y1);
  Transform(m, x2, y2);
  if y1 = y2 then
    textDir := (IfThen(x1 > x2, 1, 0) + 1) * 2
  else
    textDir := IfThen(y1 > y2, 1, 0);

  wrongLine := (textDir <> m_LastTextDir) or
               (not IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY));
  if wrongLine then
  begin
    m_LastTextInfX := 1000000.0;
    m_LastTextInfY := 0.0;
    Transform(m, m_LastTextInfX, m_LastTextInfY);
    Reset_;
  end
  else
  begin
    x3 := m_SpaceWidth; y3 := 0.0;
    Transform(m, x3, y3);
    spaceWidth := CalcDistance(x1, y1, x3, y3);
    distance := CalcDistance(m_EndX1, m_EndY1, x1, y1);
    if distance > spaceWidth then
    begin
      if (distance < spaceWidth * 6.0) and (SPCode = 32) then
      begin
        if not m_HavePos then
        begin
          m_HavePos := True;
          Inc(m_SearchPos);
          if SPCode = 0 then
          begin
            m_x1 := m_EndX1; m_y1 := m_EndY1;
            m_x4 := m_EndX4; m_y4 := m_EndY4;
            if not DrawRectEx(x1, y1, x2, y2) then begin Result := -1; Exit; end;
            Reset_;
          end;
        end
        else if SPCode = 32 then
        begin
          if not DrawRectEx(x1, y1, x2, y2) then begin Result := -1; Exit; end;
          Reset_;
        end
        else
          Inc(m_SearchPos);
      end
      else
        Reset_;
    end;
  end;

  x := 0.0;
  for i := 0 to Count - 1 do
  begin
    if not MarkSubString(x, m, @Source[i]) then begin Result := -1; Exit; end;
  end;
  m_LastTextDir := textDir;
  m_EndX1 := Width_; m_EndY1 := 0.0;
  m_EndX4 := 0.0;    m_EndY4 := m_FontSize;
  Transform(m, m_EndX1, m_EndY1);
  Transform(m, m_EndX4, m_EndY4);
  Result := 0;
end;

// ---- CTextSearch state methods ----
function BeginTemplate(MatrixPtr: PCTM): Integer;
begin
  if SaveGState < 0 then begin Result := -1; Exit; end;
  if MatrixPtr <> nil then
    m_Matrix := MulMatrix(m_Matrix, MatrixPtr^);
  Result := 0;
end;

procedure TS_SetFont(IFont: PFNT; FontType: TFontType; FontSize: Double);
begin
  m_ActiveFont := IFont;
  m_FontSize := FontSize;
  m_FontType := FontType;
  m_SpaceWidth := fntGetSpaceWidth(IFont, FontSize) * 0.5;
end;

// ---- parse* callback thunks ----
function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
  Result := BeginTemplate(Matrix);
end;
procedure parseEndTemplate(const Data: Pointer); stdcall;
begin
  RestoreGState;
end;
procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
begin
  m_Matrix := MulMatrix(m_Matrix, Matrix);
end;
function parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
begin
  RestoreGState; Result := 0;
end;
function parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
begin
  Result := SaveGState;
end;
procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_CharSpacing := Value;
end;
procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool;
                       const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: PFNT); stdcall;
begin
  TS_SetFont(Font, FontType, FontSize);
end;
procedure parseSetTextDrawMode(const Data, PDFObject: Pointer; Mode: TDrawMode); stdcall;
begin
  m_TextDrawMode := Ord(Mode);
end;
procedure parseSetTextScale(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_TextScale := Value;
end;
procedure parseSetWordSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_WordSpacing := Value;
end;
function parseShowTextArrayA(const Data: Pointer; Obj: PAnsiChar; var Matrix: TCTM;
                            const Source: TTextRecordAPtr; Count: Cardinal; Width: Double): Integer; stdcall;
begin
  Result := MarkText(Matrix, Source, Count, Width);
end;

var
  pdf: TLumasPDFCore;
  stack: TPDFParseInterface;
  g: TPDFExtGState;
  gs: Integer;
  selCount: Integer;
  dir, outFile, cmapDir: string;
  i: Integer;
begin
  dir := ExtractFilePath(ParamStr(0));
  selCount := 0;

  gPdf := nil;
  TS_Create;

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
  stack.ShowTextArrayA := parseShowTextArrayA;   // this example uses the A slot

  pdf := TLumasPDFCore.Create;
  gPdf := pdf;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

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

    // The search text must be defined in Unicode.
    SetSearchText('PDF');

    // Use blend mode bmMultiply so the background text stays visible.
    pdf.InitExtGState(g);
    g.BlendMode := bmMultiply;
    gs := pdf.CreateExtGState(g);

    for i := 1 to pdf.GetPageCount do
    begin
      pdf.EditPage(i);
      pdf.SetExtGState(gs);
      pdf.SetFillColor($00FFFF);   // yellow RGB(255,255,0)

      TS_Init;
      pdf.ParseContent(nil, stack, pfNone);
      pdf.EndPage;
      if m_SelCount > 0 then
      begin
        selCount := selCount + m_SelCount;
        Writeln(Format('Found string on Page: %d %d times!', [i, m_SelCount]));
      end;
    end;

    outFile := '';
    if pdf.HaveOpenDoc then
    begin
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    end;
    if pdf.CloseFile then
      Writeln(Format('PDF file "%s" successfully created!', [outFile]));
    Writeln('');
    Writeln(Format('Found string in the file %d times!', [selCount]));
  finally
    pdf.Free;
  end;
end.
