program custom_provider;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\08_custom_provider.c -- custom in-memory data provider.
// Callbacks are NATIVE Delphi stdcall functions wired into a TRptProviderVTable.
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

const
  PDF_DEMO_KEY: AnsiString = 'LUMAS-LumasReportExamples-DD5D40E0';
  RPT_DEMO_KEY: AnsiString =
    'LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM' +
    '.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA';
  // value kinds
  vkNull  = 0;
  vkBool  = 1;
  vkInt   = 2;
  vkFloat = 3;
  vkDate  = 4;
  vkStr   = 5;

const
  mFieldName: array[0..4] of AnsiString = ('Id', 'Price', 'Name', 'Active', 'Note');
  mFieldKind: array[0..4] of Integer = (vkInt, vkFloat, vkStr, vkBool, vkStr);
  mRowId: array[0..3] of Integer = (1, 2, 3, 4);
  mPrice: array[0..3] of Double = (12.5, 9.99, 0.0, 47.75);
  mActive: array[0..3] of Integer = (1, 0, 1, 1);
  mHasNote: array[0..3] of Integer = (1, 1, 0, 1);
  mName: array[0..3] of AnsiString = ('Alpha', 'Beta', 'Gamma', 'Delta');
  mNote: array[0..3] of AnsiString = ('first', 'second', '', 'fourth');

var
  gPdf: TPDF; gRpt: TPDFReport;

procedure WriteText(const Path, Content: AnsiString);
var FS: TFileStream;
begin
  FS := TFileStream.Create(string(Path), fmCreate);
  try
    if Content <> '' then FS.WriteBuffer(Content[1], Length(Content));
  finally
    FS.Free;
  end;
end;

procedure DumpRptError(Eng: TRPT);
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) and (Info.Code <> 0) then
    Writeln(Format('  ! rpt error %d [%s] at %s: %s',
      [Info.Code, string(AnsiString(Info.Module_)), string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]));
end;

function BootEngine: Boolean;
var Eng: TRPT;
begin
  Result := False;
  gPdf := TPDF.Create;
  gPdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));
  gPdf.SetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));
  Eng := gPdf.CreateEngineA(nil);
  if Eng = nil then begin Writeln('rptCreateEngine failed:'); DumpRptError(nil); Exit; end;
  gRpt := TPDFReport.Create(Eng);
  Result := True;
end;

// --- provider callbacks (stdcall) ---
function MyOpen(U: Pointer; Conn, Query: PAnsiChar; Params: PRptCParam; NParams: Int32; out Cursor: Pointer): Int32; stdcall;
var p: PInteger;
begin
  New(p);
  p^ := -1;                 // row index before first Fetch
  Cursor := p;
  Result := 0;
end;

function MyGetSchema(Cursor: Pointer; Fields: PRptCFieldDef; MaxFields: Int32): Int32; stdcall;
var i, n: Integer; F: PRptCFieldDef;
begin
  n := 5;
  if n > MaxFields then n := MaxFields;
  for i := 0 to n - 1 do
  begin
    F := PRptCFieldDef(PByte(Fields) + i * SizeOf(TRptCFieldDef));
    FillChar(F^, SizeOf(F^), 0);
    Move(PAnsiChar(mFieldName[i])^, F^.Name[0], Length(mFieldName[i]));
    F^.Kind := mFieldKind[i];
  end;
  Result := n;
end;

function MyFetch(Cursor: Pointer): Int32; stdcall;
var p: PInteger;
begin
  p := PInteger(Cursor);
  Inc(p^);
  if p^ <= 3 then Result := 1 else Result := 0;
end;

function MyGetVal(Cursor: Pointer; Field: Int32; V: PRptCValue): Int32; stdcall;
var r: Integer;
begin
  r := PInteger(Cursor)^;
  FillChar(V^, SizeOf(V^), 0);
  V^.Kind := vkNull;
  case Field of
    0: begin V^.Kind := vkInt;   V^.I := mRowId[r]; end;
    1: begin V^.Kind := vkFloat; V^.F := mPrice[r]; end;
    2: begin V^.Kind := vkStr;   V^.S := PAnsiChar(mName[r]); end;
    3: begin V^.Kind := vkBool;  V^.B := mActive[r]; end;
    4: if mHasNote[r] = 0 then V^.Kind := vkNull
       else begin V^.Kind := vkStr; V^.S := PAnsiChar(mNote[r]); end;
  else
    V^.Kind := vkNull;
  end;
  Result := 0;
end;

procedure MyClose(Cursor: Pointer); stdcall;
begin
  if Cursor <> nil then Dispose(PInteger(Cursor));
end;

var
  Job: TPDFReportJob;
  vt: TRptProviderVTable;
  Lrpt, OutPdf, OutTxt, Xml: AnsiString;
begin
  Lrpt := '08_custom.lrpt'; OutPdf := '08_custom.pdf'; OutTxt := '08_custom.txt';

  if not BootEngine then Halt(1);

  FillChar(vt, SizeOf(vt), 0);
  vt.Open := MyOpen;
  vt.GetSchema := MyGetSchema;
  vt.Fetch := MyFetch;
  vt.GetVal := MyGetVal;
  vt.CloseC := MyClose;
  if not gRpt.RegisterProviderA('mydata', @vt, nil) then
  begin Writeln('register provider failed'); DumpRptError(gRpt.Handle); gRpt.DeleteEngine; gPdf.Free; Halt(0); end;

  Xml :=
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
  WriteText(Lrpt, Xml);

  Job := TPDFReportJob.Create(gRpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(gRpt.Handle); gRpt.DeleteEngine; gPdf.Free; Halt(0); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(gRpt.Handle); Job.CloseReport; gRpt.DeleteEngine; gPdf.Free; Halt(0); end;
  Writeln(Format('rendered %d page(s) from the custom provider', [Job.GetPageCount]));
  Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf));
  Job.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt));
  Writeln(Format('wrote %s  +  %s', [string(OutPdf), string(OutTxt)]));
  Job.CloseReport;

  gRpt.DeleteEngine;
  gPdf.Free;
end.
