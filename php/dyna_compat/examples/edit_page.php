<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'EditPage()');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

// Import anything and don't convert pages to templates
$pdf->SetImportFlags(dynapdf::ifImportAll | dynapdf::ifImportAsPage);
if ($pdf->OpenImportFile(FILES_ROOT.'/test_files/rotated_270.pdf', dynapdf::ptOpen, NULL) < 0) die('Cannot open file!');
$pdf->ImportPDFFile(1, 1.0, 1.0);
$pdf->CloseImportFile();

$pdf->SetPageCoords(dynapdf::pcTopDown);

// This property moves the coordinate origin into the visible area (default value == false).
$pdf->SetUseVisibleCoords(true);

// Open page 1 for editing
$pdf->EditPage(1);
	// Check whether the page is rotated.
	if (($orientation = $pdf->GetOrientation()) != 0)
	{
		// SetOrientationEx() rotates the coordinate system into the opposite direction of the page orientation.
		// There is no guarantee that the contents in a page is rotated in the same way. If the result is wrong
		// then don't call this function.
		$pdf->SetOrientationEx($orientation);
	}
	$f = $pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
	// We use this font also as list font. In this example we use a bullet as list symbol (character index 143 of the code page 1252).
	$pdf->SetListFont($f);
	// We disable UTF-8 support here because the text is defined in the Windows code page 1252.
	$pdf->DisableUTF8Support();
	$pdf->WriteFTextEx(50.0, 200.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taJustify,
		"It is not difficult to edit an imported page but two things must be considered:\n\n\\LI[20,143]\\LD[16]The page's "
		."orientation.\\EL#\\LI[20,143]\\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\\EL#\n\\LD[12]"
		."Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. DynaPDF moves the zero point then automatically "
		."into the visible area of the page.\n\n"
		."The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present.\n\n"
		."The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated "
		."into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.\n\n"
		."However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was "
		."not rotated. If this produces a wrong result then don't call SetOrientationEx().\n\n"
		."Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() "
		."and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.");
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'edit_page.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>