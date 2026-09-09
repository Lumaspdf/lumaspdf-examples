<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Layer tree');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

// Disable color key masking for images
$pdf->SetUseTransparency(false);

// Create three layers
// The parameter DisplayInUI must be set to false since we create the layer tree manually in this example
$oc1 = $pdf->CreateOCG('All', false, true, dynapdf::oiAll);
$oc2 = $pdf->CreateOCG('Text and Annotations', false, true, dynapdf::oiAll);
$oc3 = $pdf->CreateOCG('Images', false, true, dynapdf::oiAll);

$root = $pdf->AddLayerToDisplTree(NULL, $oc1, 'A layer group with a title');
$grp  = $pdf->AddLayerToDisplTree($root, -1, NULL);
$pdf->AddLayerToDisplTree($grp, $oc2, NULL);
$pdf->AddLayerToDisplTree($grp, $oc3, NULL);

$pdf->Append();
// The main layer controls the visibility of all three layers in this example.
$pdf->BeginLayer($oc1);
	$pdf->BeginLayer($oc2);
		$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
		$someText = 'Some text with a link!!!';
		$pdf->SetFillColor(dynapdf::PDF_BLUE);
		$pdf->WriteText(50.0, 50.0, $someText);
		$tw = $pdf->GetTextWidth($someText);
		// To reflect the same nesting as the text layer we must
		// use an OCMD for the annotation because the visibility of the
		// layer oc2 depends on oc1 at this position.
		$pdf->SetBorderStyle(dynapdf::bsUnderline);
		$pdf->SetStrokeColor(dynapdf::PDF_BLUE);
		$annot = $pdf->WebLink(50.0, 51.0, $tw, 12.0, "www.dynaforms.com");
		$ocmd  = $pdf->CreateOCMD(dynapdf::ovAllOn, array($oc1, $oc2));
		$pdf->AddObjectToLayer($ocmd, dynapdf::ooAnnotation, $annot);
	$pdf->EndLayer();

	$pdf->BeginLayer($oc3);
		$pdf->InsertImageEx(50.0, 70.0, 300.0, 200.0, FILES_ROOT.'/test_files/images/margarita-102572_640.jpg', 1);
	$pdf->EndLayer();
$pdf->EndLayer();

$pdf->SetFillColor(dynapdf::PDF_BLACK);
$pdf->WriteText(50.0, 300.0, 'This text is not part of a layer!');
$pdf->EndPage();

$pdf->SetPageMode(dynapdf::pmUseOC);

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'layer_tree.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>