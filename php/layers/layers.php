<?php
/**
 * Optional content (layers): create OCGs, wrap content in them, and set the
 * default visibility that a viewer starts with.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('layers.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);

// CreateOCG(name, DisplayInUI, Visible, Intent) -- that parameter order is the
// verified one; DisplayInUI decides whether the user can toggle it at all.
$text   = $pdf->CreateOCG('Text',      true, true,  LumasPdf::oiAll);
$shapes = $pdf->CreateOCG('Shapes',    true, true,  LumasPdf::oiAll);
$hidden = $pdf->CreateOCG('Watermark', true, false, LumasPdf::oiAll);

$pdf->Append();

$pdf->BeginLayer($text);
    $pdf->SetFont('Helvetica', LumasPdf::fsBold, 18.0, true, LumasPdf::cp1252);
    $pdf->WriteText(50.0, 60.0, 'Layers (optional content)');
    $pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
    $pdf->WriteText(50.0, 90.0, 'Toggle the layers in your viewer\'s layer panel.');
$pdf->EndLayer();

$pdf->BeginLayer($shapes);
    $pdf->SetFillColor(rgb(120, 170, 220));
    $pdf->Rectangle(50.0, 120.0, 200.0, 90.0, LumasPdf::fmFill);
    $pdf->SetFillColor(rgb(220, 170, 120));
    $pdf->Ellipse(280.0, 120.0, 200.0, 90.0, LumasPdf::fmFill);
$pdf->EndLayer();

// Starts hidden: Visible=false above put it in the OFF array of the default
// optional-content configuration.
$pdf->BeginLayer($hidden);
    $pdf->SetFont('Helvetica', LumasPdf::fsBold, 48.0, true, LumasPdf::cp1252);
    $pdf->SetFillColor(LumasPdf::PDF_SILVER);
    $pdf->WriteAngleText('CONFIDENTIAL', 30.0, 90.0, 400.0, 0.0, 0.0);
$pdf->EndLayer();

$pdf->EndPage();
$pdf->CloseFile();
done($out);
