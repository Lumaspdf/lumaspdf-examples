<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create no PDF file in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'RenderPageToImage()');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	// Get the bounding box of the pure graphic without margins
	$pdf->SetMetaConvFlags(dynapdf::mfUseRclBounds);
	$bbox = $pdf->GetLogMetafileSize(FILES_ROOT.'/test_files/tiger.emf');

	$w = $bbox['Right'] - $bbox['Left'];
	$h = $bbox['Top'] - $bbox['Bottom'];
	if ($w < 0.0) $w = -$w;
	if ($h < 0.0) $h = -$h;

	// Scale the picture to a height of 680 units.
	$w = $pdf->CalcWidthHeight($w, $h, 0.0, 680.0);
	// Set the new page format (680 units + 20 units for the text)
	$pdf->SetBBox(dynapdf::pbMediaBox, 0.0, 0.0, $w, 700.0);

	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 14.0, false, dynapdf::cp1252);
	$pdf->WriteFTextEx(10.0, 10.0, 300.0, -1.0, dynapdf::taLeft, "\\LD[18]Tiger.emf rendered with DynaPDF\n".date('F d, Y H:i:s', $_SERVER['REQUEST_TIME']));

	// A simple EMF file with a vector graphic
	$pdf->InsertMetafile(FILES_ROOT.'/test_files/tiger.emf', 0.0, 20.0, 0.0, 680.0);
$pdf->EndPage();

// Render the page into a memory buffer. The page should be scaled to a width of 980 pixels.
$pdf->RenderPageToImage(1, NULL, 0, 980, 0, dynapdf::rfDefault, dynapdf::pxfRGB, dynapdf::cfFlate, dynapdf::ifmPNG);

// The file pdf_headers.inc.php sends the http headers in order to download a PDF or image file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$mime     = 'image/png';
$fileName = 'render_page_to_image.png';
$fileSize = $pdf->GetImageBufSize();
include('pdf_headers.inc.php');
$pdf->WriteImageBuffer();
exit;
?>