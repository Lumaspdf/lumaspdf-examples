program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{
   Note that the dynapdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure MergePDFFiles;
var i, destPage: Integer; first, haveXFA, isCollection: Boolean; pdf: TPDF; outFile: String; files: Array[0..1] of String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         pdf.SetFont('Helvetica', fsRegular, 14.0, false, cp1252);
         pdf.WriteFTextEx(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, taJustify,
             'The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that '
            +'all destinations refer to the new page numbers after import.'#13#13
            +'Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number '
            +'of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().');
      pdf.EndPage;

      first        := true;
      destPage     := 1;
      haveXFA      := false;
      isCollection := false;

      files[0] := '../../../license.pdf.';
      files[1] := '../../../dynapdf_help.pdf';

      // Generic code to merge arbitrary PDF files. 
      for i := 0 to 1 do begin
         if pdf.OpenImportFile(files[i], ptOpen, '') < 0 then begin
            pdf.Free;
            Exit;
         end;
         {
            Not all PDF files can be merged:
               - An Interactive Form is a global structure that cannot be simply merged. The names of all form fields must be
                 be unique. But also if name collusions will be solved, there is no guarantee that embedded Javascripts or Javascript
                 actions will work as expected. Interactive Forms should not be merged!

               - A PDF collection is a special PDF file that consists of a container PDF and an array of embedded files.
                 It is possible to merge two or more PDF Collections but it is not meaningful to merge a PDF Collection
                 with normal PDF files or vice versa.
         }
         if first then begin
            first        := false;
            haveXFA      := pdf.GetInIsXFAForm;
            isCollection := pdf.GetInIsCollection;
            destPage     := pdf.ImportPDFFile(destPage + 1, 1.0, 1.0);
            if destPage < 0 then break;
         end else begin
            // Special handling for PDF Collections
            if isCollection then begin
               if pdf.GetInIsCollection then begin
                  // Import the embedded files only
                  pdf.SetImportFlags(ifEmbeddedFiles);
                  // We could also use ImportPDFFile() but this function is more efficient since no pages will be imported.
                  if not pdf.ImportCatalogObjects then break;
               end else begin
                  pdf.CloseImportFile;
                  // Add the file to the collection
                  pdf.AttachFile(files[i], ExtractFileName(files[i]), true);
               end;
            end else begin
               if (pdf.GetInIsCollection or ((pdf.GetInIsXFAForm or (pdf.GetInFieldCount > 0)) and ((pdf.GetFieldCount > 0) or haveXFA))) then break;
               pdf.SetImportFlags(ifImportAll or ifImportAsPage); // Import anything and avoid the conversion of pages to templates
               pdf.SetImportFlags2(if2UseProxy);                  // This flag reduces the memory usage.
               destPage := pdf.ImportPDFFile(destPage + 1, 1.0, 1.0);
               if destPage < 0 then break;
            end;
         end;
         pdf.CloseImportFile;
      end;
      
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf.';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
         if pdf.CloseFile then begin
            Writeln(Format('PDF file "%s" successfully created!', [outFile]));
            ShellExecute(0, PChar('open'), PChar(OutFile), nil, nil, SW_SHOWMAXIMIZED);
         end;
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   MergePDFFiles;
end.
