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

procedure CreateLayersAndTree;
var annot, ocmd, oc1, oc2, oc3: Integer; tw: double; pdf: TPDF; outFile, someText: String; root, grp: Pointer; ocArray: Array[0..1] of Cardinal;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      // Disable color key masking for images
      pdf.SetUseTransparency(false);

      // Create three layers
      oc1 := pdf.CreateOCG('All', false, true, oiAll);
      oc2 := pdf.CreateOCG('Text and Annotations', false, true, oiAll);
      oc3 := pdf.CreateOCG('Images', false, true, oiAll);

      root := pdf.AddLayerToDisplTree(nil, oc1, 'A layer group with a title');
      grp  := pdf.AddLayerToDisplTree(root, -1, '');
      pdf.AddLayerToDisplTree(grp, oc2, '');
      pdf.AddLayerToDisplTree(grp, oc3, '');
      
      pdf.Append;
      // The main layer controls the visibility of all three layers in this example.
      pdf.BeginLayer(oc1);
      pdf.BeginLayer(oc2);
         pdf.SetFont('Helvetica', fsRegular, 12.0, false, cp1252);
         someText := 'Some text with a link!!!';
         pdf.SetFillColor(clBlue);
         pdf.WriteText(50.0, 50.0, someText);
         tw := pdf.GetTextWidth(someText);
         // To reflect the same nesting as the text layer we must use an OCMD for the annotation
         // because the visibility of the layer oc2 depends on oc1 at this position.
         pdf.SetBorderStyle(bsUnderline);
         pdf.SetStrokeColor(clBlue);
         annot := pdf.WebLink(50.0, 51.0, tw, 12.0, 'www.lumaspdf.com');

         ocArray[0] := oc1;
         ocArray[1] := oc2;
         ocmd := pdf.CreateOCMD(ovAllOn, @ocArray[0], 2);
         pdf.AddObjectToLayer(ocmd, ooAnnotation, annot);
      pdf.EndLayer;

      pdf.BeginLayer(oc3);
         pdf.InsertImageEx(50.0, 70.0, 300.0, 200.0, '../../../test_files/images/margarita-102572_640.jpg', 1);
      pdf.EndLayer;
      pdf.EndLayer;

      pdf.SetFillColor(clBlack);
      pdf.WriteText(50.0, 300.0, 'This text is not part of a layer!');
      pdf.EndPage;

      pdf.SetPageMode(pmUseOC);

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
   CreateLayersAndTree;
end.

