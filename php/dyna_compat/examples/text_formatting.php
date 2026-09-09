<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

function OnPageBreakProc($LastPosX, $LastPosY, $PageBreak)
{
	global $pdf;
	global $Column;
	global $ColCount;
	global $Distance;
	global $pageCount;
	global $PosX;
	global $PosY;
	global $Width;
	global $Height;

   $pdf->SetPageCoords(dynapdf::pcTopDown); // we use top down coordinates
   $Column++;
   // $PageBreak is true if the string contains a page break tag (see help file for further information).
   if (!$PageBreak && $Column < $ColCount)
   {
      // Calulate the x-coordinate of the column
      $posX = $PosX + $Column * ($Width + $Distance);
      // change the output rectangle, do not close the page!
      $pdf->SetTextRect($posX, $PosY, $Width, $Height);
   }else
   {  // the page is full or we reached a page break tag. Close the current page and append a new one
      $pdf->EndPage();
      $pdf->Append();
      $pageCount++;
      // The number of columns can be changed if you want...
      if ($pageCount & 2)
      {
      	$ColCount = 1;
      	$Width    = ($pdf->GetPageWidth() - 100.0 - ($ColCount -1) * $Distance) / $ColCount;
      }else if ($pageCount & 4)
      {
      	$ColCount = 2;
      	$Width    = ($pdf->GetPageWidth() - 100.0 - ($ColCount -1) * $Distance) / $ColCount;
      }else
      {
      	$ColCount = 3;
      	$Width    = ($pdf->GetPageWidth() - 100.0 - ($ColCount -1) * $Distance) / $ColCount;
      }
      $pdf->SetTextRect($PosX, $PosY, $Width, $Height);
      $Column = 0;
   }
   return 0; // we do not change the alignment
}

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Text formatting');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->SetCompressionLevel(dynapdf::clNone);

$txt = file_get_contents(FILES_ROOT.'/test_files/sample.txt');

$pdf->Append();
$pageCount = 0;
$ColCount = 3;
$Column   = 0;
$Distance = 10.0;
$PosX     = 50.0;
$PosY     = 50.0;
$Height   = $pdf->GetPageHeight() - 100.0;
$Width    = ($pdf->GetPageWidth() - 100.0 - ($ColCount -1) * $Distance) / $ColCount;

$pdf->SetOnPageBreakProc('OnPageBreakProc');
// Set the output rectangle first
$pdf->SetTextRect($PosX, $PosY, $Width, $Height);

$pdf->SetFont('Helvetica', dynapdf::fsRegular, 10.0, false, dynapdf::cp1252);
// The example file is encoded in the Windows code page 1252. We must disable UTF-8 support in order to process it.
// If UTF-8 support is enabled (default) then we must convert the file to UTF-8 but this wastes just unecessary processing time.
$pdf->DisableUTF8Support();
$pdf->WriteFText(dynapdf::taJustify, $txt); // Now we can load the text

unset($txt);     // free the text buffer
$pdf->EndPage(); // Close the last page

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'text_formatting.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();

unset($pdf);
exit;
?>