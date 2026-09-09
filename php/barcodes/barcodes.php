<?php
/**
 * Barcodes. LumasPDF's barcode surface is 2D only -- the bct* family covers
 * QR, DataMatrix, PDF417, Aztec and their HIBC variants. There are no linear
 * (Code 128 / EAN) types, so do not go looking for them.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('barcodes.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Barcodes (2D)');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 9.0, true, LumasPdf::cp1252);

// TCellAlign: coLeft/coTop = 0, coRight/coBottom = 1, coCenter = 2.
const CO_CENTER = 2;

$codes = [
    ['QR Code',    LumasPdf::bctQRCode,     'https://lumaspdf.com'],
    ['DataMatrix', LumasPdf::bctDataMatrix, 'LUMASPDF-4.2.2'],
    ['PDF417',     LumasPdf::bctPDF417,     'Invoice 2026-0042 / EUR 1240.00'],
];

$y = 90.0;
foreach ($codes as [$label, $type, $data]) {
    // InsertBarcodeStr is the string form -- no struct, no StructSize to get
    // wrong. The struct form (InitBarcode2 + InsertBarcode) is for the options.
    $rc = $pdf->InsertBarcodeStrA(50.0, $y, 120.0, 120.0, CO_CENTER, CO_CENTER,
                                  $type, $data, true);
    // The barcode family reports failure with -1, not 0.
    say(sprintf('%-11s %s', $label, $rc >= 0 ? 'ok' : 'not available (' . $rc . ')'));
    $pdf->WriteText(190.0, $y + 60.0, $label . ': ' . $data);
    $y += 140.0;
}

$pdf->EndPage();
$pdf->CloseFile();
done($out);
