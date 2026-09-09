<?php
/**
 * Stream a generated PDF straight to the browser (no temp file).
 *
 * IMPORTANT -- FFI in a web SAPI.
 * PHP ships `ffi.enable=preload`, which means FFI::cdef() works in the CLI but
 * is REFUSED under Apache/FPM/FastCGI. Two ways out:
 *
 *   1. preload the binding (recommended, keeps FFI closed to everything else):
 *          opcache.enable       = 1
 *          opcache.preload      = /path/to/lumaspdf_preload.php
 *          opcache.preload_user = www-data
 *   2. or open FFI for every script on the server:
 *          ffi.enable = true
 *
 * LumasPdf::assertUsable() checks this for you and explains which one is
 * missing instead of failing with a bare FFI exception.
 */
require __DIR__ . '/../bootstrap.php';

$pdf = new_doc();
$pdf->CreateNewPDF('');                    // empty name = build in memory
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 22.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 60.0, 'Generated on the fly');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 95.0, 'PHP ' . PHP_VERSION . ' / SAPI ' . PHP_SAPI
                          . ' / ' . gmdate('Y-m-d H:i:s') . ' UTC');
$pdf->EndPage();
$pdf->CloseFile();

$size = $pdf->GetBufSize();                // fetches the buffer once

if (PHP_SAPI === 'cli') {
    $out = out_path('stream_pdf.pdf');
    file_put_contents($out, '');
    ob_start(); $pdf->WriteBuffer(); file_put_contents($out, ob_get_clean());
    done($out);
    return;
}

// 'inline' plus a real .pdf file name: without both, some browsers save the
// script name instead of rendering the document.
header('Content-Type: application/pdf');
header('Content-Disposition: inline; filename="generated.pdf"');
header('Content-Length: ' . $size);
header('Cache-Control: private, max-age=0, must-revalidate');
$pdf->WriteBuffer();
