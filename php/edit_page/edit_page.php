<?php
/**
 * Open an existing page and add to it. EditPage puts the engine back into a
 * page that already exists; everything you draw is appended to its content.
 */
require __DIR__ . '/../bootstrap.php';

$src = test_file('sample_multipage.pdf');
if (!is_file($src)) { say('missing fixture: sample_multipage.pdf'); exit(0); }

$out = out_path('edit_page.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetImportFlags(LumasPdf::ifImportAll | LumasPdf::ifImportAsPage);
if ($pdf->OpenImportFile($src, LumasPdf::ptOpen, '') < 0) { say('cannot open'); exit(1); }
$pdf->ImportPDFFile(1, 1.0, 1.0);
$pdf->CloseImportFile();

// Imported pages keep the source's coordinate origin: PDF-native, bottom-up.
$pdf->SetPageCoords(LumasPdf::pcBottomUp);

$n = $pdf->GetPageCount();
for ($p = 1; $p <= $n; $p++) {
    $pdf->EditPage($p);
    $pdf->SetFont('Helvetica', LumasPdf::fsNone, 8.0, false, LumasPdf::cp1252);
    $pdf->SetFillColor(rgb(120, 120, 120));
    $pdf->WriteText(50.0, 25.0, sprintf('Reviewed %s  -  page %d of %d',
                                        date('Y-m-d'), $p, $n));
    // A stamp that must not be missed: drawn last, so it is on top.
    if ($p === 1) {
        $pdf->SetFont('Helvetica', LumasPdf::fsBold, 40.0, false, LumasPdf::cp1252);
        $pdf->SetFillColor(rgb(230, 90, 90));
        $pdf->WriteAngleText('REVIEWED', 32.0, 120.0, 300.0, 0.0, 0.0);
    }
    $pdf->EndPage();
}
say("edited $n page(s)");
$pdf->CloseFile();
done($out);
