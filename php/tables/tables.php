<?php
/**
 * The tbl* table engine: allocate, fill, then draw page by page.
 * A table is NOT bound to the document -- you draw it where you want it and
 * ask whether more rows are left.
 */
require __DIR__ . '/../bootstrap.php';

// TCellAlign: coLeft/coTop = 0, coRight/coBottom = 1, coCenter = 2.
const COALIGN_CENTER = 2;

$out = out_path('tables.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Tables');

$cols = ['Article', 'Qty', 'Unit', 'Total'];
$rows = [
    ['Hex bolt M8 x 40',      '250', '0.14', '35.00'],
    ['Washer DIN 125 A8',     '500', '0.03', '15.00'],
    ['Nut DIN 934 M8',        '250', '0.05', '12.50'],
    ['Threadlocker 50 ml',      '4', '7.90', '31.60'],
    ['Assembly grease 1 kg',    '2', '9.40', '18.80'],
];

$width = $pdf->GetPageWidth() - 100.0;
$tbl = new LumasPdfTable($pdf, count($rows) + 1, count($cols), $width, 18.0);

$tbl->SetColWidth(0, (float)($width * 0.55), false);
foreach ([1, 2, 3] as $c) $tbl->SetColWidth($c, (float)($width * 0.15), false);

// CreateTable only ALLOCATES capacity. Every row must be added with AddRow,
// which returns the row index to address -- forgetting this is why a table
// silently draws nothing. -1.0 = the default row height from CreateTable.
$hdr = $tbl->AddRow(-1.0);
$tbl->SetColor($hdr, -1, LumasPdf::tcBackColor, LumasPdf::csDeviceRGB, rgb(52, 90, 125));
$tbl->SetColor($hdr, -1, LumasPdf::tcTextColor, LumasPdf::csDeviceRGB, LumasPdf::PDF_WHITE);
$tbl->SetFontA($hdr, -1, 'Helvetica', LumasPdf::fsBold, true, LumasPdf::cp1252);
foreach ($cols as $c => $title) {
    $tbl->SetCellText($hdr, $c, $c === 0 ? LumasPdf::taLeft : LumasPdf::taRight,
                      COALIGN_CENTER, $title);
}

foreach ($rows as $row) {
    $r = $tbl->AddRow(-1.0);
    foreach ($row as $c => $text) {
        $tbl->SetCellText($r, $c,
                          $c === 0 ? LumasPdf::taLeft : LumasPdf::taRight,
                          COALIGN_CENTER, $text);
    }
}

// DrawTable paints as many rows as fit in MaxHeight and returns the height it
// used. HaveMore() then says whether rows are left for the next page.
$used = $tbl->DrawTable(50.0, 90.0, 700.0);
say(sprintf('table drawn, height used = %.1f, rows left: %s',
            $used, $tbl->HaveMore() ? 'yes' : 'no'));

$pdf->EndPage();
$pdf->CloseFile();
done($out);
