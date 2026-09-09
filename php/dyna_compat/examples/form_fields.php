<?php
error_reporting(E_ALL & ~E_NOTICE);
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Form fields');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	$y = 50.0;
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, $y, 'Text fields:');

	$y += 15.0;
	$f = $pdf->CreateTextField('Text1', -1, false, 0, 50.0, $y, 200.0, 20.0);
	$pdf->SetTextFieldValue($f, NULL, 'Single line text...', dynapdf::taLeft);

	$y += 30.0;
	$f = $pdf->CreateTextField('Text2', -1, true, 0, 50.0, $y, 200.0, 50.0);
	$pdf->SetTextFieldValue($f, NULL, 'This field accepts multi-line text. The maximum text length can be restricted if necessary.', dynapdf::taLeft);

	$y += 60.0;
	$pdf->WriteText(50.0, $y, 'A password field:');
	$y += 15.0;
	$f = $pdf->CreateTextField('Text3', -1, false, 0, 50.0, $y, 200.0, 20.0);
	$pdf->SetFieldFlags($f, dynapdf::ffPassword, false);
	$pdf->SetTextFieldValue($f, NULL, '**********', dynapdf::taLeft);

	$y += 30.0;
	$pdf->WriteText(50.0, $y, 'A fixed length field separated into combs:');
	$y += 15.0;
	$f = $pdf->CreateTextField('Text4', -1, false, 10, 50.0, $y, 200.0, 20.0);
	$pdf->SetFieldFlags($f, dynapdf::ffComb, false);


	$y = 50.0;
	$pdf->WriteText(350.0, $y, 'Choice fields:');
	$y += 15.0;
	$f = $pdf->CreateComboBox('Combo1', true, -1, 350.0, $y, 200.0, 20.0);
	$pdf->AddValToChoiceField($f, NULL, ' Select a value...', true);
	$pdf->AddValToChoiceField($f, 'Apple',  'Apple',  false);
	$pdf->AddValToChoiceField($f, 'Banana', 'Banana', false);
	$pdf->AddValToChoiceField($f, 'Pear',   'Pear',   false);
	$pdf->AddValToChoiceField($f, 'Grape',  'Grape',  false);
	$pdf->AddValToChoiceField($f, 'Orange', 'Orange', false);

	$y += 30.0;
	$f = $pdf->CreateListBox('List', true, -1, 350.0, $y, 200.0, 50.0);
	$pdf->AddValToChoiceField($f, 'Apple',  'Apple',  false);
	$pdf->AddValToChoiceField($f, 'Banana', 'Banana', true);
	$pdf->AddValToChoiceField($f, 'Pear',   'Pear',   false);
	$pdf->AddValToChoiceField($f, 'Grape',  'Grape',  false);
	$pdf->AddValToChoiceField($f, 'Orange', 'Orange', false);

	$y += 60.0;
	$pdf->WriteText(350.0, $y, 'Editable combo box:');
	$y += 15.0;
	$f = $pdf->CreateComboBox('Combo2', true, -1, 350.0, $y, 200.0, 20.0);
	$pdf->AddValToChoiceField($f, 'Apple',  'Apple',  false);
	$pdf->AddValToChoiceField($f, 'Banana', 'Banana', false);
	$pdf->AddValToChoiceField($f, 'Pear',   'Pear',   false);
	$pdf->AddValToChoiceField($f, 'Grape',  'Grape',  false);
	$pdf->AddValToChoiceField($f, 'Orange', 'Orange', false);
	$pdf->SetFieldFlags($f, dynapdf::ffEdit, false);
	$pdf->SetFieldExpValue($f, 1000, 'Select or enter a value...', NULL, true);

	$y += 30.0;
	$pdf->WriteText(350.0, $y, 'Check boxes / Radio buttons:');

	$y += 15.0;
	$pdf->ChangeFontSize(1.0);
	$f = $pdf->CreateCheckBox('N1', 'C1', true, -1, 350.0, $y, 20.0, 20.0);
	$f = $pdf->CreateCheckBox('N2', 'C2', true, -1, 380.0, $y, 20.0, 20.0);
	$f = $pdf->CreateCheckBox('N3', 'C1', true, -1, 410.0, $y, 20.0, 20.0);

	$pdf->CreateCheckBox('G1', 'C1', false, -1, 450.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox('G1', 'C2', false, -1, 480.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox('G1', 'C1', true,  -1, 510.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox('G1', 'C2', false, -1, 540.0, $y, 20.0, 20.0);

	$y += 30.0;
	$pdf->ChangeFontSize(15.0);
	$pdf->SetCheckBoxChar(dynapdf::ccCircle);
	$r = $pdf->CreateRadioButton('Radio1', 'R1', true, -1, 350.0, $y, 20.0, 20.0);
	$pdf->SetCheckBoxDefState($r, false);
	$pdf->CreateCheckBox(NULL, 'R2', false, $r, 380.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox(NULL, 'R3', false, $r, 410.0, $y, 20.0, 20.0);

	$r = $pdf->CreateRadioButton('Radio2', 'R1', true, -1, 450.0, $y, 20.0, 20.0);
	$pdf->SetFieldFlags($r, dynapdf::ffRadioIsUnion, false);
	$pdf->CreateCheckBox(NULL, 'R2', false, $r, 480.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox(NULL, 'R1', true,  $r, 510.0, $y, 20.0, 20.0);
	$pdf->CreateCheckBox(NULL, 'R2', false, $r, 540.0, $y, 20.0, 20.0);
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'form_fields.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>