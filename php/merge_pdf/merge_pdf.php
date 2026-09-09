<?php
/**
 * Merge several PDFs into one. Import flags decide what comes across, and
 * they must be set BEFORE OpenImportFile -- changing them afterwards does not
 * reach back into what was already read.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('merge_pdf.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);

// Bring the interactive layer across too, not just the page content.
$pdf->SetImportFlags(LumasPdf::ifImportAll | LumasPdf::ifImportAsPage);

$sources = ['sample_invoice.pdf', 'sample_graphics.pdf', 'sample_multipage.pdf'];
$pages = 0;
foreach ($sources as $src) {
    $file = test_file($src);
    if (!is_file($file)) { say("skip (missing): $src"); continue; }

    if ($pdf->OpenImportFile($file, LumasPdf::ptOpen, '') < 0) {
        say("skip (cannot open): $src");
        continue;
    }
    $n = $pdf->GetInPageCount();
    $pdf->ImportPDFFile(1, 1.0, 1.0);      // DestPage/scale are inert: appends
    $pdf->CloseImportFile();
    $pages += $n;
    say(sprintf('merged %-24s %d page(s)', $src, $n));
}

say('total pages: ' . $pdf->GetPageCount() . " (sources reported $pages)");
$pdf->CloseFile();
done($out);
