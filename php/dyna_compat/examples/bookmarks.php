<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Bookmarks');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->SetPageHeight(500.0);
$pdf->SetPageWidth(800.0);

$pdf->Append();
	$f = $pdf->SetFont('Helvetica', dynapdf::fsRegular, 20, false, dynapdf::cp1252);
	$pdf->WriteText(50, 50, 'Bookmark destination type dtFit');
	$root = $pdf->AddBookmark('DestType dtFit', -1, 1, true);
	$pdf->SetBookmarkDest($root, dynapdf::dtFit, 0, 0, 0, 0);
	$pdf->SetBookmarkStyle($root, dynapdf::fsItalic, dynapdf::PDF_RED);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
   $pdf->WriteText(50, 70, 'Zoom factor 3, Top position 50 (TopDown coordinates)');
   $bmk = $pdf->AddBookmark('DestType: dtXY_Zoom, zoom factor 3', $root, 2, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtXY_Zoom, 50, 50, 3, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsBold, dynapdf::PDF_MAROON);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
   $pdf->WriteText(50, 70, 'Zoom factor 0.5, Top position 50 (TopDown coordinates)');
   $bmk = $pdf->AddBookmark('DestType: dtXY_Zoom, zoom factor 0.5', $root, 3, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtXY_Zoom, 50, 50, 0.5, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsBold | dynapdf::fsItalic, dynapdf::PDF_GREEN);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
   $pdf->WriteText(50, 70, 'Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)');
   $bmk = $pdf->AddBookmark('DestType: dtXY_Zoom, zoom factor unchanged', $root, 4, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtXY_Zoom, 50, 50, 0, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsRegular, dynapdf::PDF_BLUE);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(50, 50, 'Bookmark destination type dtFitH_Top');
   $pdf->WriteText(50, 70, 'Top position 50 (TopDown coordinates)');
   $bmk = $pdf->AddBookmark('DestType: dtFitH_Top (50)', $root, 5, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtFitH_Top, 50, 0, 0, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsRegular, 0x00FF8080);
   $pdf->WriteText(50, 200, 'Bookmark destination type dtFitH_Top');
   $pdf->WriteText(50, 220, 'Top position 200 (TopDown coordinates)');
   $bmk = $pdf->AddBookmark('DestType dtFitH_Top (200)', $root, 5, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtFitH_Top, 200, 0, 0, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsRegular, 0x00C08080);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(200, 50, 'Bookmark destination type dtFitV_Left');
   $pdf->WriteText(200, 70, 'Left position 200. FitV has no effect if the width of the page');
   $pdf->WriteText(200, 90, 'is not greater as the height.');
   $bmk = $pdf->AddBookmark('DestType: dtFitV_Left (200)', $root, 6, false);
   $pdf->SetBookmarkDest($bmk, dynapdf::dtFitV_Left, 200, 0, 0, 0);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsRegular, 0x00808FFF);
$pdf->EndPage();

$pdf->Append();
   $pdf->ChangeFont($f);
   $pdf->WriteText(50, 50, 'Bookmark destination type dtFit_Rect');
   $x = ($pdf->GetPageWidth()  -90.0) / 2.0;
   $y = ($pdf->GetPageHeight() -65.0) / 2.0;
   
   $pdf->WriteFTextEx($x, $y, 90.0, -1, dynapdf::taCenter, 'We zoom into the rectangle');
   $pdf->Rectangle($x, $y, 90.0, 65.0, dynapdf::fmStroke);

    // We place a page link with a GoTo action on this position. The link zooms into the rectangle in the same way as the bookmark.
   $pdf->SetLinkHighlightMode(dynapdf::hmInvert);
   $lnk = $pdf->PageLink($x, $y, 90, 65, 7);
   $act = $pdf->CreateGoToAction(dynapdf::dtFit_Rect, 7, $x -5.0, $y -5.0, $x +100.0, $y +70.0);
   $pdf->AddActionToObj(dynapdf::otPageLink, dynapdf::oeOnMouseUp, $act, $lnk);

   $bmk = $pdf->AddBookmark('DestType: dtFit_Rect', -1, 7, false);
    // The page link uses the same destination as the bookmark should use. So we add the action to the bookmark instead
    // of a bookmark destination. This saves just a little bit disk space.
   $pdf->AddActionToObj(dynapdf::otBookmark, dynapdf::oeOnMouseUp, $act, $bmk);
   $pdf->SetBookmarkStyle($bmk, dynapdf::fsRegular, 0x000080FF);
$pdf->EndPage();

$pdf->SetPageFormat(dynapdf::pfDIN_A4);
$pdf->Append();
$pdf->ChangeFont($f);
$pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taLeft, 'Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.');
$pdf->EndPage();

$root = $pdf->AddBookmark('DestType dtFit', -1, 8, false);
$pdf->SetBookmarkDest($root, dynapdf::dtFit, 0, 0, 0, 0);

$bmk  = $pdf->AddBookmark('DestType: dtXY_Zoom, zoom factor 3', $root, 2, false);
$pdf->SetBookmarkDest($bmk, dynapdf::dtXY_Zoom, 50, 50, 3, 0);
$pdf->SetBookmarkStyle($bmk, dynapdf::fsBold, dynapdf::PDF_MAROON);


$pdf->SetPageLayout(dynapdf::plOneColumn);

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'bookmarks.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>