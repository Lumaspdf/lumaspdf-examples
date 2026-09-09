<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Hello World');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 24.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, 50.0, 'Hello World!');
	$pdf->ChangeFontSize(12.0);
	$pdf->SetLeading(14.0);
	$pdf->WriteFTextEx(50.0, 100.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taLeft, "My first PDF file created with PHP.\nThis file was created on: ".date('F d, Y H:i:s', $_SERVER['REQUEST_TIME']));
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'hello_workd.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>