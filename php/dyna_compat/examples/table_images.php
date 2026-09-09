<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Table Images');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetResolution(150);        // 150 DPI is enough for the web.
$pdf->SetJPEGQuality(70);        // This is good enough for this example.
$pdf->SetUseTransparency(false); // Disable color key masking
$pdf->SetPageCoords(dynapdf::pcTopDown);

// Allocate 100 rows and 4 columns. The table width should be 500 units and the default row height should be 100 units.
$tbl = new dynatbl($pdf, 100, 4, 500.0, 100.0);

$tbl->SetBoxProperty(-1, -1, dynapdf::tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
$tbl->SetBoxProperty(-1, -1, dynapdf::tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
$tbl->SetGridWidth(1.0, 1.0);
$tbl->SetFlags(-1, -1, dynapdf::tfUseImageCS);

$n     = 0;
$path  = FILES_ROOT.'/test_files/images';
$files = array();
if (($handle = opendir($path)) !== false)
{
	while (($file = readdir($handle)) !== false)
	{
		if (pathinfo($file, PATHINFO_EXTENSION) != 'jpg') continue;
		if ($n++ == 20) break;
		$files[] = $file;
	}
	closedir($handle);
}
sort($files, SORT_STRING);
$col    = 0;
$rowNum = $tbl->AddRow(-1.0);
for ($n = 0; $n < count($files); $n++)
{
	if ($col == 4)
	{
		$col    = 0;
		$rowNum = $tbl->AddRow(-1.0);
	}
	$tbl->SetCellImage($rowNum, $col++, true, dynapdf::coCenter, dynapdf::coCenter, 0.0, 0.0, $path.'/'.$files[$n], 1);
}
// Let's draw the table
$pdf->Append();
	$tbl->DrawTable(50.0, 50.0, 742.0);
	while ($tbl->HaveMore())
	{
		$pdf->EndPage();
		$pdf->Append();
		$tbl->DrawTable(50.0, 50.0, 742.0);
	}
$pdf->EndPage();

// We draw the same table again but this time with the flag tfScaleToRect
$tbl->SetFlags(-1, -1, dynapdf::tfScaleToRect | dynapdf::tfUseImageCS);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 12.0, false, dynapdf::cp1252);
	$pdf->WriteText(50.0, 50.0, 'The same table but the flag tfScaleToRect was set.');
	$tbl->DrawTable(50.0, 70.0, 722.0);
	while ($tbl->HaveMore())
	{
		$pdf->EndPage();
		$pdf->Append();
		$tbl->DrawTable(50.0, 50.0, 742.0);
	}
$pdf->EndPage();


// Note that PHP uses reference counting. The table has incremented the reference counter of the PDF class.
// In order to get both objects released we must unset() the table class. The PDF instance is automatically
// released when the script terminates.
unset($tbl);

// The output intent represents the destination color space for which the PDF file was created.
// It makes sure that we get consistent color results in diffeerent PDF viewers and when printing
// the file. The output intent should always be set if possible.
$pdf->AddOutputIntent(FILES_ROOT.'/test_files/sRGB.icc');

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'table_images.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>