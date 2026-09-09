unit pdf_text_coordinates;

interface

uses Vcl.Graphics, SysUtils, LumasPdfApi;

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

type CTextCoordinates = class(TObject)
  public
   constructor Create(const PDFInst: TPDF);
   destructor  Destroy(); override;
   function  BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
   procedure EndTemplate();
   procedure Init();
   function  MarkText(var Matrix: TCTM; const Source: TTextRecordAPtr; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: Boolean): Integer;
   procedure MultiplyMatrix(var Matrix: TCTM);
   function  RestoreGState(): Boolean;
   function  SaveGState(): Integer;
   procedure SetCharSpacing(Value: Double);
   procedure SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
   procedure SetTextDrawMode(Mode: TDrawMode);
   procedure SetTextScale(Value: Double);
   procedure SetWordSpacing(Value: Double);
  protected
   m_Count:        Cardinal;
   m_GState:       TGState;
   m_PDF:          TPDF;
   m_Stack:        CStack;

   function  MulMatrix(var M1, M2: TCTM): TCTM;
   procedure Transform(var M: TCTM; var x, y: Double);
end;

implementation

{ CTextCoordinates }

function CTextCoordinates.BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
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

constructor CTextCoordinates.Create(const PDFInst: TPDF);
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
   m_Stack               := CStack.Create;
end;

destructor CTextCoordinates.Destroy;
begin
  if m_Stack <> nil then m_Stack.Free;
  inherited;
end;

procedure CTextCoordinates.EndTemplate;
begin
   RestoreGState();
end;

procedure CTextCoordinates.Init;
begin
   while RestoreGState() do;
   m_Count               := 0;
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
end;

