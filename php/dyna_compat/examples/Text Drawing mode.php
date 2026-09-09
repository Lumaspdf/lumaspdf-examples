
if (!extension_loaded('dynapdf')) die('DynaPDF was not loaded. Check your php.ini!');

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Text drawing modes');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->SetBBox(dynapdf::pbMediaBox, 0.0, 0.0, 842.0, 595.0);

$pdf->Append();
    $y = 50.0;
    $w = $pdf->GetPageWidth() - 100.0;
   $pdf->SetFont('Helvetica', dynapdf::fsRegular, 20.0, false, dynapdf::cp1252);

   $pdf->WriteFTextEx(50.0, $y, $w, -1.0, dynapdf::taCenter, 'Text Drawing Modes');

   $y += 30.0;
   $pdf->ChangeFontSize(10.0);
   $pdf->WriteFTextEx(50.0, $y, $w, -1.0, dynapdf::taJustify,
       'Glyph outlines are always closed paths. The current line cap style has no effect but the line join style will be considered for stroked glyphs. '
      .'Stroked glyphs can also be drawn with a dash pattern. In this case, and only in this case, the line cap style will be considered too.');

   $pdf->SetLineWidth(2.0);
   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY();
   $pdf->SetFont('Helvetica', dynapdf::fsBold, 55.0, false, dynapdf::cp1252);
   $pdf->SetFillColor(dynapdf::PDF_SKYBLUE);
   $pdf->WriteText(50.0, $y, 'dmNormal');

   $y += 50.0;
   $pdf->SetLineJoinStyle(dynapdf::jsMiterJoin); // This is the default
   $pdf->SetTextDrawMode(dynapdf::dmStroke);
   $pdf->WriteText(50.0, $y, 'dmStroke');
   $pdf->WriteText(430.0, $y, 'MiterJoin');

   $y += 50.0;
   $pdf->SetLineJoinStyle(dynapdf::jsRoundJoin);
   $pdf->SetTextDrawMode(dynapdf::dmStroke);
   $pdf->WriteText(50.0, $y, 'dmStroke');
   $pdf->WriteText(430.0, $y, 'RoundJoin');

   $y += 50.0;
   $pdf->SetLineJoinStyle(dynapdf::jsBevelJoin);
   $pdf->SetTextDrawMode(dynapdf::dmFillStroke);
   $pdf->WriteText(50.0, $y, 'dmFillStroke');
   $pdf->WriteText(430.0, $y, 'BevelJoin');

   $y += 50.0;
   $pdf->SetLineCapStyle(dynapdf::csRoundCap);
   $pdf->SetTextDrawMode(dynapdf::dmFillStroke);
   $pdf->SetLineDashPatternEx(array(0.0, 4.0), 0);
   $pdf->WriteText(50.0, $y, 'dmFillStroke');
   $pdf->WriteText(430.0, $y, 'Dash Pattern');


   $pdf->SetLineCapStyle(dynapdf::csButtCap);    // Default
   $pdf->SetLineJoinStyle(dynapdf::jsMiterJoin); // Default
   $pdf->SetLineDashPatternEx(NULL, 0);

   $y += 70.0;
   $pdf->SetTextDrawMode(dynapdf::dmNormal);
   $pdf->SetFillColor(dynapdf::PDF_BLACK);
   $pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
   $pdf->WriteFTextEx(50.0, $y, $w, -1.0, dynapdf::taJustify,
       'The clipping modes must be enclosed in Save/RestoreGraphicState() calls! Text that is drawn in the mode dmInvisible is invisible but it can be selected and copied. This mode '
      .'is mostly used in OCR scanned faxes. The text can be drawn on top of the image so that it can be selected.');

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY();

   $pdf->SetFont('Helvetica', dynapdf::fsBold, 55.0, false, dynapdf::cp1252);
   $sh = $pdf->CreateAxialShading(0.0, $y, 0.0, $y + 50.0, 1.0, dynapdf::PDF_YELLOW, dynapdf::PDF_SKYBLUE, false, true);
   $pdf->SaveGraphicState();
      $pdf->SetTextDrawMode(dynapdf::dmClipping);
      $pdf->WriteText(50.0, $y, 'Mode dmClipping');
      $pdf->ApplyShading($sh);
   $pdf->RestoreGraphicState();

   $y += 55.0;
   $sh = $pdf->CreateAxialShading(0.0, $y, 0.0, $y + 50.0, 1.0, dynapdf::PDF_YELLOW, dynapdf::PDF_SKYBLUE, false, true);
   $pdf->SaveGraphicState();
      $pdf->SetTextDrawMode(dynapdf::dmFillClip);
      $pdf->WriteText(50.0, $y, 'Mode dmFillClip');
      $pdf->ApplyShading($sh);
   $pdf->RestoreGraphicState();

   $y += 55.0;
   $sh = $pdf->CreateAxialShading(0.0, $y, 0.0, $y + 50.0, 1.0, dynapdf::PDF_YELLOW, dynapdf::PDF_SKYBLUE, false, true);
   $pdf->SaveGraphicState();
      $pdf->SetLineWidth(3.0);
      $pdf->SetTextDrawMode(dynapdf::dmStrokeClip);
      $pdf->WriteText(50.0, $y, 'Mode dmStrokeClip');
      $pdf->ApplyShading($sh);
   $pdf->RestoreGraphicState();
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'text_drawing_modes.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>