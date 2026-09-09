program edit_page;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Imports a rotated page and edits it, demonstrating SetUseVisibleCoords and
// SetOrientationEx. Logic mirrors examples\c\edit_page\edit_page.c.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first -- binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // fsRegular, cp1252, taJustify, pcTopDown, if*
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  f, orientation: Integer;
  dir, inFile, outFile: string;
  s: AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));

  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);

    inFile := dir + 'rotated_270.pdf';
    if pdf.OpenImportFileA(PAnsiChar(AnsiString(inFile)), Ord(ptOpen), '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetUseVisibleCoords(True);

    pdf.EditPage(1);
      orientation := pdf.GetOrientation;
      if orientation <> 0 then pdf.SetOrientationEx(orientation);
      pdf.SetLeading(14.0);
      f := pdf.SetFontA('Helvetica', fsRegular, 12.0, False, cp1252);
      pdf.SetListFont(f);

      // ANSI export, bullet = code page 1252 char 144 = #$90
      s := 'It is not difficult to edit an imported page but two things must be considered:'#13#13 +
           '\LI[20,'#$90']\LD[16]The page''s orientation.\EL#\LI[20,'#$90']\LD[12]The coordinate origin. ' +
           'The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#'#13'\LD[12]' +
           'Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. ' +
           'DynaPDF moves the zero point then automatically into the visible area of the page.'#13#13 +
           'The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation ' +
           'and whether a crop box is present.'#13#13 +
           'The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that ' +
           'the contents is rotated into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.'#13#13 +
           'However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we ' +
           'can work with the page as if it was not rotated. If this produces a wrong result then don''t call SetOrientationEx().'#13#13 +
           'Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible ' +
           'to parse a page with ParseContent() and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.';

      pdf.WriteFTextExA(50.0, 200.0, pdf.GetPageWidth - 100.0, -1.0, Ord(taJustify), PAnsiChar(s));
    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
      if pdf.CloseFile then
        Writeln(Format('PDF file "%s" successfully created!', [outFile]));
    end;
  finally
    pdf.Free;
  end;
end.
