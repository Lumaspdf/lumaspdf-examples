<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Metafiles');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	// A simple EMF file with a vector graphic
	$pdf->InsertMetafile(FILES_ROOT.'/test_files/tiger.emf', 0.0, 0.0, $pdf->GetPageWidth(), 0.0);
$pdf->EndPage();

// The output intent represents the destination color space for which the PDF file was created.
// It makes sure that we get consistent color results in diffeerent PDF viewers and when printing
// the file. The output intent should always be set if possible.
$pdf->AddOutputIntent(FILES_ROOT.'/test_files/sRGB.icc');

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'metafiles.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>