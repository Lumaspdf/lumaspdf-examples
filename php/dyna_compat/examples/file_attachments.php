<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'File Attachments');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, 50.0, 'This file contains two attachments.');
$pdf->EndPage();

$pdf->AttachFile(FILES_ROOT.'/test_files/images/switzerland-140275_640.jpg', 'Switzerland', false);
$pdf->AttachFile(FILES_ROOT.'/test_files/images/south-africa-114857_640.jpg', 'South Africa', false);

$pdf->SetPageMode(dynapdf::pmUseAttachments);

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'file_attachm.pdf'; // IE <= 8 displays a save file dialog if the name contains the sub string attachment!
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>