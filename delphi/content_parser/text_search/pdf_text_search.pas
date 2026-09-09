unit pdf_text_search;

interface

uses Classes, SysUtils, LumasPdfApi;

const MAX_LINE_ERROR: Double = 4.0; // This must be the square of the allowed error (2 * 2 in this case).

type TTextDir =
(
   tfLeftToRight    = 0,
   tfRightToLeft    = 1,
   tfTopToBottom    = 2,
   tfBottomToTop    = 4,
   tfNotInitialized = 5
);

type TGState = record
   ActiveFont:   Pointer;
   CharSpacing:  Single;
   FontSize:     Single;
   FontType:     TFontType;
   Matrix:       TCTM;
   SpaceWidth:   Single;
   TextDrawMode: TDrawMode;
   TextScale:    Single;
   WordSpacing:  Single;
end;

type CStack = class(TObject)
  public
   function Restore(var F: TGState): Boolean;
   function Save(var F: TGState): Integer;
  private
   m_Capacity: Cardinal;
   m_Count:    Cardinal;
   m_Items:    Array of TGState;
end;

type CTextSearch = class(TObject)
  public
   constructor Create(const PDFInst: TPDF);
   destructor  Destroy(); override;
   function  BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
   procedure EndTemplate();
   function  GetSelCount(): Cardinal;
   procedure Init();
   function  MarkText(var Matrix: TCTM; const Source: TTextRecordAPtr; Count: Cardinal; Width: Double): Integer;
   procedure MultiplyMatrix(var Matrix: TCTM);
   function  RestoreGState(): Boolean;
   function  SaveGState(): Integer;
   procedure SetCharSpacing(Value: Double);
   procedure SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
   procedure SetSearchText(Text: WideString);
   procedure SetTextDrawMode(Mode: TDrawMode);
   procedure SetTextScale(Value: Double);
   procedure SetWordSpacing(Value: Double);
  protected
   m_EndX1:         Double;
   m_EndY1:         Double;
   m_EndX4:         Double;
   m_EndY4:         Double;
   m_GState:        TGState;
   m_HavePos:       Boolean;
   m_LastTextDir:   TTextDir;
   m_LastTextInfX:  Double;
   m_LastTextInfY:  Double;
   m_OutBuf:        Array[0..31] of WideChar;
   m_PDF:           TPDF;
   m_Stack:         CStack;
   m_SearchPos:     PWideChar;
   m_SearchText:    PWideChar;
   m_SearchTextLen: Cardinal;
   m_SelCount:      Cardinal;
   m_x1:            Double;
   m_y1:            Double;
   m_x4:            Double;
   m_y4:            Double;
   function  CalcDistance(x1, y1, x2, y2: Double): Double;
   function  Compare(Text: PWideChar; Len: Integer): Boolean;
   function  DrawRect(var Matrix: TCTM; EndX: Double): Boolean;
   function  DrawRectEx(x2, y2, x3, y3: Double): Boolean;
   procedure InitGState();
   function  IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
   function  MarkSubString(var x: Double; var Matrix: TCTM; const Source: TTextRecordAPtr): Boolean;
   function  MulMatrix(var M1, M2: TCTM): TCTM;
   procedure Reset();
   procedure SetStartCoord(var Matrix: TCTM; x: Double);
   procedure Transform(var M: TCTM; var x, y: Double);
end;

implementation

{ CTextSearch }

function CTextSearch.BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
begin
   if SaveGState() < 0 then begin
      Result := -1;
      Exit;
   end;
   if Matrix <> nil then begin
      m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix^);
   end;
   Result := 0;
end;

function CTextSearch.CalcDistance(x1, y1, x2, y2: Double): Double;
var dx, dy: Double;
begin
   dx := x2-x1;
   dy := y2-y1;
   Result := sqrt(dx*dx + dy*dy);
end;

function CTextSearch.Compare(Text: PWideChar; Len: Integer): Boolean;
var endPtr: PWideChar;
begin
   endPtr := Text + Len;
   while Text < endPtr do begin
      if m_SearchPos^ <> Text^ then begin
         m_HavePos   := false;
         m_SearchPos := m_SearchText;
         Result      := false;
         Exit;
      end;
      Inc(Text);
      Inc(m_SearchPos);
      if m_SearchPos^ = #0 then begin
         m_SearchPos := m_SearchText;
         Result := (Text = endPtr);
         Exit;
      end;
   end;
   Result := true;
