<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'EMF Spool files');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);
$pdf->SetResolution(300);
$pdf->SetCompressionFilter(dynapdf::cfFlate);
$pdf->SetPageFormat(dynapdf::pfUS_Letter);

// A few pages of the help file. The spool file contains embedded font subsets and delta font
// records which must be converted back to regular TrueType fonts to achieve a correct result.
$pdf->ConvertEMFSpool(FILES_ROOT.'/test_files/print_spool.spl', 0.0, 0.0, dynapdf::spcDefault);

// The output intent represents the destination color space for which the PDF file was created.
// It makes sure that we get consistent color results in diffeerent PDF viewers and when printing
// the file. The output intent should always be set if possible.
$pdf->AddOutputIntent(FILES_ROOT.'/test_files/sRGB.icc');

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'emf_spool.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>