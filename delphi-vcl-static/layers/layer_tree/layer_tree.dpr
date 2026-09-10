program layer_tree;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC). No LumasPdf.dll.
// Builds a nested layer display tree (AddLayerToDisplTree) plus content on OCGs.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  clBlue  = $FF0000;
  clBlack = $000000;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  annot, ocmd, oc1, oc2, oc3: Integer;
  root, grp: Pointer;
  tw: Double;
  dir, outFile: string;
  someText: AnsiString;
  ocArray: array[0..1] of Cardinal;
begin
  someText := 'Some text with a link!!!';
  dir := ExtractFilePath(ParamStr(0));

  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetUseTransparency(False);

    oc1 := pdf.CreateOCGA('All', False, True, oiAll);
    oc2 := pdf.CreateOCGA('Text and Annotations', False, True, oiAll);
    oc3 := pdf.CreateOCGA('Images', False, True, oiAll);

    root := pdf.AddLayerToDisplTreeA(nil, oc1, 'A layer group with a title');
    grp := pdf.AddLayerToDisplTreeA(root, -1, '');
    pdf.AddLayerToDisplTreeA(grp, oc2, '');
    pdf.AddLayerToDisplTreeA(grp, oc3, '');

    pdf.Append;
    pdf.BeginLayer(oc1);
    pdf.BeginLayer(oc2);
      pdf.SetFontA('Helvetica', fsRegular, 12.0, False, cp1252);
      pdf.SetFillColor(clBlue);
      pdf.WriteTextA(50.0, 50.0, PAnsiChar(someText));
      tw := pdf.GetTextWidthA(PAnsiChar(someText));
      pdf.SetBorderStyle(Ord(bsUnderline));
      pdf.SetStrokeColor(clBlue);
      annot := pdf.WebLinkA(50.0, 51.0, tw, 12.0, 'www.lumaspdf.com');

      ocArray[0] := Cardinal(oc1);
      ocArray[1] := Cardinal(oc2);
      ocmd := pdf.CreateOCMD(ovAllOn, @ocArray[0], 2);
      pdf.AddObjectToLayer(ocmd, ooAnnotation, annot);
    pdf.EndLayer;

    pdf.BeginLayer(oc3);
      pdf.InsertImageExA(50.0, 70.0, 300.0, 200.0, '../../../test_files/images/margarita-102572_640.jpg', 1);
    pdf.EndLayer;
    pdf.EndLayer;

    pdf.SetFillColor(clBlack);
    pdf.WriteTextA(50.0, 300.0, 'This text is not part of a layer!');
    pdf.EndPage;

    pdf.SetPageMode(Ord(pmUseOC));

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
