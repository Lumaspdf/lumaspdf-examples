program comments;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC). No LumasPdf.dll.
// Creates a square annotation, then adds a chain of replies via incremental updates.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;

// Creates the base file in memory and returns a private copy of the PDF buffer.
function CreateTestFile(var buf: TBytes): Boolean;
var
  p: PAnsiChar;
  bufSize: Cardinal;
begin
  pdf.CreateNewPDFA('');
  pdf.SetPageCoords(Ord(pcTopDown));

  pdf.Append;
    pdf.SquareAnnotA(50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, 'Jim', 'Test', 'Just a test...');
  pdf.EndPage;

  if not pdf.CloseFile then Exit(False);
  p := pdf.GetBuffer(bufSize);
  if (p = nil) or (bufSize = 0) then Exit(False);
  SetLength(buf, bufSize);
  Move(p^, buf[0], bufSize);
  pdf.FreePDF;
  Result := True;
end;

function LoadTestFile(const buf: TBytes): Boolean;
begin
  pdf.CreateNewPDFA('');
  pdf.SetImportFlags2(if2IncrementalUpd);
  if pdf.OpenImportBuffer(@buf[0], Length(buf), ptOpen, '') < 0 then Exit(False);
  Result := pdf.ImportPDFFile(1, 1.0, 1.0) > 0;
end;

function SaveFile(var buf: TBytes): Boolean;
var
  p: PAnsiChar;
  bufSize: Cardinal;
begin
  if not pdf.CloseFile then Exit(False);
  p := pdf.GetBuffer(bufSize);
  if (p = nil) or (bufSize = 0) then Exit(False);
  SetLength(buf, bufSize);
  Move(p^, buf[0], bufSize);
  pdf.FreePDF;
  Result := True;
end;

var
  reply: Integer;
  buf: TBytes;
  dir, filePath: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);

    if not CreateTestFile(buf) then Exit;

    if LoadTestFile(buf) then
    begin
      reply := pdf.SetAnnotMigrationStateA(0, asCreateReply, 'Harry');
      pdf.SetAnnotStringA(reply, Ord(asContent), 'Hi Jim, your test annotation looks fine!');
      if SaveFile(buf) then
        if LoadTestFile(buf) then
        begin
          reply := pdf.SetAnnotMigrationStateA(reply, asCreateReply, 'Tommy');
          pdf.SetAnnotStringA(reply, Ord(asContent), 'Just a test whether I can reply to a reply...');
          if SaveFile(buf) then
            if LoadTestFile(buf) then
            begin
              reply := pdf.SetAnnotMigrationStateA(reply, asCreateReply, 'Jim');
              pdf.SetAnnotStringA(reply, Ord(asContent), 'Seems to work very well!');
              if pdf.HaveOpenDoc then
              begin
                filePath := dir + 'out.pdf';
                if pdf.OpenOutputFileA(PAnsiChar(AnsiString(filePath))) then
                  if pdf.CloseFile then
                    Writeln('PDF file "' + filePath + '" successfully created!');
              end;
            end;
        end;
    end;
  finally
    pdf.Free;
  end;
end.
