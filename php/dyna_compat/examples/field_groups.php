<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Field groups');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
   $pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
   $pdf->SetLeading(12.0);
   $pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taJustify,
      "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type.\n\n"
      ."A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. "
      ."The latter way is more efficient since it is not required to search for the parent field when a child will be created.\n\n"
      ."Enter some more text into a field to see the difference between auto size and fixed font size.");

	// GetLastTextPosY() returns bottom up coordinates. We must subtract the value from the page height.
   $base = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 20.0;

   $pdf->WriteFTextEx(50.0, $base, 200.0, -1.0, dynapdf::taLeft, 'Font size <= 1.0 means auto size.');

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->ChangeFontSize(1.0);
   $f = $pdf->CreateTextField('Auto', -1, false, 0, 50.0, $y, 200.0, 20.0);
   $pdf->SetTextFieldValue($f, 'Some text...', 'Some text...', dynapdf::taLeft);

   $y += 30.0;
   $pdf->CreateTextField(NULL, $f, false, 0, 50.0, $y, 200.0, 30.0);

   $y += 40.0;
   $pdf->CreateTextField(NULL, $f, false, 0, 50.0, $y, 200.0, 40.0);


   $pdf->ChangeFontSize(10.0);
   $pdf->WriteFTextEx(345.0, $base, 200.0, -1.0, dynapdf::taLeft, 'The same fields with a fixed font size.');

   $y = $pdf->GetPageHeight() - $pdf->GetLastTextPosY() + 10.0;

   $pdf->ChangeFontSize(12.0);
   $pdf->CreateTextField(NULL, $f, false, 0, 345.0, $y, 200.0, 20.0);

   $y += 30.0;
   $pdf->ChangeFontSize(24.0);
   $pdf->CreateTextField(NULL, $f, false, 0, 345.0, $y, 200.0, 30.0);

   $y += 40.0;
   $pdf->ChangeFontSize(34.0);
   $pdf->CreateTextField(NULL, $f, false, 0, 345.0, $y, 200.0, 40.0);

   $pdf->ChangeFontSize(18.0);
   $f = $pdf->CreateButton('Reset', 'Reset', -1, 222.5, $y + 80.0, 150.0, 25.0);
   $pdf->SetFieldColor($f, dynapdf::fcBackColor, dynapdf::csDeviceRGB, dynapdf::PDF_LTGRAY);
   $pdf->SetFieldBorderStyle($f, dynapdf::bsBevelled);

   $act = $pdf->CreateResetAction();
   $pdf->AddActionToObj(dynapdf::otField, dynapdf::oeOnMouseUp, $act, $f);
$pdf->EndPage();

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'field_groups.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>