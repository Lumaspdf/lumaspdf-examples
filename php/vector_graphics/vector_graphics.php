<?php
/**
 * Path construction and painting: every path ends in exactly ONE painting
 * operator, and the graphics state is saved/restored around transforms.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('vector_graphics.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Vector graphics');

$pdf->SetLineWidth(1.5);
$pdf->SetStrokeColor(LumasPdf::PDF_NAVY);
$pdf->SetFillColor(rgb(166, 202, 240));

$pdf->Rectangle(50.0, 90.0, 120.0, 70.0, LumasPdf::fmFillStroke);
$pdf->Ellipse(200.0, 90.0, 120.0, 70.0, LumasPdf::fmFillStroke);
$pdf->Triangle(350.0, 160.0, 410.0, 90.0, 470.0, 160.0, LumasPdf::fmFillStroke);

// A hand-built path. MoveTo/LineTo/ClosePath describe it; ONE operator paints
// it. Leaving the painting call out leaves the path open for the next call.
$pdf->SetFillColor(rgb(192, 220, 192));
$pdf->MoveTo(50.0, 220.0);
$pdf->LineTo(120.0, 190.0);
$pdf->LineTo(190.0, 250.0);
$pdf->LineTo(120.0, 280.0);
$pdf->ClosePath(LumasPdf::fmFillStroke);

// Dashes. NumValues == 0 restores a solid line.
$pdf->SetLineDashPattern('6 3', 0);
$pdf->SetStrokeColor(LumasPdf::PDF_MAROON);
$pdf->MoveTo(220.0, 220.0);
$pdf->LineTo(500.0, 220.0);
$pdf->StrokePath();
$pdf->SetLineDashPattern('', 0);

// Transforms concatenate -- wrap them, or they compound.
$pdf->SaveGraphicState();
    $pdf->TranslateCoords(300.0, 320.0);
    $pdf->RotateCoords(20.0, 0.0, 0.0);
    $pdf->SetFillColor(LumasPdf::PDF_ORANGE);
    $pdf->Rectangle(0.0, 0.0, 140.0, 60.0, LumasPdf::fmFill);
$pdf->RestoreGraphicState();

$pdf->EndPage();
$pdf->CloseFile();
done($out);
