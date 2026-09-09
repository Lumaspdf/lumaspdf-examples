<?php
/**
 * Rasterize pages to image files. The resolution argument is what decides
 * quality and cost -- 96 for a thumbnail, 150 for screen, 300 for print.
 */
require __DIR__ . '/../bootstrap.php';

$src = test_file('sample_invoice.pdf');
if (!is_file($src)) { say('missing fixture: sample_invoice.pdf'); exit(0); }

$pdf = new_doc();
$pdf->CreateNewPDF('');
$pdf->SetImportFlags(LumasPdf::ifImportAll | LumasPdf::ifImportAsPage);
if ($pdf->OpenImportFile($src, LumasPdf::ptOpen, '') < 0) { say('cannot open'); exit(1); }
$pdf->ImportPDFFile(1, 1.0, 1.0);
$pdf->CloseImportFile();

// RenderPageToImage(page, file, resolution, width, height, flags,
//                    pixelFormat, compressionFilter, imageFormat)
// Width/height 0 means "derive from the resolution".
$made = [];
$jobs = [
    ['png', LumasPdf::ifmPNG,  150, LumasPdf::pxfRGB,  LumasPdf::cfFlate],
    ['jpg', LumasPdf::ifmJPEG,  96, LumasPdf::pxfRGB,  LumasPdf::cfJPEG],
];
foreach ($jobs as [$ext, $fmt, $dpi, $pix, $filter]) {
    $file = out_path('page1.' . $ext);
    $ok = $pdf->RenderPageToImage(1, $file, $dpi, 0, 0,
                                  LumasPdf::rfDefault, $pix, $filter, $fmt);
    say(sprintf('%-4s %3d dpi -> %s', $ext, $dpi, $ok ? 'ok' : 'FAILED'));
    if ($ok) $made[] = $file;
}
foreach ($made as $f) done($f);
