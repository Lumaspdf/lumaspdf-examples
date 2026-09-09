<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Soft mask');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

// Disable color key masking for images
$pdf->SetUseTransparency(false);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, 50.0, 'Transparency effect with a soft mask.');

	$pdf->InsertImageEx(50.0, 80.0, $pdf->GetPageWidth() - 100.0, 0.0, FILES_ROOT.'/test_files/images/meadow-110719_640.jpg', 1);

	// Note that a transparency group that is used as soft mask has no own coordinate system. The easiest way to avoid coordinate
	// issues is to create the transparency group in the full size of the page or template in which it is used. The real bounding
	// box can be computed after the transparency group was fully defined.
	$grp = $pdf->BeginTransparencyGroup(0.0, 0.0, $pdf->GetPageWidth(), $pdf->GetPageHeight(), true, false, dynapdf::esDeviceGray, -1);
		$pdf->SetColorSpace(dynapdf::csDeviceGray);
		$sh = $pdf->CreateRadialShading(400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, true, false);
		$pdf->ApplyShading($sh);
		// Optional but recommended: Compute the real bounding of the group if it is used as soft mask.
		$bbox = $pdf->ComputeBBox(dynapdf::cbfNone);
		$pdf->SetBBox(dynapdf::pbMediaBox, $bbox['Left'], $bbox['Bottom'], $bbox['Right'], $bbox['Top']);
	$pdf->EndTemplate();

	$sm = $pdf->CreateSoftMask($grp, dynapdf::smtLuminosity, 0);
	$gs = $pdf->CreateExtGState(array('SoftMask' => $sm));

	$pdf->SetExtGState($gs);
	$pdf->InsertImageEx(220.0, 80.0, 500.0, 0.0, FILES_ROOT.'/test_files/images/tree-frog-69813_640.jpg', 1);
$pdf->EndPage();

// Very important for consistent color results. Attach always an output intent if transparency is used!
$pdf->AddOutputIntent(FILES_ROOT.'/test_files/sRGB.icc');

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'softmask.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>