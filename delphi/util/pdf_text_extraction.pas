unit pdf_text_extraction;

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

type CPDFToText = class(TObject)
  public
   constructor Create(const PDFInst: TPDF);
   destructor  Destroy(); override;
   function  AddText(var Matrix: TCTM; const Source: TTextRecordAPtr; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: Boolean): Integer;
   function  BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
   procedure Close();
   procedure EndTemplate();
   procedure Init();
   procedure MultiplyMatrix(var Matrix: TCTM);
   procedure Open(FileName: String);
   function  OpenEx(FileName: String): Boolean;
   function  RestoreGState(): Boolean;
   function  SaveGState(): Integer;
   procedure SetCharSpacing(Value: Double);
   procedure SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
   procedure SetTextDrawMode(Mode: TDrawMode);
   procedure SetTextScale(Value: Double);
   procedure SetWordSpacing(Value: Double);
   procedure WritePageIdentifier(PageNum: Integer);
  protected
   m_File:         TFileStream;
   m_GState:       TGState;
   m_LastTextDir:  TTextDir;
   m_LastTextEndX: Double;
   m_LastTextEndY: Double;
   m_LastTextInfX: Double;
   m_LastTextInfY: Double;
   m_PDF:          TPDF;
   m_Stack:        CStack;

   function  CalcDistance(x1, y1, x2, y2: Double): Double;
   function  IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
   function  MulMatrix(var M1, M2: TCTM): TCTM;
   procedure Transform(var M: TCTM; var x, y: Double);
end;

implementation

{ CPDFToText }

