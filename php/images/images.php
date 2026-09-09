<?php
/**
 * Placing images, and the two switches that decide what lands in the file:
 * SetSaveNewImageFormat (re-encode or pass through) and SetJPEGQuality.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('images.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Images');

$jpg = test_file('sample_page.jpg');
$png = test_file('sample_page.png');

// Pass the source bytes through untouched. Re-encoding an already-optimised
// JPEG only loses quality, so this is the right default for photographs.
$pdf->SetSaveNewImageFormat(false);
$pdf->InsertImage(50.0, 90.0, 220.0, -1.0, $jpg);

// Re-encode on insertion -- what you want for BMP/uncompressed TIFF sources.
$pdf->SetSaveNewImageFormat(true);
$pdf->SetJPEGQuality(80);
$pdf->InsertImage(300.0, 90.0, 220.0, -1.0, $png);

$pdf->SetFont('Helvetica', LumasPdf::fsNone, 9.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 330.0, 'left: passed through   right: re-encoded at quality 80');

// Interpolation is a REQUEST to the viewer: it smooths an upscaled image.
// Good for photos, bad for screenshots and barcodes. It is set PER IMAGE, by
// handle -- InsertImage returns the handle of the image it placed.
$h1 = $pdf->InsertImage(50.0, 360.0, 80.0, -1.0, $jpg);
$pdf->SetUseImageInterpolation($h1, true);
$h2 = $pdf->InsertImage(150.0, 360.0, 80.0, -1.0, $jpg);
$pdf->SetUseImageInterpolation($h2, false);
$pdf->WriteText(50.0, 470.0, 'interpolated / not interpolated (viewer-dependent)');

$pdf->EndPage();
$pdf->CloseFile();
done($out);
