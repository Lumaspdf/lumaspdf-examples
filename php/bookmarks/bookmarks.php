<?php
/**
 * Outline (bookmark) tree: nesting, destination types and styling.
 * AddBookmark returns the handle you pass as the PARENT of the next level.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('bookmarks.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);

$chapters = ['Introduction', 'Installation', 'First steps', 'Reference'];
$root = -1;
foreach ($chapters as $i => $title) {
    $pdf->Append();
    $pdf->SetFont('Helvetica', LumasPdf::fsBold, 20.0, true, LumasPdf::cp1252);
    $pdf->WriteText(50.0, 60.0, $title);
    $pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
    $pdf->WriteText(50.0, 90.0, 'Page ' . ($i + 1));

    // parent -1 = top level; Open = 1 shows the children expanded
    $bm = $pdf->AddBookmark($title, -1, $i + 1, 1);
    if ($i === 0) $root = $bm;

    // dtFit = fit the whole page; the four coordinates are unused for it
    $pdf->SetBookmarkDest($bm, LumasPdf::dtFit, 0, 0, 0, 0);
    $pdf->SetBookmarkStyle($bm, LumasPdf::fsBold, rgb(20, 50, 90));

    // one child per chapter, pointing at a zoomed position
    $sub = $pdf->AddBookmark('  ' . $title . ' - detail', $bm, $i + 1, 0);
    $pdf->SetBookmarkDest($sub, LumasPdf::dtXY_Zoom, 0.0, 40.0, 0.0, 2.0);
    $pdf->EndPage();
}
say('bookmarks created: ' . $pdf->GetBookmarkCount());

$pdf->CloseFile();
done($out);
