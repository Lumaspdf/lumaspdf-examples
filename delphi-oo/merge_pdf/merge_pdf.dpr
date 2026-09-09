program merge_pdf;
// Delphi OO example -- merges two PDF files (with collection/XFA guards).
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  i: Integer;
  destPage: Integer;
  first, haveXFA, isCollection: Boolean;
  dir, outFile: string;
  files: array[0..1] of AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));

  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
      pdf.SetFontA('Helvetica', fsRegular, 14.0, False, cp1252);
      pdf.WriteFTextExA(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, taJustify,
        'The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that ' +
        'all destinations refer to the new page numbers after import.'#13#13 +
        'Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number ' +
        'of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().');
    pdf.EndPage;

    first := True;
    destPage := 1;
    haveXFA := False;
    isCollection := False;

    files[0] := AnsiString(dir + 'license.pdf');
    files[1] := AnsiString(dir + 'dynapdf_help.pdf');

    for i := 0 to 1 do
    begin
      if pdf.OpenImportFileA(PAnsiChar(files[i]), ptOpen, '') < 0 then Exit;
      if first then
      begin
        first := False;
        haveXFA := pdf.GetInIsXFAForm <> 0;
        isCollection := pdf.GetInIsCollection <> 0;
        destPage := pdf.ImportPDFFile(destPage + 1, 1.0, 1.0);
        if destPage < 0 then Break;
      end
      else
      begin
        if isCollection then
        begin
          if pdf.GetInIsCollection <> 0 then
          begin
            pdf.SetImportFlags(ifEmbeddedFiles);
            if not pdf.ImportCatalogObjects then Break;
          end
          else
          begin
            pdf.CloseImportFile;
            pdf.AttachFileA(PAnsiChar(files[i]), PAnsiChar(AnsiString(ExtractFileName(string(files[i])))), True);
          end;
        end
        else
        begin
          if (pdf.GetInIsCollection <> 0) or
             (((pdf.GetInIsXFAForm <> 0) or (pdf.GetInFieldCount > 0)) and
              ((pdf.GetFieldCount > 0) or haveXFA)) then
            Break;
          pdf.SetImportFlags(ifImportAll or ifImportAsPage);
          pdf.SetImportFlags2(if2UseProxy);
          destPage := pdf.ImportPDFFile(destPage + 1, 1.0, 1.0);
          if destPage < 0 then Break;
        end;
      end;
      pdf.CloseImportFile;
    end;

    if pdf.HaveOpenDoc then
    begin
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
      if pdf.CloseFile then
        Writeln('PDF file "' + outFile + '" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.
