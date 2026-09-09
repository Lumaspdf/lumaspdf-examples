<?php
/**
 * Formatted text: alignment, leading, styles, rotation and the text matrix.
 * Shows why WriteFText (flow) and WriteText (one line) are different tools.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('text_formatting.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$w = $pdf->GetPageWidth();
$lorem = "LumasPDF flows this paragraph inside the rectangle set by "
       . "SetTextRect. Line breaks happen at word boundaries, the alignment "
       . "argument decides the edges, and SetLeading controls the distance "
       . "between baselines. A height of -1 means \"down to the bottom of the page\".";

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 18.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Text formatting');

$y = 90.0;
foreach ([LumasPdf::taLeft => 'taLeft',
          LumasPdf::taCenter => 'taCenter',
          LumasPdf::taRight => 'taRight',
          LumasPdf::taJustify => 'taJustify'] as $align => $name) {
    $pdf->SetFont('Courier', LumasPdf::fsNone, 8.0, true, LumasPdf::cp1252);
    $pdf->WriteText(50.0, $y, $name);
    $pdf->SetFont('Times', LumasPdf::fsNone, 10.0, true, LumasPdf::cp1252);
    $pdf->SetLeading(13.0);
    $pdf->SetTextRect(120.0, $y - 8.0, $w - 170.0, 60.0);
    $pdf->WriteFText($align, $lorem);
    $y += 70.0;
}

// Styles. Bold and italic are SYNTHESISED when the font file has no such
// face -- bold by stroking, italic by shearing at SetItalicAngle degrees.
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 11.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, $y, 'Bold');
$pdf->SetFont('Helvetica', LumasPdf::fsItalic, 11.0, true, LumasPdf::cp1252);
$pdf->WriteText(100.0, $y, 'Italic');
$pdf->SetFont('Helvetica', LumasPdf::fsUnderlined, 11.0, true, LumasPdf::cp1252);
$pdf->WriteText(150.0, $y, 'Underlined');

// Rotated single line. Radius/YOrigin are dead parameters in this engine.
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 30.0, true, LumasPdf::cp1252);
$pdf->SetFillColor(LumasPdf::PDF_SILVER);
$pdf->WriteAngleText('DRAFT', 45.0, 190.0, $y + 190.0, 0.0, 0.0);

$pdf->EndPage();
$pdf->CloseFile();
done($out);
