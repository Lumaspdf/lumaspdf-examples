program custom_provider;
// ===========================================================================
//  LumasReport example 08 -- Custom data provider (pure Delphi, C-ABI vtable)
//  Covers: rptRegisterProvider + TRptProviderVTable (Open/GetSchema/Fetch/
//  GetVal/CloseC), TRptCFieldDef, TRptCValue and EVERY value kind
//  (null/bool/int/float/date/string). A report binds provider="mydata" and
//  renders a 4-row x 5-typed-column in-memory table -- no files, no DB.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

// Value-kind ordinals (TRptValueKind): 0=null 1=bool 2=int 3=float 4=date 5=str
const
  vkNull = 0; vkBool = 1; vkInt = 2; vkFloat = 3; vkDate = 4; vkStr = 5;

// ---- the in-memory table the provider serves --------------------------------
type
  TRow = record Id: Int64; Price: Double; Name: AnsiString; Active: Boolean; Note: AnsiString; end;
const
  ROWS: array[0..3] of TRow = (
    (Id: 1; Price: 12.50; Name: 'Alpha';   Active: True;  Note: 'first'),
    (Id: 2; Price:  9.99; Name: 'Beta';    Active: False; Note: 'second'),
    (Id: 3; Price:  0.00; Name: 'Gamma';   Active: True;  Note: ''),      // Note = NULL row
    (Id: 4; Price: 47.75; Name: 'Delta';   Active: True;  Note: 'fourth'));
  FIELD_NAME: array[0..4] of AnsiString = ('Id', 'Price', 'Name', 'Active', 'Note');
  FIELD_KIND: array[0..4] of Int32      = (vkInt, vkFloat, vkStr, vkBool, vkStr);

// A cursor is just a heap-allocated current-row index (-1 before first Fetch).
function MyOpen(U: Pointer; Conn, Query: PAnsiChar; Params: PRptCParam;
  NParams: Int32; out Cursor: Pointer): Int32; stdcall;
var P: PInteger;
begin
  New(P); P^ := -1; Cursor := P; Result := 0;   // 0 = success
end;

function MyGetSchema(Cursor: Pointer; Fields: PRptCFieldDef; MaxFields: Int32): Int32; stdcall;
var i, n, k: Integer; F: PRptCFieldDef; src: AnsiString;
begin
  n := Length(FIELD_NAME);
  if n > MaxFields then n := MaxFields;
  F := Fields;
  for i := 0 to n - 1 do
  begin
    FillChar(F^, SizeOf(TRptCFieldDef), 0);
    src := FIELD_NAME[i];                         // copy the NUL-terminated field name
    for k := 1 to Length(src) do
      if k <= 63 then F^.Name[k - 1] := src[k];
    F^.Kind := FIELD_KIND[i];
    Inc(F);
  end;
  Result := n;                                   // number of fields
end;

function MyFetch(Cursor: Pointer): Int32; stdcall;
begin
  Inc(PInteger(Cursor)^);
  if PInteger(Cursor)^ <= High(ROWS) then Result := 1 else Result := 0;  // 1=row 0=EOF
end;

// GetVal fills V by field index, exercising every value kind.
function MyGetVal(Cursor: Pointer; Field: Int32; V: PRptCValue): Int32; stdcall;
var r: Integer;
begin
  r := PInteger(Cursor)^;
  FillChar(V^, SizeOf(TRptCValue), 0);
  case Field of
    0: begin V^.Kind := vkInt;   V^.I := ROWS[r].Id; end;
    1: begin V^.Kind := vkFloat; V^.F := ROWS[r].Price; end;
    2: begin V^.Kind := vkStr;   V^.S := PAnsiChar(ROWS[r].Name); end;
    3: begin V^.Kind := vkBool;  if ROWS[r].Active then V^.B := 1 else V^.B := 0; end;
    4: if ROWS[r].Note = '' then V^.Kind := vkNull                 // demonstrate NULL
       else begin V^.Kind := vkStr; V^.S := PAnsiChar(ROWS[r].Note); end;
  else V^.Kind := vkNull;
  end;
  Result := 0;
end;

procedure MyClose(Cursor: Pointer); stdcall;
begin
  if Cursor <> nil then Dispose(PInteger(Cursor));
end;

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="CustomProvider" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="mydata" conn="" query=""/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="12">'#10 +
    '   <text name="t" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center" wordWrap="0">Custom Provider - typed rows</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="7">'#10 +
    '   <text name="h1" x="0"   y="0" w="20" h="5" fontSize="9" bold="1" wordWrap="0">Id</text>'#10 +
    '   <text name="h2" x="22"  y="0" w="40" h="5" fontSize="9" bold="1" wordWrap="0">Name</text>'#10 +
    '   <text name="h3" x="64"  y="0" w="30" h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Price</text>'#10 +
    '   <text name="h4" x="98"  y="0" w="24" h="5" fontSize="9" bold="1" wordWrap="0">Active</text>'#10 +
    '   <text name="h5" x="126" y="0" w="50" h="5" fontSize="9" bold="1" wordWrap="0">Note</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="c1" x="0"   y="0" w="20" h="5" fontSize="9" wordWrap="0">{{Id}}</text>'#10 +
    '   <text name="c2" x="22"  y="0" w="40" h="5" fontSize="9" wordWrap="0">{{Name}}</text>'#10 +
    '   <text name="c3" x="64"  y="0" w="30" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(''#,##0.00'', Price) }}</text>'#10 +
    '   <text name="c4" x="98"  y="0" w="24" h="5" fontSize="9" wordWrap="0">{{expr: CSTR(Active) }}</text>'#10 +
    '   <text name="c5" x="126" y="0" w="50" h="5" fontSize="9" wordWrap="0">{{expr: IFNULL(Note, ''(none)'') }}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB; VT: TRptProviderVTable;
  Dir, Lrpt, OutPdf, OutTxt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    // Register the custom provider (optional slots RewindC/RowCount/Exec/Tx = nil).
    FillChar(VT, SizeOf(VT), 0);
    VT.Open := MyOpen; VT.GetSchema := MyGetSchema; VT.Fetch := MyFetch;
    VT.GetVal := MyGetVal; VT.CloseC := MyClose;
    if not rptRegisterProvider(Eng, 'mydata', @VT, nil) then
      begin Writeln('register provider failed'); DumpRptError(Eng); Halt(2); end;

    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt := Dir + '08_custom.lrpt'; OutPdf := Dir + '08_custom.pdf'; OutTxt := Dir + '08_custom.txt';
    WriteText(Lrpt, REPORT_XML);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(3); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(4); end;
      Writeln(Format('rendered %d page(s) from the custom provider', [rptGetPageCount(Job)]));
      rptExportA(Job, RPT_EXP_PDF,  PAnsiChar(OutPdf));
      rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt));
      Writeln('wrote ' + string(OutPdf) + '  +  ' + string(OutTxt));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.
