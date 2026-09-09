program text_extraction2;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Extracts the text of a PDF file by driving ParseContent() with a
// TPDFParseInterface of stdcall callbacks. Output is out.txt as UTF-16LE.
{$APPTYPE CONSOLE}
{$POINTERMATH ON}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.Classes,
  System.Math,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core,
  Lumas.Pdf.Wrap.Imports;   // fnt* helper proc pointers (bound in-process by Wrap.Static)

const
  IN_FILE = 'E:\LUMASPDFSDK\sample_multipage.pdf';
  tfNotInitialized = 5;
  MAX_LINE_ERROR = 4.0;

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
  gPdf: TLumasPDFCore;
  m_File: TFileStream;
  m_GState: TGState;
  m_LastTextDir: Integer;
  m_LastTextEndX, m_LastTextEndY: Double;
  m_LastTextInfX, m_LastTextInfY: Double;
  m_StackItems: array of TGState;
  m_StackCount: Integer;
  m_StackCapacity: Integer;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// ---- output helpers ----
procedure WriteWStr(const s: AnsiString);
var
  i: Integer;
  two: array[0..1] of Byte;
begin
  two[1] := 0;
  for i := 1 to Length(s) do
  begin
    two[0] := Byte(s[i]);
    m_File.WriteBuffer(two, 2);
  end;
end;

procedure WriteWCharsFromPtr(Ptr: PWideChar; WCharCount: Integer);
begin
  if (Ptr = nil) or (WCharCount <= 0) then Exit;
  m_File.WriteBuffer(Ptr^, WCharCount * 2);
end;

// ---- stack ----
function StackRestore(var F: TGState): Boolean;
begin
  if m_StackCount > 0 then
  begin
    Dec(m_StackCount);
    F := m_StackItems[m_StackCount];
    Result := True;
  end
  else
    Result := False;
end;

function StackSave(const F: TGState): Integer;
begin
  if m_StackCount = m_StackCapacity then
  begin
    Inc(m_StackCapacity, 28);
    SetLength(m_StackItems, m_StackCapacity);
  end;
  m_StackItems[m_StackCount] := F;
  Inc(m_StackCount);
  Result := 0;
end;

// ---- matrix helpers ----
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
  di := (x * dx + y * dy) / (dx * dx + dy * dy);
  if di < 0.0 then di := 0.0
  else if di > 1.0 then di := 1.0;
  dx := x - di * dx;
  dy := y - di * dy;
  di := dx * dx + dy * dy;
  Result := di < MAX_LINE_ERROR;
end;

// ---- CPDFToText methods ----
function DoRestoreGState: Boolean;
begin
  Result := StackRestore(m_GState);
end;

function DoSaveGState: Integer;
begin
  Result := StackSave(m_GState);
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
  m_GState.SpaceWidth := 0.0;
  m_GState.TextDrawMode := Ord(dmNormal);
  m_GState.TextScale := 100.0;
  m_GState.WordSpacing := 0.0;
end;

procedure DoInit;
begin
  while DoRestoreGState do ;
  ResetGState;
  m_LastTextDir := tfNotInitialized;
  m_LastTextEndX := 0.0; m_LastTextEndY := 0.0;
  m_LastTextInfX := 0.0; m_LastTextInfY := 0.0;
end;

procedure DoSetFont(IFont: PFNT; FontType: TFontType; FontSize: Double);
begin
  m_GState.ActiveFont := IFont;
  m_GState.FontSize := FontSize;
  m_GState.FontType := FontType;
  m_GState.SpaceWidth := fntGetSpaceWidth(IFont, FontSize);
  if FontSize < 0.0 then m_GState.SpaceWidth := -m_GState.SpaceWidth;
end;

procedure DoWritePageIdentifier(PageNum: Integer);
begin
  if PageNum > 1 then WriteWStr(#13#10);
  WriteWStr(AnsiString(Format('%%----------------------- Page %d -----------------------------'#13#10, [PageNum])));
end;

// ---- text reconstruction (AddText) ----
function DoAddText(const Matrix: TCTM; Kerning: TTextRecordWPtr; Count: Cardinal;
                   Widen: Double; Decoded: LongBool): Integer;
var
  i: Cardinal;
  x1, x2, x3, y1, y2, y3, distance, spaceWidth: Double;
  textDir: Integer;
  m: TCTM;
  spw: Single;
  rec: TTextRecordW;
begin
  if not Decoded then begin Result := 0; Exit; end;

  x1 := 0.0; y1 := 0.0;
  x2 := 0.0; y2 := m_GState.FontSize;
  m := MulMatrix(m_GState.Matrix, Matrix);
  Transform(m, x1, y1);
  Transform(m, x2, y2);

  if y1 = y2 then
    textDir := (IfThen(x1 > x2, 1, 0) + 1) * 2
  else
    textDir := IfThen(y1 > y2, 1, 0);

  if (textDir <> m_LastTextDir) or
     (not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)) then
  begin
    m_LastTextInfX := 1000000.0;
    m_LastTextInfY := 0.0;
    Transform(m, m_LastTextInfX, m_LastTextInfY);
    if m_LastTextDir <> tfNotInitialized then WriteWStr(#13#10);
  end
  else
  begin
    x3 := m_GState.SpaceWidth; y3 := 0.0;
    Transform(m, x3, y3);
    spaceWidth := CalcDistance(x1, y1, x3, y3);
    distance := CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
    if distance > spaceWidth then WriteWStr(' ');
  end;

  spw := -m_GState.SpaceWidth * 0.5;
  for i := 0 to Count - 1 do
  begin
    rec := Kerning[i];
    if rec.Advance < spw then WriteWStr(' ');
    WriteWCharsFromPtr(rec.Text, rec.Length);
  end;

  m_LastTextEndX := Widen + spw;   // spw is negative
  m_LastTextEndY := 0.0;
  m_LastTextDir := textDir;
  Transform(m, m_LastTextEndX, m_LastTextEndY);
  Result := 0;
end;

// ---- parse* callback thunks ----
function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
  if DoSaveGState < 0 then begin Result := -1; Exit; end;
  if Matrix <> nil then
    m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix^);
  Result := 0;
end;
procedure parseEndTemplate(const Data: Pointer); stdcall;
begin
  DoRestoreGState;
end;
procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
begin
  m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix);
end;
function parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
begin
  DoRestoreGState; Result := 0;
end;
function parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
begin
  DoSaveGState; Result := 0;
end;
procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
  m_GState.CharSpacing := Value;
end;
procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool;
                       const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: PFNT); stdcall;
begin
  DoSetFont(Font, FontType, FontSize);
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
  Result := DoAddText(Matrix, Kerning, Count, Width, Decoded);
end;

var
  pdf: TLumasPDFCore;
  stack: TPDFParseInterface;
  dir, outFile, cmapDir: string;
  bom: array[0..1] of Byte;
  i: Integer;
begin
  dir := ExtractFilePath(ParamStr(0));

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

    outFile := dir + 'out.txt';
    m_File := TFileStream.Create(outFile, fmCreate);
    try
      bom[0] := $FF; bom[1] := $FE;   // UTF-16LE BOM
      m_File.WriteBuffer(bom, 2);

      for i := 1 to pdf.GetPageCount do
      begin
        pdf.EditPage(i);
        DoInit;
        DoWritePageIdentifier(i);
        pdf.ParseContent(nil, stack, pfNone);
        pdf.EndPage;
      end;
    finally
      m_File.Free;
    end;

    Writeln(Format('Text successfully extracted to %s', [outFile]));
  finally
    pdf.Free;
  end;
end.
