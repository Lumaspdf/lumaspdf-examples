unit pdf_to_text;

interface

uses Classes, Math, SysUtils, LumasPdfApi;

{
	This class uses the function GetPageText() to extract the text of a PDF file.
	It demonstrates how text lines and word boundaries can be identified. The
	algorithm handles rotated text as well as text lines which consist of multiple
	text records correctly.

	The identification of text lines and word boundaries is very important if
	you want to develop a text search or text replacement algorithm.

	The function GetPageText() should normally be used to replace or delete certain
	texts of a page. Take a look into the example edit_text to determine how texts
	can be replaced. Since the demo class CPDFEditText is already rather complex it
	is easier to understand how text lines can be constructed with a smaller example.

	GetPageText() uses internally the content parser of DynaPDF. If you just want to
	extract the contents of a PDF file it is better to use the content parser directly
	because it is faster in comparison to GetPageText(). Take a look into the
	examples text_extraction2 or text_search to determine how it can be used. However,
	it is currently not possible to combine the content parser with editing functions.
}

type TTextDir =
(
   tfLeftToRight    = 0,
   tfRightToLeft    = 1,
   tfTopToBottom    = 2,
   tfBottomToTop    = 4,
   tfNotInitialized = 5
);

// List to store template handles
type CIntList = class(TObject)
  private
   m_Capacity: Integer;
   m_Count:    Integer;
   m_Items:    Array of Integer;
  public
   destructor  Destroy(); override;
   procedure   Add(Value: Integer); 
   procedure   Clear();
   property    Count: Integer read m_Count;
   function    Find(Value: Integer): Integer;
   function    GetItem(Index: Cardinal): Integer;
end;

type CPDFToText = class(TObject)
 public
   constructor Create(const PDFInst: TPDF);
   destructor  Destroy(); override;
   procedure Close();
   procedure Open(const FileName: String);
   procedure ParsePage();
   procedure WritePageIdentifier(PageNum: Integer);
 protected
   m_File:         TFileStream;
   m_LastTextDir:  TTextDir;
   m_LastTextEndX: Double;
   m_LastTextEndY: Double;
   m_LastTextInfX: Double;
   m_LastTextInfY: Double;
   m_PDF:          TPDF;
   m_Stack:        TPDFStack;
   m_Templates:    CIntList;

   procedure AddText();
   function  CalcDistance(x1, y1, x2, y2: Double): Double;
   function  IsPointOnLine(x, y, x0, y0, x1, y1: Double): Boolean;
   function  MulMatrix(var M1, M2: TCTM): TCTM;
   procedure ParseTemplates();
   procedure ParseText();
   procedure Transform(var M: TCTM; var x, y: Double);
end;

implementation

{ CIntList }

procedure CIntList.Add(Value: Integer);
begin
	if m_Count = m_Capacity then begin
		SetLength(m_Items, m_Capacity + 64);
		Inc(m_Capacity, 64);
	end;
   m_Items[m_Count] := Value;
	Inc(m_Count);
end;

procedure CIntList.Clear;
begin
   m_Count := 0;
end;

destructor CIntList.Destroy;
begin
   m_Items := nil;
   inherited;
end;

function CIntList.Find(Value: Integer): Integer;
var i, e: Integer;
begin
   i := 0;
   e := m_Count - 1;
   while i <= e do begin
      if m_Items[i] = Value Then begin
         Result := i;
         Exit;
      end;
      if m_Items[e] = Value Then begin
         Result := e;
         Exit;
      end;
      Inc(i);
      Dec(e);
   end;
   Result := -1;
end;

function CIntList.GetItem(Index: Cardinal): Integer;
begin
   Result := m_Items[Index];
end;

{ CPDFToText }

const MAX_LINE_ERROR: Double = 4.0; // This must be the square of the allowed error (2 * 2 in this case).

procedure CPDFToText.AddText();
var i: Integer; x1, x2, x3, y1, y2, y3, distance, spaceWidth: Double; textDir: TTextDir; m: TCTM; rec: TTextRecordWPtr; spw: Single;
begin
   x1 := 0.0;
   y1 := 0.0;
   x2 := 0.0;
   y2 := m_Stack.FontSize;
   // Transform the text matrix to user space
   m := MulMatrix(m_Stack.ctm, m_Stack.tm);
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
      x3 := m_Stack.SpaceWidth;
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
   spw := -m_Stack.SpaceWidth * 0.5;
   rec := m_Stack.Kerning;
   for i := 0 to m_Stack.KerningCount - 1 do begin
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
   m_LastTextEndX := m_Stack.TextWidth + spw; // spw is a negative value!
   m_LastTextEndY := 0.0;
   m_LastTextDir  := textDir;
   // Calculate the end coordinate of the text record
   Transform(m, m_LastTextEndX, m_LastTextEndY);
end;

constructor CPDFToText.Create(const PDFInst: TPDF);
begin
   m_PDF := PDFInst;
   m_Templates := CIntList.Create;
end;

destructor CPDFToText.Destroy;
begin
  if m_File <> nil then m_File.Free;
  if m_Templates <> nil then m_Templates.Free;
  inherited;
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

function CPDFToText.MulMatrix(var M1, M2: TCTM): TCTM;
begin
   Result.a := M2.a * M1.a + M2.b * M1.c;
   Result.b := M2.a * M1.b + M2.b * M1.d;
   Result.c := M2.c * M1.a + M2.d * M1.c;
   Result.d := M2.c * M1.b + M2.d * M1.d;
   Result.x := M2.x * M1.a + M2.y * M1.c + M1.x;
   Result.y := M2.x * M1.b + M2.y * M1.d + M1.y;
end;

procedure CPDFToText.Open(const FileName: String);
begin
   m_File := TFileStream.Create(FileName, fmCreate);
   m_File.Write(PAnsiChar(#255#254)^, 2);
end;

procedure CPDFToText.ParsePage;
begin
   m_Templates.Clear;
   if not m_PDF.InitStack(m_Stack) then raise Exception.Create(String(m_PDF.GetErrorMessage()));
   m_LastTextEndX := 0.0;
   m_LastTextEndY := 0.0;
   m_LastTextDir  := tfNotInitialized;
   m_LastTextInfX := 0.0;
   m_LastTextInfY := 0.0;

   ParseText();
   ParseTemplates();
end;

procedure CPDFToText.ParseTemplates;
var i, j, tmpl, tmplCount, tmplCount2: Integer;
begin
   tmplCount := m_PDF.GetTemplCount();
   for i := 0 to tmplCount - 1 do begin
      if not m_PDF.EditTemplate(i) then raise Exception.Create(String(m_PDF.GetErrorMessage()));
      tmpl := m_PDF.GetTemplHandle;
      if m_Templates.Find(tmpl) < 0 then begin
         m_Templates.Add(tmpl);

         if not m_PDF.InitStack(m_Stack) then raise Exception.Create(String(m_PDF.GetErrorMessage()));

         ParseText();

         tmplCount2 := m_PDF.GetTemplCount();
         for j := 0 to tmplCount2 -1 do begin
            ParseTemplates();
         end;
         m_PDF.EndTemplate;
      end else
         m_PDF.EndTemplate();
   end;
end;

procedure CPDFToText.ParseText;
var haveMore: Boolean;
begin
   // Get the first text record if any
   haveMore := m_PDF.GetPageText(m_Stack);
   // No text found?
   if not haveMore and (m_Stack.TextLen = 0) then Exit;
   AddText();
   if haveMore then begin
      while m_PDF.GetPageText(m_Stack) do begin
         AddText();
      end;
   end;
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

end.
 