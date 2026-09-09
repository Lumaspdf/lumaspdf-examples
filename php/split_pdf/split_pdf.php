<?php
/**
 * Split a multi-page PDF into one file per page, by importing a single page
 * into a fresh document each time.
 */
require __DIR__ . '/../bootstrap.php';

$src = test_file('sample_multipage.pdf');
if (!is_file($src)) { say('missing fixture: sample_multipage.pdf'); exit(0); }

// One probe instance just to count the pages.
$probe = new_doc();
$probe->CreateNewPDF('');
if ($probe->OpenImportFile($src, LumasPdf::ptOpen, '') < 0) {
    say('cannot open ' . $src); exit(1);
}
$count = $probe->GetInPageCount();
$probe->CloseImportFile();
unset($probe);
say("source has $count page(s)");

$written = [];
for ($p = 1; $p <= $count; $p++) {
    $out = out_path(sprintf('page_%02d.pdf', $p));
    $pdf = new_doc();
    $pdf->CreateNewPDF($out);
    $pdf->SetImportFlags(LumasPdf::ifImportAll | LumasPdf::ifImportAsPage);
    $pdf->OpenImportFile($src, LumasPdf::ptOpen, '');
    $pdf->ImportPageEx($p, 1.0, 1.0);      // scale factors are inert here
    $pdf->CloseImportFile();
    $pdf->CloseFile();
    unset($pdf);
    $written[] = $out;
}
foreach ($written as $f) done($f);
