<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Edit text');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

// Import anything and don't convert pages to templates
$pdf->SetImportFlags(dynapdf::ifImportAll | dynapdf::ifImportAsPage);
$pdf->SetImportFlags2(dynapdf::if2UseProxy); // Reduce the memory usage
if ($pdf->OpenImportFile(FILES_ROOT.'/public_files/dynapdf_help.pdf', dynapdf::ptOpen, NULL) < 0) die('Cannot open file!');

$cnt = $pdf->GetInPageCount();
if ($cnt > 100) $cnt = 100;

for ($i = 1; $i <= $cnt; $i++)
{
	$pdf->Append();
		$pdf->ImportPageEx($i, 1.0, 1.0);
	$pdf->EndPage();
}

$psr = new content_parser($pdf, dynapdf::ofDefault);

$searchText  = "PDF"; // This string occurs of course very often in the help file
$replaceText = "XDF"; // Just an example. Use also a longer or shorter string to see what happens...

// Load at least a minimal set of fonts. Best results are achieved when the original fonts are available.
$pdf->AddFontSearchPath(FILES_ROOT.'/fonts', false);

for ($i = 1; $i <= $cnt; $i++)
{
	// The flag cpfEnableTextSelection is required. Otherwise no text can be found.
	if ($psr->ParsePage($i, dynapdf::cpfEnableTextSelection))
	{
		// Replace all occurences of "PDF" with "XDF" (case insensitive).
		while ($psr->FindText(NULL, dynapdf::stCaseInSensitive, $searchText, false))
		{
			// Set the replacement string to an empty string one time to see how surrounding text will be handled...
			// With psrSetAltFont() you can also set the preferred alternate font to output the new text if the
			// original font is not available on the system.
			$psr->ReplaceSelText(dynapdf::rtfDefault, $replaceText);
		}
		$psr->WriteToPage(dynapdf::ofDefault);
	}
}

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'edit_text.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>
