program collections2;

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

      // We add a user defined field Index to the list so that we can sort it in every order we want.
      ef := pdf.CreateCollectionField(cisCustomNumber, 0, 'File index', 'Index', false, true);
      pdf.SetColSortField(ef, true);

      pdf.CreateCollectionField(cisFileName, 1, 'File name', '', true, true);
      // The creation date is documented in the PDF Reference and a valid field in a file specification
      // but Acrobat 8 ignores it. Maybe it works when the next update of Acrobat is available...
      //pdfCreateCollectionField(pdf, cisCreationDate, 4, 'Creation date', NULL, true, false);
      pdf.CreateCollectionField(cisSize, 2, 'File size', '', true, false);
      pdf.CreateCollectionField(cisModDate, 3, 'Modification date', '', true, false);

      ef := pdf.AttachFile('../../test_files/taxform.pdf', 'A PDF file...', true);
      pdf.SetColDefFile(ef); // This file is opened when viewing the file with Acrobat 8 or later
      pdf.CreateColItemNumber(ef, 'Index', 0.0, '');

      ef := pdf.AttachFile('../../test_files/fulltest.emf', 'An EMF file...', true);
      pdf.CreateColItemNumber(ef, 'Index', 1.0, '');

      ef := pdf.AttachFile('../../test_files/sample.txt', 'A text file...', true);
      pdf.CreateColItemNumber(ef, 'Index', 2.0, '');

      // Let's check whether the collection is valid.
      // We know that the collection is valid in this example, but when editing an imported collection
      // this function can be very helpful.
      pdf.CheckCollection();

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