end;

constructor CTextSearch.Create(const PDFInst: TPDF);
begin
   m_GState.ActiveFont   := nil;
   m_GState.CharSpacing  := 0.0;
   m_GState.FontSize     := 1.0;
   m_GState.FontType     := ftType1;
   m_GState.Matrix.a     := 1.0;
   m_GState.Matrix.b     := 0.0;
   m_GState.Matrix.c     := 0.0;
   m_GState.Matrix.d     := 1.0;
   m_GState.Matrix.x     := 0.0;
   m_GState.Matrix.y     := 0.0;
   m_GState.TextDrawMode := dmNormal;
   m_GState.TextScale    := 100.0;
   m_GState.WordSpacing  := 0.0;
   m_PDF                 := PDFInst;
   m_Stack := CStack.Create;
end;

destructor CTextSearch.Destroy;
begin
   if m_SearchText <> nil then FreeMem(m_SearchText);
   if m_Stack <> nil then m_Stack.Free;
   inherited;
end;

function CTextSearch.DrawRect(var Matrix: TCTM; EndX: Double): Boolean;
var x2, x3, y2, y3: Double;
begin
   // Note that the start and end coordinate can use different transformation matrices
   x2 := EndX;
   y2 := 0.0;
   x3 := EndX;
   y3 := m_GState.FontSize;
   Transform(Matrix, x2, y2);
   Transform(Matrix, x3, y3);
   Result := DrawRectEx(x2, y2, x3, y3);
end;

function CTextSearch.DrawRectEx(x2, y2, x3, y3: Double): Boolean;
begin
   m_PDF.MoveTo(m_x1, m_y1);
   m_PDF.LineTo(x2, y2);
   m_PDF.LineTo(x3, y3);
   m_PDF.LineTo(m_x4, m_y4);
   m_HavePos := false;
   Inc(m_SelCount);
   Result := m_PDF.ClosePath(fmFill);
end;

procedure CTextSearch.EndTemplate;
begin
   RestoreGState();
end;

function CTextSearch.GetSelCount: Cardinal;
begin
   Result := m_SelCount;
end;

procedure CTextSearch.Init;
begin
   InitGState();
   Reset();
   m_SelCount := 0;
end;

procedure CTextSearch.InitGState;
begin
   while RestoreGState() do;
   m_GState.ActiveFont   := nil;
   m_GState.CharSpacing  := 0.0;
   m_GState.FontSize     := 1.0;
   m_GState.Matrix.a     := 1.0;
   m_GState.Matrix.b     := 0.0;
   m_GState.Matrix.c     := 0.0;
   m_GState.Matrix.d     := 1.0;
   m_GState.Matrix.x     := 0.0;
   m_GState.Matrix.y     := 0.0;
   m_GState.SpaceWidth   := 0.0;
   m_GState.TextDrawMode := dmNormal;
   m_GState.TextScale    := 100.0;
   m_GState.WordSpacing  := 0.0;

   m_LastTextDir         := tfNotInitialized;
   m_LastTextInfX        := 0.0;
   m_LastTextInfY        := 0.0;
end;

function CTextSearch.IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
var dx, dy, di: Double;
begin
   x  := x - x0;
   y  := y - y0;
   dx := x1 - x0;
   dy := y1 - y0;
   di := (x*dx + y*dy) / (dx*dx + dy*dy);
   if  di < 0.0 then
      di := 0.0
   else if di > 1.0 then
      di := 1.0;
   dx := x - di * dx;
   dy := y - di * dy;
   di := dx*dx + dy*dy;
   Result := (di < MAX_LINE_ERROR);
end;

