program text_extraction;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF), NOT the flat API.
// Imports a PDF and extracts its text with GetPageText()/TPDFStack, rebuilding
// text lines and word boundaries by transforming each text record to user space.
// Output is written to out.txt as UTF-16LE (with BOM).
{$APPTYPE CONSOLE}
{$POINTERMATH ON}
uses
  System.SysUtils,
  System.Classes,
  System.Math,
  LumasPdf,
  LumasPdfOO;

const
  tfNotInitialized = 5;      // TTextDir sentinel
  MAX_LINE_ERROR   = 4.0;    // square of the allowed error (2*2)

var
  m_PDF: TPDF;
  m_File: TFileStream;
  m_Stack: TPDFStack;
  m_LastTextDir: Integer;
  m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY: Double;
  m_Templates: array[0..4095] of Integer;
  m_TemplCount: Integer;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// ---------------- output helpers ----------------
procedure WriteWStr(const s: UnicodeString);
begin
  if s <> '' then m_File.WriteBuffer(PWideChar(s)^, 2 * Length(s));
end;
procedure WriteWCharsFromPtr(p: PWideChar; count: Integer);
begin
  if (p <> nil) and (count > 0) then m_File.WriteBuffer(p^, 2 * count);
end;

// ---------------- CIntList ----------------
procedure ListClear; begin m_TemplCount := 0; end;
procedure ListAdd(v: Integer); begin if m_TemplCount < 4096 then begin m_Templates[m_TemplCount] := v; Inc(m_TemplCount); end; end;
function ListFind(v: Integer): Integer;
var i: Integer;
begin
  for i := 0 to m_TemplCount - 1 do if m_Templates[i] = v then Exit(i);
  Result := -1;
end;

// ---------------- matrix helpers ----------------
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
  if (dx * dx + dy * dy) = 0.0 then Exit(False);
  di := (x * dx + y * dy) / (dx * dx + dy * dy);
  if di < 0.0 then di := 0.0 else if di > 1.0 then di := 1.0;
  dx := x - di * dx; dy := y - di * dy;
  di := dx * dx + dy * dy;
  Result := di < MAX_LINE_ERROR;
end;

// ---------------- text reconstruction ----------------
procedure AddText;
var
  i, textDir: Integer;
  x1, x2, y1, y2, x3, y3, distance, spaceWidth, spw: Double;
  m: TCTM;
  recs: TTextRecordWPtr;
begin
  x1 := 0.0; y1 := 0.0;
  x2 := 0.0; y2 := m_Stack.FontSize;
  m := MulMatrix(m_Stack.ctm, m_Stack.tm);
  Transform(m, x1, y1);
  Transform(m, x2, y2);
  if y1 = y2 then
  begin
    if x1 > x2 then textDir := (1 + 1) * 2 else textDir := (0 + 1) * 2;
  end
  else
  begin
    if y1 > y2 then textDir := 1 else textDir := 0;
  end;

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
    x3 := m_Stack.SpaceWidth; y3 := 0.0;
    Transform(m, x3, y3);
    spaceWidth := CalcDistance(x1, y1, x3, y3);
    distance := CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
    if distance > spaceWidth then WriteWStr(' ');
  end;

  spw := -m_Stack.SpaceWidth * 0.5;
  recs := m_Stack.Kerning;
  for i := 0 to Integer(m_Stack.KerningCount) - 1 do
  begin
    if recs[i].Advance < spw then WriteWStr(' ');
    WriteWCharsFromPtr(recs[i].Text, recs[i].Length);
  end;

  m_LastTextEndX := m_Stack.TextWidth + spw;   // spw is negative
  m_LastTextEndY := 0.0;
  m_LastTextDir := textDir;
  Transform(m, m_LastTextEndX, m_LastTextEndY);
end;

procedure ParseText;
var haveMore: Boolean;
begin
  haveMore := m_PDF.GetPageText(m_Stack);
  if (not haveMore) and (m_Stack.TextLen = 0) then Exit;
  AddText;
  if haveMore then
    while m_PDF.GetPageText(m_Stack) do AddText;
end;

procedure ParseTemplates;
var i, j, tmpl, tmplCount, tmplCount2: Integer;
begin
  tmplCount := m_PDF.GetTemplCount;
  for i := 0 to tmplCount - 1 do
  begin
    if not m_PDF.EditTemplate(i) then Exit;
    tmpl := m_PDF.GetTemplHandle;
    if ListFind(tmpl) < 0 then
    begin
      ListAdd(tmpl);
      if not m_PDF.InitStack(m_Stack) then Exit;
      ParseText;
      tmplCount2 := m_PDF.GetTemplCount;
      for j := 0 to tmplCount2 - 1 do ParseTemplates;
      m_PDF.EndTemplate;
    end
    else
      m_PDF.EndTemplate;
  end;
end;

procedure ParsePage;
var em: PAnsiChar;
begin
  ListClear;
  if not m_PDF.InitStack(m_Stack) then
  begin
    em := m_PDF.GetErrorMessage;
    if em <> nil then Writeln(string(AnsiString(em)));
    Exit;
  end;
  m_LastTextEndX := 0.0; m_LastTextEndY := 0.0;
  m_LastTextDir := tfNotInitialized;
  m_LastTextInfX := 0.0; m_LastTextInfY := 0.0;
  ParseText;
  ParseTemplates;
end;

var
  i, cnt: Integer;
  bom: array[0..1] of Byte;
  prefix: UnicodeString;
begin
  m_PDF := TPDF.Create;
  try
    m_PDF.CreateNewPDFA('');
    m_PDF.SetOnErrorProc(nil, @ErrProc);

    m_PDF.SetCMapDirA('CMap', lcmRecursive or lcmDelayed);

    m_PDF.SetImportFlags(ifImportAll or ifImportAsPage);
    if m_PDF.OpenImportFileA('in.pdf', ptOpen, '') < 0 then Exit;
    m_PDF.ImportPDFFile(1, 1.0, 1.0);
    m_PDF.CloseImportFile;

    m_PDF.FlattenAnnots(affMarkupAnnots);
    m_PDF.FlattenForm;

    m_File := TFileStream.Create('out.txt', fmCreate);
    try
      bom[0] := $FF; bom[1] := $FE;
      m_File.WriteBuffer(bom, 2);

      cnt := m_PDF.GetPageCount;
      for i := 1 to cnt do
      begin
        m_PDF.EditPage(i);
        if i > 1 then prefix := #13#10 else prefix := '';
        WriteWStr(prefix + '%----------------------- Page ' + IntToStr(i) +
                  ' -----------------------------'#13#10);
        ParsePage;
        m_PDF.EndPage;
      end;
    finally
      m_File.Free;
    end;

    Writeln('Text successfully extracted to out.txt');
  finally
    m_PDF.Free;
  end;
end.
