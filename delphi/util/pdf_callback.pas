unit pdf_callBack;

interface

uses Windows, LumasPdfApi, pdf_text_extraction;

function  parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
procedure parseEndTemplate(const Data: Pointer); stdcall;
procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
function  parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
function  parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool; const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: Pointer); stdcall;
procedure parseSetTextDrawMode(const Data, PDFObject: Pointer; Mode: TDrawMode); stdcall;
procedure parseSetTextScale(const Data, PDFObject: Pointer; Value: Double); stdcall;
procedure parseSetWordSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
function  parseShowTextArrayW(const Data: Pointer; const Source: TTextRecordAPtr; var Matrix: TCTM; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: LongBool): Integer; stdcall;

implementation

function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
   Result := CPDFToText(Data).BeginTemplate(BBox, Matrix);
end;

procedure parseEndTemplate(const Data: Pointer); stdcall;
begin
   CPDFToText(Data).EndTemplate();
end;

procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
begin
   CPDFToText(Data).MultiplyMatrix(Matrix);
end;

function parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
begin
   CPDFToText(Data).RestoreGState();
   Result := 0;
end;

function parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
begin
   CPDFToText(Data).SaveGState();
   Result := 0;
end;

procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CPDFToText(Data).SetCharSpacing(Value);
end;

procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool; const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: Pointer); stdcall;
begin
   CPDFToText(Data).SetFont(Font, FontType, FontSize);
end;

procedure parseSetTextDrawMode(const Data, PDFObject: Pointer; Mode: TDrawMode); stdcall;
begin
   CPDFToText(Data).SetTextDrawMode(Mode);
end;

procedure parseSetTextScale(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CPDFToText(Data).SetTextScale(Value);
end;

procedure parseSetWordSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CPDFToText(Data).SetWordSpacing(Value);
end;

function parseShowTextArrayW(const Data: Pointer; const Source: TTextRecordAPtr; var Matrix: TCTM; const Kerning: TTextRecordWPtr; Count: Cardinal; Width: Double; Decoded: LongBool): Integer; stdcall;
begin
   Result := CPDFToText(Data).AddText(Matrix, Source, Kerning, Count, Width, Decoded);
end;

end.
 