function CTextSearch.MarkSubString(var x: Double; var Matrix: TCTM; const Source: TTextRecordAPtr): Boolean;
var i, max, outlen: Integer; src: PAnsiChar; decoded: LongBool; spaceWidth2: Single; w: Double;
begin
   Result := false;
   i := 0;
   spaceWidth2 := -m_GState.SpaceWidth * 6.0;
   max := Source.Length;
   src := Source.Text;
   if Source.Advance < -m_GState.SpaceWidth then begin
      // If the distance is too large then we assume that no space was emulated at this position.
      if (Source.Advance > spaceWidth2) and (m_SearchPos^ = #32) then begin
         if not m_HavePos then begin
            SetStartCoord(Matrix, x);
            Inc(m_SearchPos);
            if m_SearchPos^ = #0 then begin
               if not DrawRect(Matrix, x - Source.Advance) then Exit;
               Reset();
            end;
         end else if m_SearchPos^ = #0 then begin
            if not DrawRect(Matrix, 0.0) then Exit;
            Reset();
         end else
            Inc(m_SearchPos);
      end else
         Reset();
   end;
   x := x - Source.Advance;
   outLen := 0;
   while i < max do begin
      Inc(i, m_PDF.TranslateRawCode(m_GState.ActiveFont, src + i, max - i, w, m_OutBuf, outLen, decoded, m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale));
      // We skip this text record if the text cannot be converted to Unicode. The return value must be TRUE,
      // otherwise we would break processing.
      if not decoded then begin
         Result := true;
         Exit;
      end;
      // outLen is always greater zero if decoded is true!
      if Compare(m_OutBuf, outLen) then begin
         if not m_HavePos then begin
            SetStartCoord(Matrix, x);
         end;
         x := x + w;
         if m_SearchPos = m_SearchText then begin
            if not DrawRect(Matrix, x - m_GState.CharSpacing) then Exit;
         end;
      end else
         x := x + w;
   end;
   Result := true;
end;

function CTextSearch.MarkText(var Matrix: TCTM; const Source: TTextRecordAPtr; Count: Cardinal; Width: Double): Integer;
var i: Integer; x, x1, x2, x3, y1, y2, y3, distance, spaceWidth: Double; textDir: TTextDir; m: TCTM; rec: TTextRecordAPtr;
begin
   Result := -1;
   x1 := 0.0;
   y1 := 0.0;
   x2 := 0.0;
   y2 := m_GState.FontSize;
   // Transform the text matrix to user space
   m := MulMatrix(m_GState.Matrix, Matrix);
   // Start point of the text record
   Transform(m, x1, y1);
   // The second point to determine the text direction can also be used to calculate
   // the visible font size measured in user space:
      // realFontSize := CalcDistance(x1, y1, x2, y2);
   Transform(m, x2, y2);
   // Determine the text direction
   if y1 = y2 then
      textDir := TTextDir((Cardinal(x1 > x2) + 1) shl 1)
   else
      textDir := TTextDir(y1 > y2);

   // Wrong direction or not on the same text line?
   if (textDir <> m_LastTextDir) or not IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY) then begin
      // Extend the x-coordinate to an infinite point.
      m_LastTextInfX := 1000000.0;
      m_LastTextInfY := 0.0;
      Transform(m, m_LastTextInfX, m_LastTextInfY);
      Reset();
   end else begin
      // The space width is measured in text space but the distance between two text
      // records is measured in user space! We must transform the space width to user
      // space before we can compare the values.
      // Note that we use the full space width here because the end position of the last record
      // was set to the record width minus the half space width.
      x3 := m_GState.SpaceWidth;
      y3 := 0.0;
      Transform(m, x3, y3);
      spaceWidth := CalcDistance(x1, y1, x3 ,y3);
      distance   := CalcDistance(m_EndX1, m_EndY1, x1, y1);
      if distance > spaceWidth then begin
         // If the distance is too large then we assume that no space was emulated at this position.
         if (distance < spaceWidth * 6.0) and (m_SearchPos^ = #32) then begin
            if not m_HavePos then begin
               // The start coordinate is the end coordinate of the last text record.
               m_HavePos := true;
               Inc(m_SearchPos);
               if m_SearchPos^ = #0 then begin
                  m_x1 := m_EndX1;
                  m_y1 := m_EndY1;
                  m_x4 := m_EndX4;
                  m_y4 := m_EndY4;
                  if not DrawRectEx(x1, y1, x2, y2) then Exit;
                  Reset();
               end;
            end else if m_SearchPos^ = #32 then begin
               if not DrawRectEx(x1, y1, x2, y2) then Exit;
               Reset();
            end else begin
               Inc(m_SearchPos);
            end;
         end else begin
            Reset();
         end;
      end;
   end;
   x := 0.0;
   rec := Source;
   for i := 0 to Count - 1 do begin
      if not MarkSubString(x, m, rec) then Exit;
      Inc(rec);
   end;
   m_LastTextDir := textDir;
   m_EndX1 := Width;
   m_EndY1 := 0.0;
   m_EndX4 := 0.0;
   m_EndY4 := m_GState.FontSize;
   Transform(m, m_EndX1, m_EndY1);
   Transform(m, m_EndX4, m_EndY4);
   Result := 0;
end;

procedure CTextSearch.MultiplyMatrix(var Matrix: TCTM);
begin
   m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix);
