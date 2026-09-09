program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure FreeAndNilMem(var Ptr: PByte);
begin
   if Ptr <> nil then begin
      FreeMem(Ptr);
      Ptr := nil;
   end;
end;

{
   Incremental updates are useful if small changes should be saved quickly, e.g. when adding an annotation or reply to one,
   adding form fields and so on.

   This example is a bit simplified since we know that the file contains only one annotation and a handle of an annotation
   is just an array index from 0 though annotation count -1.
}

function CreateTestFile(const PDF: TPDF; var BufSize: Cardinal): PByte;
var buffer: PAnsiChar;
begin
   Result := nil;
   PDF.CreateNewPDF('');
   PDF.SetPageCoords(pcTopDown);

   PDF.Append;
      PDF.SquareAnnot(50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, 'Jim', 'Test', 'Just a test...');
   PDF.EndPage;

   if not PDF.CloseFile then Exit;
   buffer := PDF.GetBuffer(BufSize);
   try
      GetMem(Result, BufSize);
      CopyMemory(Result, buffer, BufSize);
   finally
      // Now we can release the original buffer. This also resets the PDF instance,
      // just as CloseFile() would do if the file would be created on a local drive.
      PDF.FreePDF;
   end;
end;

function LoadTestFile(const PDF: TPDF; Buffer: PByte; BufSize: Cardinal): Boolean;
begin
   Result := false;
   PDF.CreateNewPDF('');
   // This flag also sets the flags ifImportAsPage | ifImportAll, and if2UseProxy | if2CopyEncryptDict to make sure that
   // anything is imported and nothing gets changed.
   PDF.SetImportFlags2(if2IncrementalUpd);
   if PDF.OpenImportBuffer(Buffer, BufSize, ptOpen, '') < 0 then Exit;
   Result := PDF.ImportPDFFile(1, 1.0, 1.0) > 0;
end;

function SaveFile(const PDF: TPDF; var BufSize: Cardinal): PByte;
var buffer: PAnsiChar;
begin
   Result := nil;
   if not PDF.CloseFile then Exit;
   buffer := PDF.GetBuffer(BufSize);
   // Note that the buffer is bound to the PDF instance.
   // We make a copy of it so that we can work with only one PDF instance
   try
      GetMem(Result, BufSize);
      CopyMemory(Result, buffer, BufSize);
   finally
      // Now we can release the original buffer. This also resets the PDF instance,
      // just as CloseFile() would do if the file would be created on a local drive.
      PDF.FreePDF;
   end;
end;

procedure TestComments;
var reply: Integer; pdf: TPDF; buffer: PByte; bufSize: Cardinal; filePath: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);

      // We create the base file in memory in this example
      buffer := CreateTestFile(pdf, bufSize);
      if buffer <> nil then begin
         // CreateTest() created a copy of the PDF buffer. We are now the owner of the buffer.
         // The PDF instance has now it's inital state with the exception that the font cache, if already loaded, stays in memory.
         if LoadTestFile(pdf, buffer, bufSize) then begin
            // We don't need the buffer anymore
            FreeAndNilMem(buffer);
            // We do not search for the annotation here since we know that the file contains only one annotation
            // and the handle of this annotation is zero since this is just an array index.
            reply := pdf.SetAnnotMigrationState(0, asCreateReply, 'Harry');
            pdf.SetAnnotString(reply, asContent, 'Hi Jim, your test annotation looks fine!');
            buffer := SaveFile(pdf, bufSize);
            if (buffer <> nil) and LoadTestFile(pdf, buffer, bufSize) then begin
               FreeAndNilMem(buffer);

               reply := pdf.SetAnnotMigrationState(reply, asCreateReply, 'Tommy');
               pdf.SetAnnotString(reply, asContent, 'Just a test whether I can reply to a reply...');
               buffer := SaveFile(pdf, bufSize);
               if (buffer <> nil) and LoadTestFile(pdf, buffer, bufSize) then begin
                  FreeAndNilMem(buffer);

                  reply := pdf.SetAnnotMigrationState(reply, asCreateReply, 'Jim');
                  pdf.SetAnnotString(reply, asContent, 'Seems to work very well!');
                  if pdf.HaveOpenDoc then begin
                     // We write the output file into the current directory.
                     GetDir(0, filePath);
                     filePath := filePath + '\out.pdf';
                     if pdf.OpenOutputFile(filePath) and pdf.CloseFile then begin
                        Writeln(Format('PDF file "%s" successfully created!\n', [filePath]));
                        ShellExecute(0, PChar('open'), PChar(filePath), nil, nil, SW_SHOWMAXIMIZED);
                     end;
                  end;
               end;
            end;
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
   TestComments;
end.
