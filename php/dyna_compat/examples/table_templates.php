<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Table Templates');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);
$pdf->SetPageFormat(dynapdf::pfUS_Letter);

// Allocate 30 rows and 2 columns. The table width should be 500.12 units and the default row height should be 335.0 units.
$tbl = new dynatbl($pdf, 30, 2, 512.12, 335.0);

$tbl->SetBoxProperty(-1, -1, dynapdf::tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
$tbl->SetBoxProperty(-1, -1, dynapdf::tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
$tbl->SetGridWidth(1.0, 1.0);
$tbl->SetFlags(-1, -1, dynapdf::tfScaleToRect);

$pdf->SetImportFlags2(dynapdf::if2UseProxy); // Reduce the memory usage
if ($pdf->OpenImportFile(FILES_ROOT.'/public_files/dynapdf_help.pdf', dynapdf::ptOpen, NULL) < 0) die('Cannot open file!');
$pageCount = 60; // We import only the first 60 pages since the help file is too large for an online example.

$rowNum = 0;
for ($i = 1; $i <= $pageCount; $i++)
{
	$tmpl = $pdf->ImportPage($i);
	if (($i & 1) != 0) $rowNum = $tbl->AddRow(-1.0);
	$tbl->SetCellTemplate($rowNum, ($i-1) & 1, true, dynapdf::coCenter, dynapdf::coCenter, $tmpl, 0.0, 0.0);
}
$pdf->CloseImportFile();

// Draw the table now
$pdf->Append();
$tbl->DrawTable(50.0, 50.0, 693.0);
while ($tbl->HaveMore())
{
	$pdf->EndPage();
	$pdf->Append();
	$tbl->DrawTable(50.0, 50.0, 693.0);
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
$fileName = 'table_templates.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>