end;

function CTextSearch.MulMatrix(var M1, M2: TCTM): TCTM;
begin
   Result.a := M2.a * M1.a + M2.b * M1.c;
   Result.b := M2.a * M1.b + M2.b * M1.d;
   Result.c := M2.c * M1.a + M2.d * M1.c;
   Result.d := M2.c * M1.b + M2.d * M1.d;
   Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
   Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

procedure CTextSearch.Reset;
begin
   m_HavePos   := false;
   m_SearchPos := m_SearchText;
end;

function CTextSearch.RestoreGState: Boolean;
begin
   Result := m_Stack.Restore(m_GState);
end;

function CTextSearch.SaveGState: Integer;
begin
   Result := m_Stack.Save(m_GState);
end;

procedure CTextSearch.SetCharSpacing(Value: Double);
begin
   m_GState.CharSpacing := Value;
end;

procedure CTextSearch.SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
begin
   m_GState.ActiveFont := IFont;
   m_GState.FontSize   := FontSize;
   m_GState.FontType   := FontType;
   m_GState.SpaceWidth := m_PDF.GetSpaceWidth(IFont, FontSize) * 0.5;
end;

procedure CTextSearch.SetSearchText(Text: WideString);
var i, len: Integer;
begin
   len := Length(Text);
   GetMem(m_SearchText, (len + 1) * sizeof(WideChar));
   for i := 0 to len -1 do
      m_SearchText[i] := Text[i+1];
   m_SearchText[len] := WideChar(0);
end;

procedure CTextSearch.SetStartCoord(var Matrix: TCTM; x: Double);
begin
   m_x1 := x;
   m_y1 := 0.0;
   m_x4 := x;
   m_y4 := m_GState.FontSize;
   Transform(Matrix, m_x1, m_y1);
   Transform(Matrix, m_x4, m_y4);
   m_HavePos := true;
end;

procedure CTextSearch.SetTextDrawMode(Mode: TDrawMode);
begin
   m_GState.TextDrawMode := Mode;
end;

procedure CTextSearch.SetTextScale(Value: Double);
begin
   m_GState.TextScale := Value;
end;

procedure CTextSearch.SetWordSpacing(Value: Double);
begin
   m_GState.WordSpacing := Value;
end;

procedure CTextSearch.Transform(var M: TCTM; var x, y: Double);
var tx: Double;
begin
   tx := x;
   x  := tx * M.a + y * M.c + M.x;
   y  := tx * M.b + y * M.d + M.y;
end;

{ CStack }

function CStack.Restore(var F: TGState): Boolean;
begin
   if m_Count > 0 then begin
      Dec(m_Count);
      F := m_Items[m_Count];
      Result := true;
   end else
      Result := false;
end;

function CStack.Save(var F: TGState): Integer;
begin
   if m_Count = m_Capacity then begin
      Inc(m_Capacity, 28);
      try
         SetLength(m_Items, m_Capacity);
      except
         Dec(m_Capacity, 28);
         Result := -1;
         Exit;
      end;
   end;
   m_Items[m_Count] := F;
   Inc(m_Count);
   Result := 0;
end;

end.

