<?php
/**
 * Content parsing: walk a page's operators and find text.
 * The parser is a separate object (psr*) that takes BOTH the document and its
 * own context handle -- it is not a document method.
 */
require __DIR__ . '/../bootstrap.php';

// Author a page we can search, with a non-embedded font so the text is
// recoverable (see text_extraction/ for why that matters).
$src = out_path('_search_source.pdf');
$doc = new_doc();
$doc->CreateNewPDF($src);
$doc->SetPageCoords(LumasPdf::pcTopDown);
$doc->Append();
$doc->SetFont('Helvetica', LumasPdf::fsNone, 12.0, false, LumasPdf::cp1252);
$doc->WriteText(50.0, 60.0,  'Invoice 2026-0042');
$doc->WriteText(50.0, 90.0,  'Customer: ACME Ltd');
$doc->WriteText(50.0, 120.0, 'Total due: 1,240.00 EUR');
$doc->EndPage();
$doc->CloseFile();
unset($doc);

$pdf = new_doc();
$pdf->CreateNewPDF('');
$pdf->SetImportFlags(LumasPdf::ifContentOnly | LumasPdf::ifImportAsPage);
if ($pdf->OpenImportFile($src, LumasPdf::ptOpen, '') < 0) { say('cannot open'); exit(1); }
$pdf->ImportPDFFile(1, 1.0, 1.0);
$pdf->CloseImportFile();

$parser = new content_parser($pdf, 0);

// The page must be OPEN while it is parsed -- the parser reads the content
// stream of the page the engine is currently editing.
$pdf->EditPage(1);
if (!$parser->ParsePage(1, 0)) { $pdf->EndPage(); say('ParsePage failed'); exit(1); }

foreach (['ACME', 'Total due', 'nothing-like-this'] as $needle) {
    // FindText advances from the previous hit, so the same needle can be
    // searched repeatedly to walk every occurrence.
    $found = $parser->FindText(null, 0, $needle);
    say(sprintf('%-18s %s', $needle, $found ? 'found' : 'not found'));
}
$pdf->EndPage();
say('done');
