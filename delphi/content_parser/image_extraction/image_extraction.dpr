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

var m_Images:    TList;
var m_Templates: TList;

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
   if (m_Templates.IndexOf(PInteger(Handle)) > -1) then begin
      Result := 1; // Skip the template
      Exit;
   end else begin
      try
         m_Templates.Add(PInteger(Handle));
      except
         Result := -1; // Break processing
         Exit;
      end;
      Result := 0; 
   end;
end;

function parseInsertImage(const Data: Pointer; var Image: TPDFImage): Integer; stdcall;
begin
   Result := 0;
   if Image.InlineImage = false then begin
      if m_Images.IndexOf(Image.ObjectPtr) > -1 then Exit;  // Already handled?
      try
         m_Images.Add(Image.ObjectPtr);
      except
         Result := -1; // Break processing
         Exit;
      end;
   end;
   // If an image cannot be decompressed due to an unsupported filter or if the decoder
   // failed to decompress it then we can get a compressed image here.
   if Image.Filter <> dfNone then Exit;
   // Note that Flate compression is no standard filter; Photoshop does not support this filter.
   if Image.BitsPerPixel = 1 then
      TPDF(Data).AddImage(cfCCITT4, icNone, Image)
   else
      TPDF(Data).AddImage(cfLZW, icNone, Image);
end;

procedure ExtractImages;
var i: Integer; pdf: TPDF; stack: TPDFParseInterface; outFile: String;
begin
   pdf := nil;
   FillChar(stack, sizeof(stack), 0);
   stack.BeginTemplate := parseBeginTemplate;
   stack.InsertImage   := parseInsertImage; 

   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @ErrProc);
      pdf.CreateNewPDF(''); // We create no PDF file in this example

      // We avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../../sample_multipage.pdf', ptOpen, '') < 0 then begin
         Writeln('Input file "../../../../sample_multipage.pdf" not found!');
         pdf.Free;
         Exit;
      end;
      if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then begin
         pdf.Free;
         ReadLn;
         Exit;
      end;
      // We form fields so that we can extract images of these objects too.
      pdf.FlattenForm;

      // We write the file into the application directory.
      GetDir(0, outFile);
      outFile := outFile + '\out.tif';

      // We create a multi-page TIFF in this example
      if not pdf.CreateImage(outFile, ifmTIFF) then begin
         pdf.Free;
         ReadLn;
         Exit;
      end;
      for i := 1 to pdf.GetPageCount do begin
         pdf.EditPage(i);
         // When extracing images to separate image files it is usually best to set
         // the flag pfNone because JPEG or JPEG 2000 images can be extracted as is.
         pdf.ParseContent(pdf, stack, pfDecomprAllImages);
         pdf.EndPage();
      end;
      if pdf.CloseImage then begin
         Writeln(Format('TIFF image "%s" successfully created!', [outFile]));
         ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   m_Images    := TList.Create;
   m_Templates := TList.Create;
   m_Images.Capacity    := 1024;
   m_Templates.Capacity := 1024;
   ExtractImages();
   m_Images.Free;
   m_Templates.Free;
end.