function CPDFToText.AddText(var Matrix: TCTM; const Source: TTextRecordAPtr; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: Boolean): Integer;
var i: Integer; x1, x2, x3, y1, y2, y3, distance, spaceWidth: Double; textDir: TTextDir; m: TCTM; rec: TTextRecordWPtr; spw: Single;
begin
   Result := 0;
   if not Decoded then Exit;
   try
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
      if (textDir <> m_LastTextDir) or not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY) then begin
         // Extend the x-coordinate to an infinite point.
         m_LastTextInfX := 1000000.0;
         m_LastTextInfY := 0.0;
         Transform(m, m_LastTextInfX, m_LastTextInfY);
         if m_LastTextDir <> tfNotInitialized then begin
            // Add a new line to the output file
            m_File.Write(PWideChar(WideString(#13#10))^, 4);
         end;
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
         distance   := CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
         if distance > spaceWidth then begin
            // Add a space to the output file
            m_File.Write(PWideChar(WideString(' '))^, 2);
         end;
      end;
      // We use the half space width to determine whether a space must be inserted at
      // a specific position. This produces better results in most cases.
      spw := -m_GState.SpaceWidth * 0.5;
      rec := Kerning;
      for i := 0 to Count - 1 do begin
         if rec.Advance < spw then begin
            // Add a space to the output file
            m_File.Write(PWideChar(WideString(' '))^, 2);
         end;
         // The Kerning array contains Unicode strings (two bytes per character)!
         m_File.Write(rec.Text^, rec.Length * 2);
         Inc(rec);
      end;
      // We don't set the cursor to the real end of the string because applications like MS Word
      // add often a space to the end of a text record and this space can slightly overlap the next
      // record. IsPointOnLine() would return false if the new record overlaps the previous one.
      m_LastTextEndX := Width + spw; // spw is a negative value!
      m_LastTextEndY := 0.0;
      m_LastTextDir  := textDir;
      // Calculate the end coordinate of the text record
      Transform(m, m_LastTextEndX, m_LastTextEndY);
   except
      on E: Exception do begin
         Writeln(E.Message);
         Result := -1;
      end;
   end;
end;

function CPDFToText.BeginTemplate(BBox: TPDFRect; Matrix: PCTM): Integer;
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

function CPDFToText.CalcDistance(x1, y1, x2, y2: Double): Double;
var dx, dy: Double;
begin
   dx := x2-x1;
   dy := y2-y1;
   Result := sqrt(dx*dx + dy*dy);
end;

procedure CPDFToText.Close;
begin
   m_File.Free;
   m_File := nil;
end;

constructor CPDFToText.Create(const PDFInst: TPDF);
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

destructor CPDFToText.Destroy;
begin
  if m_File  <> nil then m_File.Free;
  if m_Stack <> nil then m_Stack.Free;
  inherited;
end;

procedure CPDFToText.EndTemplate;
begin
   RestoreGState();
end;

procedure CPDFToText.Init;
begin
   while RestoreGState() do;
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
   m_LastTextDir         := tfNotInitialized;
   m_LastTextEndX        := 0.0;
   m_LastTextEndY        := 0.0;
   m_LastTextInfX        := 0.0;
   m_LastTextInfY        := 0.0;
end;

function CPDFToText.IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
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

procedure CPDFToText.MultiplyMatrix(var Matrix: TCTM);
begin
   m_GState.Matrix := MulMatrix(m_GState.Matrix, Matrix);
end;

function CPDFToText.MulMatrix(var M1, M2: TCTM): TCTM;
begin
   Result.a := M2.a * M1.a + M2.b * M1.c;
   Result.b := M2.a * M1.b + M2.b * M1.d;
   Result.c := M2.c * M1.a + M2.d * M1.c;
   Result.d := M2.c * M1.b + M2.d * M1.d;
   Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
   Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

procedure CPDFToText.Open(FileName: String);
begin
   // Make sure that this function is called within a try except block.
   m_File := TFileStream.Create(FileName, fmCreate);
   // Write a little endian marker to the file
   m_File.Write(PAnsiChar(#255#254)^, 2);
end;

function CPDFToText.OpenEx(FileName: String): Boolean;
begin
   Result := true;
   if m_File <> nil then m_File.Free;
   try
      m_File := TFileStream.Create(FileName, fmCreate);
      // Write a little endian marker to the file
      m_File.Write(PAnsiChar(#255#254)^, 2);
   except
      Result := false;
   end;
end;

function CPDFToText.RestoreGState: Boolean;
begin
   Result := m_Stack.Restore(m_GState);
end;

function CPDFToText.SaveGState: Integer;
begin
   Result := m_Stack.Save(m_GState);
end;

procedure CPDFToText.SetCharSpacing(Value: Double);
begin
   m_GState.CharSpacing := Value;
end;

procedure CPDFToText.SetFont(const IFont: Pointer; FontType: TFontType; FontSize: Double);
begin
   m_GState.ActiveFont := IFont;
   m_GState.FontSize   := FontSize;
   m_GState.FontType   := FontType;
   m_GState.SpaceWidth := m_PDF.GetSpaceWidth(IFont, FontSize);
   if FontSize < 0.0 then
   	m_GState.SpaceWidth := -m_GState.SpaceWidth;
end;

procedure CPDFToText.SetTextDrawMode(Mode: TDrawMode);
begin
   m_GState.TextDrawMode := Mode;
end;

procedure CPDFToText.SetTextScale(Value: Double);
begin
   m_GState.TextScale := Value;
end;

procedure CPDFToText.SetWordSpacing(Value: Double);
begin
   m_GState.WordSpacing := Value;
end;

procedure CPDFToText.Transform(var M: TCTM; var x, y: Double);
var tx: Double;
begin
   tx := x;
   x  := tx * M.a + y * M.c + M.x;
   y  := tx * M.b + y * M.d + M.y;
end;

procedure CPDFToText.WritePageIdentifier(PageNum: Integer);
var identifier: WideString;
begin
   if PageNum > 1 then begin
      // Add a new line to the output file
      m_File.Write(PWideChar(WideString(#13#10))^, 4);
   end;
   // Note that the page marker must be written as WideString. An Ansi string is automatically
   // converted to Unicode when passing it to a WideString variable.
   identifier := Format('%%----------------------- Page %d -----------------------------'#13#10, [PageNum]);
   m_File.Write(identifier[1], Length(identifier) * 2);
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
