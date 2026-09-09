program multiple_signatures;
// Delphi OO example -- signs license.PDF four times using incremental updates.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  MOVEFILE_COPY_ALLOWED  = $2;
  MOVEFILE_WRITE_THROUGH = $8;

function GetTempFileNameA(lpPathName, lpPrefixString: PAnsiChar; uUnique: Cardinal; lpTempFileName: PAnsiChar): Cardinal; stdcall; external 'kernel32.dll' name 'GetTempFileNameA';
function MoveFileExA(lpExistingFileName, lpNewFileName: PAnsiChar; dwFlags: Cardinal): LongBool; stdcall; external 'kernel32.dll' name 'MoveFileExA';
function DeleteFileA(lpFileName: PAnsiChar): LongBool; stdcall; external 'kernel32.dll' name 'DeleteFileA';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function SignFile(pdf: TPDF; const InFileName, OutFileName, FieldName, Reason: AnsiString;
  PosX: Double; VisibleSignature: Boolean): Boolean;
var
  outName: AnsiString;
  tmp: array[0..299] of AnsiChar;
  sig: Integer;
  usedTemp: Boolean;
begin
  outName := OutFileName;
  usedTemp := False;
  if InFileName = OutFileName then
  begin
    if GetTempFileNameA('.', 'sig', 0, @tmp[0]) = 0 then Exit(False);
    outName := AnsiString(PAnsiChar(@tmp[0]));
    usedTemp := True;
  end;

  pdf.CreateNewPDFA(PAnsiChar(outName));
  pdf.SetLicenseKey('SigDemo');

  pdf.SetImportFlags2(if2IncrementalUpd);
  if pdf.OpenImportFileA(PAnsiChar(InFileName), ptOpen, '') < 0 then Exit(False);
  pdf.ImportPDFFile(1, 1.0, 1.0);

  if VisibleSignature then
  begin
    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.EditPage(1);
      sig := pdf.CreateSigField(PAnsiChar(FieldName), -1, PosX, 30.0, 180.0, 40.0);
      pdf.SetFieldBorderWidth(sig, 0.0);
    pdf.EndPage;
  end;

  Result := pdf.CloseAndSignFile('../../../test_files/test_cert.pfx', '123456', PAnsiChar(Reason), '');
  if Result and usedTemp then
  begin
    DeleteFileA(PAnsiChar(OutFileName));
    Result := MoveFileExA(PAnsiChar(outName), PAnsiChar(OutFileName), MOVEFILE_COPY_ALLOWED or MOVEFILE_WRITE_THROUGH);
  end;
end;

var
  pdf: TPDF;
  dir, filePath: string;
  fp: AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    filePath := dir + 'out.pdf';
    fp := AnsiString(filePath);

    if SignFile(pdf, '../../../../license.PDF', fp, 'Signature1', 'Test signature 1', 50.0, True) then
      if SignFile(pdf, fp, fp, 'Signature2', 'Test signature 2', 430.0, True) then
        if SignFile(pdf, fp, fp, '', 'Test signature 3', 0.0, False) then
          if SignFile(pdf, fp, fp, '', 'Test signature 4', 0.0, False) then
            Writeln('PDF file "' + filePath + '" successfully created!');
  finally
    pdf.Free;
  end;
end.