function CTextCoordinates.MarkText(var Matrix: TCTM; const Source: TTextRecordAPtr; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: Boolean): Integer;
var i, j, last: Integer; x1, x2, y1, y2, textWidth: Double; m: TCTM; rec: TTextRecordWPtr; src: TTextRecordAPtr;
begin
   {
      This code draws lines under each text record of a PDF file to check whether the coordinates are correct.
      It shows also how word spacing must be handled. You need an algorithm like this one if you want to
      develop a text extraction algorithm that tries to preserve the original text layout. Note that word
      spacing must be ignored when a CID font is selected. In addition, word spacing is applied to the space
      character (32) of the non-translated source string only. The Unicode string cannot be used to determine
      whether word spacing must be applied because the character can be encoded to an arbitrary Unicode character.

      Note that we write lines to the page while we parsed it. This is critical because the parser
      doesn't notice when a fatal error occurs, e.g. out of memory. We must make sure that processing
      breaks immediatly in such a case. To archive this we check the return value of StrokePath() since
      the only reason why this function can fail is out of memory.
   }
   if not Decoded then begin
      Result := 0;
      Exit;
   end;
   Result := -1;
   try
      x1 := 0.0;
      y1 := 0.0;
      // Transform the text matrix to user space
      m := MulMatrix(m_GState.Matrix, Matrix);
      // Start point of the text record
      Transform(m, x1, y1);

      textWidth := 0.0;
      if m_GState.FontType = ftType0 then begin
         // Word spacing must be ignored if a CID font is selected!
         rec := Kerning;
         for i := 0 to Count - 1 do begin
            if rec.Advance <> 0.0 then begin
               textWidth := textWidth - rec.Advance;
               x1 := textWidth;
               y1 := 0.0;
               Transform(m, x1, y1);
            end;
            textWidth := textWidth + rec.Width;
            x2 := textWidth;
            y2 := 0.0;
            Transform(m, x2, y2);

            m_PDF.MoveTo(x1, y1);
            m_PDF.LineTo(x2, y2);
            if (m_Count and 1) <> 0 then
               m_PDF.SetStrokeColor(clRed)
            else
               m_PDF.SetStrokeColor(clBlue);
            if not m_PDF.StrokePath() then Exit;
            Inc(rec);
            x1 := x2;
            y1 := y2;
         end;
      end else begin
         // This code draws lines under line segments which are separated by one or more space characters. This is important
         // to handle word spacing correctly. The same code can be used to compute word boundaries of Ansi strings.
         src := Source;
         for i := 0 to Count - 1 do begin
            j    := 0;
            last := 0;
            if src.Advance <> 0.0 then begin
               textWidth := textWidth - src.Advance;
               x1 := textWidth;
               y1 := 0.0;
               Transform(m, x1, y1);
            end;
            while j < src.Length do begin
               if src.Text[j] <> #32 then
                  Inc(j)
               else begin
                  if j > last then begin
                     // Note that the text must be taken from the Source array!
                     textWidth := textWidth + m_PDF.GetTextWidth( m_GState.ActiveFont,
                                                                  src.Text + last,
                                                                  j - last,
                                                                  m_GState.CharSpacing,
                                                                  m_GState.WordSpacing,
                                                                  m_GState.TextScale);

                     x2 := textWidth;
                     y2 := 0.0;
                     Transform(m, x2, y2);
                     m_PDF.MoveTo(x1, y1);
                     m_PDF.LineTo(x2, y2);
                     if (m_Count and 1) <> 0 then
                        m_PDF.SetStrokeColor(clRed)
                     else
                        m_PDF.SetStrokeColor(clBlue);
                     if not m_PDF.StrokePath() then Exit;
                  end;
                  last := j;
                  Inc(j);
                  while (j < src.Length) and (src.Text[j] = #32) do Inc(j);
                  textWidth := textWidth + m_PDF.GetTextWidth( m_GState.ActiveFont,
                                                               src.Text + last,
                                                               j - last,
                                                               m_GState.CharSpacing,
                                                               m_GState.WordSpacing,
                                                               m_GState.TextScale);

                  last := j;
                  x1 := textWidth;
                  y1 := 0.0;
                  Transform(m, x1, y1);
               end;
            end;
            if j > last then begin
               textWidth := textWidth + m_PDF.GetTextWidth( m_GState.ActiveFont,
                                                            src.Text + last,
                                                            j - last,
                                                            m_GState.CharSpacing,
                                                            m_GState.WordSpacing,
                                                            m_GState.TextScale);

               x2 := textWidth;
               y2 := 0.0;
               Transform(m, x2, y2);
               m_PDF.MoveTo(x1, y1);
               m_PDF.LineTo(x2, y2);
               if (m_Count and 1) <> 0 then
                  m_PDF.SetStrokeColor(clRed)
               else
                  m_PDF.SetStrokeColor(clBlue);
               if not m_PDF.StrokePath() then Exit;
            end;
            Inc(src);
            x1 := x2;
            y1 := y2;
         end;
      end;
      Inc(m_Count);
      Result := 0;
   except
      on E: Exception do begin
         Writeln(E.Message);
         Result := -1;
      end;
   end;
end;

procedure CTextCoordinates.MultiplyMatrix(var Matrix: TCTM);
begin
   m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix);
end;

function CTextCoordinates.MulMatrix(var M1, M2: TCTM): TCTM;
begin
   Result.a := M2.a * M1.a + M2.b * M1.c;
   Result.b := M2.a * M1.b + M2.b * M1.d;
   Result.c := M2.c * M1.a + M2.d * M1.c;
   Result.d := M2.c * M1.b + M2.d * M1.d;
   Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
   Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

function CTextCoordinates.RestoreGState: Boolean;
begin
   Result := m_Stack.Restore(m_GState);
end;

function CTextCoordinates.SaveGState: Integer;
begin
   Result := m_Stack.Save(m_GState);
end;

procedure CTextCoordinates.SetCharSpacing(Value: Double);
begin
   m_GState.CharSpacing := Value;
end;

procedure CTextCoordinates.SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
begin
   m_GState.ActiveFont := IFont;
   m_GState.FontSize   := FontSize;
   m_GState.FontType   := FontType;
   m_GState.SpaceWidth := m_PDF.GetSpaceWidth(IFont, FontSize);
end;

procedure CTextCoordinates.SetTextDrawMode(Mode: TDrawMode);
begin
   m_GState.TextDrawMode := Mode;
end;

procedure CTextCoordinates.SetTextScale(Value: Double);
begin
   m_GState.TextScale := Value;
end;

procedure CTextCoordinates.SetWordSpacing(Value: Double);
begin
   m_GState.WordSpacing := Value;
end;

procedure CTextCoordinates.Transform(var M: TCTM; var x, y: Double);
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
