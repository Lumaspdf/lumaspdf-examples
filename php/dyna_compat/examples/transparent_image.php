<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Transparent image');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

// Disable color key masking for images
$pdf->SetUseTransparency(false);

$pdf->Append();

	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, 50.0, 'Fill Alpha = 0.5');

	$pdf->Rectangle(50.0, 70.0, 110.0, 160.0, dynapdf::fmFill);
	$pdf->SetFillColor(dynapdf::PDF_WHITE);
	$pdf->WriteText(55.0, 75.0, 'Background');

	$gs = $pdf->CreateExtGState(array('FillAlpha' => 0.5));
	$pdf->SetExtGState($gs);
	$img = $pdf->InsertImageEx(60.0, 84.0, 200.0, 0.0, FILES_ROOT.'/test_files/images/tree-frog-69813_640.jpg', 0);

	// To restore an extended graphics state, create a second one that restores the changes made before.
	$gs = $pdf->CreateExtGState(array('FillAlpha' => 1.0));
	$pdf->SetExtGState($gs);

	$pdf->SetFillColor(dynapdf::PDF_BLACK);
	$pdf->WriteText(340.0, 50.0, 'Fill Alpha = 1.0 (default)');
	$pdf->Rectangle(340.0, 70.0, 110.0, 160.0, dynapdf::fmFill);
	$pdf->SetFillColor(dynapdf::PDF_WHITE);
	$pdf->WriteText(345.0, 75.0, 'Background');
	$pdf->PlaceImage($img, 350.0, 84.0, 200.0, 0.0);

$pdf->EndPage();

// Very important for consistent color results. Attach always an output intent if transparency is used!
$pdf->AddOutputIntent(FILES_ROOT.'/test_files/sRGB.icc');

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'transparent_image.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>