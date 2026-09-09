<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Check boxes');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
   $pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
   $pdf->WriteText(50.0, 50.0, 'Normal check boxes.');

   $pdf->ChangeFontSize(1.0);
   $f = $pdf->CreateCheckBox('N1', 'C1', true, -1, 50.0,  70.0, 20.0, 20.0);
   $pdf->SetCheckBoxDefState($f, true);
   $f = $pdf->CreateCheckBox('N2', 'C2', true, -1, 80.0,  70.0, 20.0, 20.0);
   $pdf->SetCheckBoxDefState($f, true);
   $f = $pdf->CreateCheckBox('N3', 'C1', true, -1, 110.0, 70.0, 20.0, 20.0);
   $pdf->SetCheckBoxDefState($f, true);

   $pdf->ChangeFontSize(10.0);
   $pdf->WriteText(50.0, 100.0, 'Field group with check boxes.');

   $pdf->ChangeFontSize(1.0);
   $pdf->CreateCheckBox('G1', 'C1', false, -1, 50.0, 120.0, 20.0, 20.0);
   $pdf->CreateCheckBox('G1', 'C2', false, -1, 80.0, 120.0, 20.0, 20.0);
   $pdf->CreateCheckBox('G1', 'C1', true, -1, 110.0, 120.0, 20.0, 20.0);

   $pdf->ChangeFontSize(10.0);
   $pdf->WriteFTextEx(50.0, 150.0, 220.0, -1.0, dynapdf::taLeft, 'This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.');

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->ChangeFontSize(1.0);
   $pdf->SetCheckBoxChar(dynapdf::ccCircle);
   $pdf->CreateCheckBox('G2', 'C1', false, -1, 50.0, $y, 20.0, 20.0);
   $pdf->CreateCheckBox('G2', 'C2', false, -1, 80.0, $y, 20.0, 20.0);
   $pdf->CreateCheckBox('G2', 'C3', true, -1, 110.0, $y, 20.0, 20.0);


   $pdf->ChangeFontSize(10.0);
   $pdf->WriteFTextEx(300.0, 50.0, 250.0, -1.0, dynapdf::taLeft, 'This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.');

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->ChangeFontSize(15.0);
   $r = $pdf->CreateRadioButton('Radio1', 'R1', true, -1, 300.0, $y, 20.0, 20.0);
   $pdf->SetCheckBoxDefState($r, false);
   $pdf->CreateCheckBox(NULL, 'R2', false, $r, 330.0, $y, 20.0, 20.0);
   $pdf->CreateCheckBox(NULL, 'R3', false, $r, 360.0, $y, 20.0, 20.0);

   $pdf->ChangeFontSize(10.0);
   $f = $pdf->CreateButton('Reset', 'Reset', -1, 400.0, $y, 60.0, 20.0);
   $pdf->SetFieldColor($f, dynapdf::fcBackColor, dynapdf::csDeviceRGB, dynapdf::PDF_LTGRAY);
   $pdf->SetFieldBorderStyle($f, dynapdf::bsBevelled);

   $act = $pdf->CreateResetAction();
   $pdf->AddActionToObj(dynapdf::otField, dynapdf::oeOnMouseUp, $act, $f);
   $pdf->AddFieldToFormAction($act, $r, true);

   $y += 40.0;
   $pdf->ChangeFontSize(10.0);
   $pdf->WriteFTextEx(300.0, $y, 250.0, -1.0, dynapdf::taLeft, 'The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.');
   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->ChangeFontSize(15.0);
   $r = $pdf->CreateRadioButton('Radio2', 'R1', true, -1, 300.0, $y, 20.0, 20.0);
   $pdf->SetFieldFlags($r, dynapdf::ffRadioIsUnion, false);
   $pdf->CreateCheckBox(NULL, 'R2', false, $r, 330.0, $y, 20.0, 20.0);
   $pdf->CreateCheckBox(NULL, 'R1', true, $r, 360.0, $y, 20.0, 20.0);
   $pdf->CreateCheckBox(NULL, 'R2', false, $r, 390.0, $y, 20.0, 20.0);
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'check_boxes.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>