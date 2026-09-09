<?php
/**
 * The smallest complete LumasPDF program: create, write, close.
 *
 *   php hello_world.php
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('hello_world.pdf');
$pdf = new_doc();

$pdf->CreateNewPDF($out);
$pdf->SetDocInfo(LumasPdf::diTitle,   'Hello World');
$pdf->SetDocInfo(LumasPdf::diCreator, 'LumasPDF PHP example');

// Top-down coordinates read like screen coordinates. Choose this ONCE,
// right after CreateNewPDF -- switching it later disagrees with content
// that is already written.
$pdf->SetPageCoords(LumasPdf::pcTopDown);

$pdf->Append();                                   // opens a page
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 24.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 60.0, 'Hello World!');

$pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
$pdf->SetLeading(15.0);
$pdf->SetTextRect(50.0, 90.0, $pdf->GetPageWidth() - 100.0, -1.0);
$pdf->WriteFText(LumasPdf::taJustify,
    "This file was produced by PHP " . PHP_VERSION . " calling the LumasPDF "
  . "engine through FFI. The engine behaviour is identical in every binding; "
  . "only the calling idiom differs.");
$pdf->EndPage();

$pdf->CloseFile();
done($out);
