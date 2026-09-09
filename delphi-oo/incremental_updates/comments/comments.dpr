program comments;
// Delphi OO example -- incremental update / annotation replies.
// Builds a file in memory, then re-loads it three times as an incremental update
// adding a reply annotation each pass.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  buf: TBytes;

procedure GrabBuffer(pdf: TPDF);
var
  p: PAnsiChar;
  sz: Cardinal;
begin
  sz := 0;
  p := pdf.GetBuffer(sz);
  if (p = nil) or (sz = 0) then Exit;
  SetLength(buf, sz);
  Move(p^, buf[0], sz);
  pdf.FreePDF;
end;

function CreateTestFile(pdf: TPDF): Boolean;
begin
  pdf.CreateNewPDFA('');
  pdf.SetPageCoords(Ord(pcTopDown));
  pdf.Append;
    pdf.SquareAnnotA(50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, 'Jim', 'Test', 'Just a test...');
  pdf.EndPage;
  if not pdf.CloseFile then Exit(False);
  GrabBuffer(pdf);
  Result := Length(buf) > 0;
end;

function LoadTestFile(pdf: TPDF): Boolean;
begin
  pdf.CreateNewPDFA('');
  pdf.SetImportFlags2(if2IncrementalUpd);
  if pdf.OpenImportBuffer(@buf[0], Length(buf), ptOpen, '') < 0 then Exit(False);
  Result := pdf.ImportPDFFile(1, 1.0, 1.0) > 0;
end;

function SaveFile(pdf: TPDF): Boolean;
begin
  if not pdf.CloseFile then Exit(False);
  GrabBuffer(pdf);
  Result := Length(buf) > 0;
end;

var
  pdf: TPDF;
  reply: Integer;
  dir, filePath: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    if not CreateTestFile(pdf) then Exit;

    if LoadTestFile(pdf) then
    begin
      reply := pdf.SetAnnotMigrationStateA(0, asCreateReply, 'Harry');
      pdf.SetAnnotStringA(reply, Ord(asContent), 'Hi Jim, your test annotation looks fine!');
      if SaveFile(pdf) then
        if LoadTestFile(pdf) then
        begin
          reply := pdf.SetAnnotMigrationStateA(reply, asCreateReply, 'Tommy');
          pdf.SetAnnotStringA(reply, Ord(asContent), 'Just a test whether I can reply to a reply...');
          if SaveFile(pdf) then
            if LoadTestFile(pdf) then
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
