<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'SetOCGStateAction()');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$oc1 = $pdf->CreateOCG('Deutsch', true, false, dynapdf::oiAll);
$oc2 = $pdf->CreateOCG('English', true, true, dynapdf::oiAll);

$bmkDE = $pdf->AddBookmark('Deutsch', -1, 1, false);
$bmkEN = $pdf->AddBookmark('English', -1, 1, false);

// Simply toggle the state from On to Off or vice versa
$actToggle = $pdf->CreateSetOCGStateAction(NULL, NULL, array($oc1, $oc2), true);

$pdf->AddActionToObj(dynapdf::otBookmark, dynapdf::oeOnMouseUp, $actToggle, $bmkDE);
$pdf->AddActionToObj(dynapdf::otBookmark, dynapdf::oeOnMouseUp, $actToggle, $bmkEN);

$txtDE = "Dieses Beispiel zeigt wie ein mehrsprachiges Dokument erzeugt werden kann.\n\n".
         "Zunächst wird beim Öffnen des Dokuments die Sprache mit einer JavaScript Funktion ".
         " eingestellt.\n\n".
         "Zusätzlich kann die Sprache auch über zwei Lesezeichen ausgewählt werden. ".
         "Hierbei wird lediglich ein Layer ein- bzw. ausgeblendet.\n\n".
         "Der Seiteninhalt muss natürlich zweimal erzeugt werden, einmal in Deutsch und einmal in ".
         "Englisch in diesem Beispiel, jeweils in unterschiedlichen Layern.\n\n".
         "Die Lesezeichen blenden die Layer ein und aus mit einer SetOCGStateAction. Layer die im Toggle ".
         "Array enthalten sind, werden ein- oder ausgeschaltet, je nachdem welchen Status die Layer gerade haben.";

$txtEN = "This example shows how a multi-language document can be created.\n\n".
         "The language is initially selected with a JavaScript function when opening the file.\n\n".
         "Additionally, the whished language can be selected with two bookmarks. ".
         "The bookmarks simply hide or unhide a layer.\n\n".
         "The page contents must of course be created twice, one time in English and one time in ".
         "German in this example, but in different layers.\n\n".
         "The bookmarks switch the layer state from on to off or vice versa with a SetOCGStateAction. ".
         "The layers which are included in the Toggle array will be set to on or off, depending on ".
         "the current state.";

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular | dynapdf::fsItalic, 12.0, true, dynapdf::cp1252);
	// Text for the German layer
	$pdf->BeginLayer($oc1);
		$pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, $pdf->GetPageHeight() - 100.0, dynapdf::taLeft, $txtDE);
	$pdf->EndLayer();

	// Text for the English layer
	$pdf->BeginLayer($oc2);
		$pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, $pdf->GetPageHeight() - 100.0, dynapdf::taLeft, $txtEN);
	$pdf->EndLayer();
$pdf->EndPage();

// This Javascript selects the right layer or language depending on the viewer language.
$actLang = $pdf->CreateJSAction(
"if (app.viewerVersion >= 6.0)
{
	var ocgArray = this.getOCGs();
	var de = (app.language == \"DEU\");
	for (var i = 0; i < ocgArray.length; i++)
	{
		if(ocgArray[i].name==\"English\")
		{
			 ocgArray[i].state = !de;
		}else
		{
			ocgArray[i].state = de;
		}
	}
}");

$pdf->AddActionToObj(dynapdf::otCatalog, dynapdf::oeOnOpen, $actLang, -1);

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'set_ocg_state_action.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>