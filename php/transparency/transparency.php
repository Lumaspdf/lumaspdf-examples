<?php
/**
 * Real transparency comes from an extended graphics state -- NOT from
 * SetOpacity, which stores its value and emits nothing.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('transparency.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->SetUseTransparency(true);           // master switch, on by default
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Transparency');

$colours = [rgb(220, 60, 60), rgb(60, 160, 90), rgb(60, 100, 200)];
$x = 60.0;
foreach ([1.0, 0.6, 0.3] as $i => $alpha) {
    // CreateExtGState takes the property array; InitExtGState's job (zeroing
    // the struct so the shape is not invisible) is done for you here.
    $gs = $pdf->CreateExtGState(['FillAlpha' => $alpha, 'StrokeAlpha' => $alpha]);
    $pdf->SetExtGState($gs);
    $pdf->SetFillColor($colours[$i]);
    $pdf->Ellipse($x, 110.0, 160.0, 160.0, LumasPdf::fmFill);
    $x += 70.0;
}

// Back to opaque for the caption.
$gs = $pdf->CreateExtGState(['FillAlpha' => 1.0, 'StrokeAlpha' => 1.0]);
$pdf->SetExtGState($gs);
$pdf->SetFillColor(LumasPdf::PDF_BLACK);
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 10.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 300.0, 'alpha 1.0 / 0.6 / 0.3 via CreateExtGState + SetExtGState');
$pdf->WriteText(50.0, 316.0, 'SetOpacity() would store the value and change nothing.');

$pdf->EndPage();
$pdf->CloseFile();
done($out);
