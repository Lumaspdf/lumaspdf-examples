unit pdf_callBack;

interface

uses Windows, LumasPdfApi, pdf_text_search;

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
function  parseShowTextArrayA(const Data: Pointer; Obj: PAnsiChar; var Matrix: TCTM; const Source: TTextRecordAPtr; Count: Cardinal; Width: Double): Integer; stdcall;

implementation

function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
   Result := CTextSearch(Data).BeginTemplate(BBox, Matrix);
end;

procedure parseEndTemplate(const Data: Pointer); stdcall;
begin
   CTextSearch(Data).EndTemplate();
end;

procedure parseMulMatrix(const Data, PDFObject: Pointer; var Matrix: TCTM); stdcall;
begin
   CTextSearch(Data).MultiplyMatrix(Matrix);
end;

function parseRestoreGraphicState(const Data: Pointer): Integer; stdcall;
begin
   CTextSearch(Data).RestoreGState();
   Result := 0;
end;

function parseSaveGraphicState(const Data: Pointer): Integer; stdcall;
begin
   Result := CTextSearch(Data).SaveGState();
end;

procedure parseSetCharSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CTextSearch(Data).SetCharSpacing(Value);
end;

procedure parseSetFont(const Data, PDFObject: Pointer; FontType: TFontType; Embedded: LongBool; const FontName: PAnsiChar; Style: TFStyle; FontSize: Double; const Font: Pointer); stdcall;
begin
   CTextSearch(Data).SetFont(Font, FontType, FontSize);
end;

procedure parseSetTextDrawMode(const Data, PDFObject: Pointer; Mode: TDrawMode); stdcall;
begin
   CTextSearch(Data).SetTextDrawMode(Mode);
end;

procedure parseSetTextScale(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CTextSearch(Data).SetTextScale(Value);
end;

procedure parseSetWordSpacing(const Data, PDFObject: Pointer; Value: Double); stdcall;
begin
   CTextSearch(Data).SetWordSpacing(Value);
end;

function  parseShowTextArrayA(const Data: Pointer; Obj: PAnsiChar; var Matrix: TCTM; const Source: TTextRecordAPtr; Count: Cardinal; Width: Double): Integer;
begin
   Result := CTextSearch(Data).MarkText(Matrix, Source, Count, Width);
end;

end.

