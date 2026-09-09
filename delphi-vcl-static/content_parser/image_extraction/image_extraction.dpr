program image_extraction;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Imports dynapdf_help.pdf and extracts every image into a multi-page TIFF by
// parsing each page's content stream. Templates and image objects are
// de-duplicated so each is handled once.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  IN_FILE = 'E:\LUMASPDFSDK\dynapdf_help.pdf';

var
  gPdf: TLumasPDFCore;
  m_Images: TList;
  m_Templates: TList;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function parseBeginTemplate(const Data, PDFObject: Pointer; Handle: Integer; var BBox: TPDFRect; Matrix: PCTM): Integer; stdcall;
begin
  if m_Templates.IndexOf(Pointer(Handle)) > -1 then
  begin
    Result := 1; // Skip the template
    Exit;
  end;
  m_Templates.Add(Pointer(Handle));
  Result := 0;
end;

function parseInsertImage(const Data: Pointer; var Image: TPDFImage): Integer; stdcall;
begin
  Result := 0;
  if not Image.InlineImage then
  begin
    if m_Images.IndexOf(Image.ObjectPtr) > -1 then Exit; // Already handled
    m_Images.Add(Image.ObjectPtr);
  end;
  // If an image cannot be decompressed we can get a compressed image here.
  if Image.Filter <> dfNone then Exit;
  if Image.BitsPerPixel = 1 then
    gPdf.AddImage(cfCCITT4, icNone, Image)
  else
    gPdf.AddImage(cfLZW, icNone, Image);
end;

var
  pdf: TLumasPDFCore;
  stack: TPDFParseInterface;
  outFile: string;
  i: Integer;
begin
  m_Images := TList.Create;
  m_Templates := TList.Create;
  m_Images.Capacity := 1024;
  m_Templates.Capacity := 1024;
  try
    FillChar(stack, SizeOf(stack), 0);
    stack.BeginTemplate := parseBeginTemplate;
    stack.InsertImage := parseInsertImage;

    pdf := TLumasPDFCore.Create;
    gPdf := pdf;
    try
      pdf.SetOnErrorProc(nil, @ErrProc);
      pdf.CreateNewPDFA('');

      // We avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFileA(IN_FILE, Ord(ptOpen), '') < 0 then
      begin
        Writeln('Input file "dynapdf_help.pdf" not found!');
        Exit;
      end;
      if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then Exit;
      // Flatten form fields so we can extract images of these objects too.
      pdf.FlattenForm;

      outFile := ExtractFilePath(ParamStr(0)) + 'out.tif';

      // We create a multi-page TIFF in this example
      if not pdf.CreateImageA(PAnsiChar(AnsiString(outFile)), ifmTIFF) then Exit;

      for i := 1 to pdf.GetPageCount do
      begin
        pdf.EditPage(i);
        // The pdf handle is passed as the parser Data.
        pdf.ParseContent(pdf.InstanceHandle, stack, pfDecomprAllImages);
        pdf.EndPage;
      end;

      if pdf.CloseImage then
        Writeln(Format('TIFF image "%s" successfully created!', [outFile]));
    finally
      pdf.Free;
    end;
  finally
    m_Images.Free;
    m_Templates.Free;
  end;
end.
