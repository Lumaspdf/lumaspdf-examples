program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

function GetFileBuffer(FileName: String): WideString;
var strm: TFileStream;
begin
   strm   := nil;
   Result := '';
   try
      strm := TFileStream.Create(FileName, fmOpenRead);
      SetLength(Result, strm.Size div 2);
      strm.Read(Result[1], strm.Size);
   except
      if strm <> nil then strm.Free;
      Exit;
   end;
   strm.Free;
end;

procedure TestFontSubstitution;
var pdf: TPDF; txt: WideString; outFile: String;
begin
   pdf := nil;

   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @ErrProc);
      pdf.CreateNewPDF(''); // We create no PDF file in this example
      
      txt := GetFileBuffer('../../../test_files/multi_lang.txt');
      
      pdf.SetPageCoords(pcTopDown);
      // Enable complex text layout
      pdf.SetGStateFlags(gfComplexText, false);
      //pdf.SetBidiMode(bmRightToLeft);
      
      pdf.Append;

         // The font must be loaded with cpUnicode.
         pdf.SetFont('Arial', fsRegular, 10.0, true, cpUnicode);
         pdf.SetLeading(pdf.GetTypoLeading);
         // We call the wide version of WriteFTextEx() directly since overloaded string functions do not always work as expected with older Delphi versions.
         pdf.WriteFTextExW(50.0, 50.0, pdf.GetPageWidth - 100.0, pdf.GetPageHeight - 100.0, taJustify, txt);

         txt := '';

      pdf.EndPage;

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
      if pdf.CloseFile then begin
         Writeln(Format('PDF file "%s" successfully created!', [outFile]));
         ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   TestFontSubstitution;
end.
