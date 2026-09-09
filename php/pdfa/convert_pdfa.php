<?php
/**
 * PDF/A conversion and conformance checking.
 *
 * Two rules decide whether it works: every font must be EMBEDDED (so
 * SetUseStdFonts must be off) and an output intent must be present.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('pdfa.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);

// PDF/A forbids relying on the viewer's fonts.
$pdf->SetUseStdFonts(false);
$pdf->SetLanguage('en-US');                 // required for PDF/UA, good practice here

$pdf->Append();
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 18.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 60.0, 'Archivable document');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
$pdf->SetTextRect(50.0, 90.0, $pdf->GetPageWidth() - 100.0, -1.0);
$pdf->WriteFText(LumasPdf::taJustify,
    'PDF/A files must carry everything they need to render identically in '
  . 'fifty years: embedded fonts, a declared colour space, and XMP metadata '
  . 'that agrees with the document information dictionary.');
$pdf->EndPage();

// CheckConformance returns the number of VIOLATIONS it could not fix -- 0 is
// the pass. It is not a boolean, and a non-zero result is not a failure of the
// call itself.
// CheckConformance(ConfType, Options, UserData, OnFontNotFound, OnReplaceICC)
$violations = $pdf->CheckConformance(LumasPdf::ctPDFA_3b, 0, null, null, null);
say('conformance violations left: ' . $violations);

$pdf->CloseFile();
done($out);
