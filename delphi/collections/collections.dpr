program collections;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure TestCollection();
var ef: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.CreateNewPDF(''); // The output file is opened later
      pdf.SetOnErrorProc(nil, @ErrProc);
      // The page of this file is shown when opening the file with an older version of Adobe's Acrobat.
      // Otherwise, the default document of the collection is opened. Click on "Cover sheet" to view the
      // contents of this page.
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../test_files/collection_en.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Writeln('Input file "../../test_files/collection_en.pdf" not found!');
         ReadLn;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);
      pdf.CloseImportFile;
      pdf.CreateCollection(civTile);

      ef := pdf.AttachFile('../../test_files/taxform.pdf', 'A PDF file...', true);
      pdf.SetColDefFile(ef); // This file is opened when viewing the file Acrobat 8 or later
      pdf.AttachFile('../../test_files/fulltest.emf', 'An EMF file...', true);
      pdf.AttachFile('../../test_files/sample.txt', 'A text file...', true);

      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
      end;
      pdf.CloseFile;
      Writeln(Format('PDF Collection "%s" successfully created!', [outFile]));
      ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
end;

begin
   TestCollection;
end.
