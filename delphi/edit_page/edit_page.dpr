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
   Note that the LumasPdf.dll must be copied into the output directory or into a
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

procedure EditRotatedPage;
var f, orientation: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      // Import anything and don't convert pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../examples/test_files/rotated_270.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);
      pdf.CloseImportFile;
      
      pdf.SetPageCoords(pcTopDown);

      // This property moves the coordinate origin into the visible area (default value = false).
      pdf.SetUseVisibleCoords(true);

      // Open page 1 for editing
      pdf.EditPage(1);
         // Check whether the page is rotated.
         orientation := pdf.GetOrientation;
         if orientation <> 0 then begin
            // SetOrientationEx() rotates the coordinate system into the opposite direction of the page orientation.
            // There is no guarantee that the contents in a page is rotated in the same way. If the result is wrong
            // then don't call this function.
            pdf.SetOrientationEx(orientation);
         end;
         pdf.SetLeading(14.0);
         f := pdf.SetFont('Helvetica', fsRegular, 12.0, false, cp1252);
         // We use this font also as list font. In this example we use a bullet as list symbol (character index 144 of the code page 1252).
         //
         // Now it becomes complicated: Since modern Delphi versions uses Unicode as string format, WriteFTextEx() passes an Unicode string
         // to the classic API but the Unicode index of the bullet character is hex 2022 and not 144! If we would add the decimal number 8226 to the
         // string, then this number would be interpreted as the number of a numbered list.
         //
         // We have two options: Either we use WriteFTextExA() to output the text and add the decimal number 144 to the string, or we add the
         // Unicode character u2020 to the text and use WriteFTextEx() or WriteFTextExW(). We check whether Unicode is default and use the right
         // version.
         pdf.SetListFont(f);
         if pdf.UnicodeIsDefault then begin
            pdf.WriteFTextEx(50.0, 200.0, pdf.GetPageWidth - 100.0, -1.0, taJustify,
                'It is not difficult to edit an imported page but two things must be considered:'#13#13'\LI[20,'#$2022']\LD[16]The page''s '
               +'orientation.\EL#\LI[20,'#$2022']\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#'#13'\LD[12]'
               +'Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. LumasPDF moves the zero point then automatically '
               +'into the visible area of the page.'#13#13
               +'The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present.'#13#13
               +'The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated '
               +'into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.'#13#13
               +'However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was '
               +'not rotated. If this produces a wrong result then don''t call SetOrientationEx().'#13#13
               +'Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() '
               +'and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.');
         end else begin
            pdf.WriteFTextEx(50.0, 200.0, pdf.GetPageWidth - 100.0, -1.0, taJustify,
                'It is not difficult to edit an imported page but two things must be considered:'#13#13'\LI[20,144]\LD[16]The page''s '
               +'orientation.\EL#\LI[20,144]\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#'#13'\LD[12]'
               +'Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. LumasPDF moves the zero point then automatically '
               +'into the visible area of the page.'#13#13
               +'The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present.'#13#13
               +'The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated '
               +'into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.'#13#13
               +'However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was '
               +'not rotated. If this produces a wrong result then don''t call SetOrientationEx().'#13#13
               +'Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() '
               +'and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.');
         end;

      pdf.EndPage;
      
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
   EditRotatedPage;
end.
