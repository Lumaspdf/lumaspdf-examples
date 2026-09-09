<?php
/**
 * Extract the text of every page.
 *
 * Three things decide whether you get anything back:
 *   * import with ifContentOnly -- the interactive layer is noise here;
 *   * the page must be OPEN (EditPage/EndPage) while you read it;
 *   * the source font must not be an embedded SUBSET (see the note below).
 * After that, SetTextExtractionWordGap is the knob that decides whether words
 * run together or single words split.
 */
require __DIR__ . '/../bootstrap.php';

// ---------------------------------------------------------------------------
// Step 1 -- author a small source document. Embed = false keeps the standard
// font referenced by name, which is what makes the text extractable below.
// ---------------------------------------------------------------------------
$src = out_path('_extraction_source.pdf');
$doc = new_doc();
$doc->CreateNewPDF($src);
$doc->SetPageCoords(LumasPdf::pcTopDown);
foreach (['Invoice 2026-0042', 'Consulting services', 'Total due: 1,240.00 EUR'] as $i => $line) {
    $doc->Append();
    $doc->SetFont('Helvetica', LumasPdf::fsNone, 12.0, false, LumasPdf::cp1252);
    $doc->WriteText(50.0, 60.0 + 20.0 * $i, $line);
    $doc->WriteText(50.0, 120.0, 'Page ' . ($i + 1) . ' of 3');
    $doc->EndPage();
}
$doc->CloseFile();
unset($doc);

// ---------------------------------------------------------------------------
// Step 2 -- read it back.
// ---------------------------------------------------------------------------
$pdf = new_doc();
$pdf->CreateNewPDF('');                     // no output file: we only read
$pdf->SetImportFlags(LumasPdf::ifContentOnly | LumasPdf::ifImportAsPage);
if ($pdf->OpenImportFile($src, LumasPdf::ptOpen, '') < 0) {
    say('cannot open ' . $src); exit(1);
}
if ($pdf->ImportPDFFile(1, 1.0, 1.0) < 0) { say('import failed'); exit(1); }
$pdf->CloseImportFile();

// Raise the gap when words run together, lower it when single words split.
$pdf->SetTextExtractionWordGap(0.3);

$out = out_path('text_extraction.txt');
$fh  = fopen($out, 'wb');
$chars = 0;
for ($p = 1; $p <= $pdf->GetPageCount(); $p++) {
    $pdf->EditPage($p);
    // SplitPageText is 1-BASED and returns NULL for an empty page -- NULL is
    // not failure. The buffer is engine-owned and only valid until the next
    // call, so convert it immediately.
    $w   = $pdf->SplitPageTextW($p);
    $txt = ($w === null) ? '' : LumasPdf::fromW($w);
    $pdf->EndPage();
    $chars += strlen($txt);
    fwrite($fh, "--- page $p ---\n" . $txt . "\n");
    if ($p === 1) say('page 1: ' . str_replace("\n", ' | ', trim($txt)));
}
fclose($fh);

say('pages: ' . $pdf->GetPageCount() . ', characters: ' . $chars);

/*
 * VERIFIED LIMITATION -- embedded subset fonts.
 * If the source page was written with Embed = true, the engine subsets the
 * font and remaps the character codes, and it writes no /ToUnicode CMap.
 * SplitPageText/ExtractText then hand back the RAW CODES, so "LumasPDF" comes
 * out as "/XPDV3')" -- every code shifted by the subset offset. This is the
 * behaviour of BOTH engines (the C++ build and the Delphi reference agree),
 * not a binding problem, and a third-party extractor reading the same file has
 * the same trouble. Extract from documents whose fonts are referenced by name,
 * or keep the text you need somewhere other than the content stream.
 */
