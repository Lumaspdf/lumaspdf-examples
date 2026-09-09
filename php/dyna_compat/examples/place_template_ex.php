<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'PlaceTemplateEx()');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

if ($pdf->OpenImportFile(FILES_ROOT.'/test_files/rotated_270_neg.pdf', dynapdf::ptOpen, NULL) < 0) die('Cannot open file!');

// Get the bounding box of page 1. The crop box, if set, takes always precedence.
if (($bbox = $pdf->GetInBBox(1, dynapdf::pbCropBox)) === NULL)
	$bbox = $pdf->GetInBBox(PDF, 1, dynapdf::pbMediaBox);
// Get the orientation of page 1
$orientation = $pdf->GetInOrientation(1);
// Import page 1 as template
$tmpl = $pdf->ImportPage(1);
// We don't need the file anymore.
$pdf->CloseImportFile();

switch($orientation)
{
	case   90:
	case  -90:
	case  270:
	case -270:
	{
		$w = $bbox['Top'] - $bbox['Bottom'];
		$h = $bbox['Right'] - $bbox['Left'];
		break;
	}
	default:
	{
		$w = $bbox['Right'] - $bbox['Left'];
		$h = $bbox['Top'] - $bbox['Bottom'];
	}
}
if ($w < 0.0) $w = -$w;
if ($h < 0.0) $h = -$h;

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
   $pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
   $pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taJustify,
      "\\LD[12]This example shows the difference between PlaceTemplate() and PlaceTemplateEx(). "
      ."PlaceTemplate() does not consider the bounding boxes or the orientation of an imported page. "
      ."The page that we import here is maybe a bit unusual but something like this exists.\n\n"
      ."The page is rotated by -270 degrees and it uses a negative coordinate origin. It contains also a crop box "
      ."that must be considered.\n\n"
      ."Since templates do not support a crop box, the only way to get rid of it is to draw the template into a clipping rectangle, but "
      ."this sounds easier as it is. If a page is rotated and if it uses also a non-zero coordinate origin then it "
      ."is quite difficult to draw such a template. However, there is an easy solution that handles all the complicated things for you: "
      ."simply use PlaceTemplateEx() instead!\n\n"
      ."The green rectangle marks the area in which the template should be drawn.");

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->WriteText(50.0, $y, 'Result with PlaceTemplate():');
   $pdf->WriteText(300.0, $y, 'Result with PlaceTemplateEx():');

   $y += 20.0;

	// Calculate the expected height of the rectangle
   $h = $pdf->CalcWidthHeight($w, $h, 200.0, 0.0);

	// This version produces an incorrect result
   $pdf->PlaceTemplate($tmpl, 50.0, $y, 200.0, 0.0);

   $pdf->SetStrokeColor(dynapdf::PDF_GREEN);
   $pdf->Rectangle(50.0, $y, 200.0, $h, dynapdf::fmStroke);

	// This function was designed for imported pages
   $pdf->PlaceTemplateEx($tmpl, 300.0, $y, 200.0, 0.0);

   $pdf->Rectangle(300.0, $y, 200.0, $h, dynapdf::fmStroke);
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'place_template_ex.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>