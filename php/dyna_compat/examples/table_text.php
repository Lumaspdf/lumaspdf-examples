<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Table Text');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

// Allocate 3 rows and 3 columns. The table width should be 500 units and the default row height should be 100 units.
$tbl = new dynatbl($pdf, 3, 3, 500.0, 100.0);

$tbl->SetBoxProperty(-1, -1, dynapdf::tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
$tbl->SetFont(-1, -1, 'Helvetica', dynapdf::fsRegular, false, dynapdf::cp1252); 
$tbl->SetFont(-1, 1, 'Helvetica', dynapdf::fsBold, false, dynapdf::cp1252);
$tbl->SetGridWidth(1.0, 1.0);

$text = 'The cell alignment can be set for text, images, and templates...';

// -1.0 means use the default row height as specified in the table constructor.
$rowNum = $tbl->AddRow(-1.0);
$tbl->SetCellText($rowNum, 0, dynapdf::taLeft,   dynapdf::coTop, $text);
$tbl->SetCellText($rowNum, 1, dynapdf::taCenter, dynapdf::coTop, $text);
$tbl->SetCellText($rowNum, 2, dynapdf::taRight,  dynapdf::coTop, $text);

$rowNum = $tbl->AddRow(-1.0);
$tbl->SetCellText($rowNum, 0, dynapdf::taLeft,   dynapdf::coCenter, $text);
$tbl->SetCellText($rowNum, 1, dynapdf::taCenter, dynapdf::coCenter, $text);
$tbl->SetCellText($rowNum, 2, dynapdf::taRight,  dynapdf::coCenter, $text);

$rowNum = $tbl->AddRow(-1.0);
$tbl->SetCellText($rowNum, 0, dynapdf::taLeft,   dynapdf::coBottom, $text);
$tbl->SetCellText($rowNum, 1, dynapdf::taCenter, dynapdf::coBottom, $text);
$tbl->SetCellText($rowNum, 2, dynapdf::taRight,  dynapdf::coBottom, $text);

// Draw the table now
$pdf->Append();
$tbl->DrawTable(50.0, 50.0, 742.0);
while ($tbl->HaveMore())
{
	$pdf->EndPage();
	$pdf->Append();
	$tbl->DrawTable(50.0, 50.0, 742.0);
}
$pdf->EndPage();


// Let's change the cell orientation to see what happens...
$tbl->SetCellOrientation(-1, -1, 90);
$pdf->Append();
$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
$pdf->WriteText(50.0, 50.0, 'The same table but the cell orientation was changed to 90 degrees.');

$tbl->DrawTable(50.0, 70.0, 742.0);
while ($tbl->HaveMore())
{
	$pdf->EndPage();
	$pdf->Append();
	$tbl->DrawTable(50.0, 50.0, 737.0);
}
$pdf->EndPage();

// Note that PHP uses reference counting. The table has incremented the reference counter of the PDF class.
// In order to get both objects released we must unset() the table class. The PDF instance is automatically
// released when the script terminates.
unset($tbl);

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'table_text.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>