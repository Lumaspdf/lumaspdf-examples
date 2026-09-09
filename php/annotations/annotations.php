<?php
/**
 * Annotations: sticky notes, highlights, stamps, links and file attachments.
 * They live beside the page content, not in it -- a viewer can hide them.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('annotations.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Annotations');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);

// Sticky note. Its icon colour is a DOCUMENT default -- set it first.
$pdf->SetIconColor(rgb(255, 214, 90));
$pdf->TextAnnot(50.0, 95.0, 22.0, 22.0, 'Reviewer',
                'This paragraph needs a source.', LumasPdf::aiComment, false);
$pdf->WriteText(85.0, 100.0, 'A text (sticky note) annotation sits here.');

// Web link. Nothing connects a link to the text under it: measure the text
// and place the rectangle yourself.
$label = 'lumaspdf.com';
$pdf->WriteText(50.0, 140.0, 'Visit ');
$w = $pdf->GetTextWidth($label);
$pdf->SetFillColor(rgb(20, 80, 180));
$pdf->WriteText(84.0, 140.0, $label);
$pdf->SetFillColor(LumasPdf::PDF_BLACK);
$pdf->WebLink(84.0, 128.0, $w, 14.0, 'https://lumaspdf.com');

// Square and stamp.
$pdf->SquareAnnot(50.0, 180.0, 180.0, 60.0, 1.0, rgb(240, 245, 255),
                  rgb(60, 110, 190), LumasPdf::csDeviceRGB,
                  'Reviewer', 'Area of interest', 'Check the totals here.');
$pdf->StampAnnot(260.0, 180.0, 120.0, 50.0, LumasPdf::rsApproved,
                 'Reviewer', 'Sign-off', 'Approved on ' . date('Y-m-d'));

// GetPageAnnotCount takes no page number: it reports the CURRENT page, and
// it counts annotations only -- form fields are not included.
say('annotations on this page: ' . $pdf->GetPageAnnotCount());
$pdf->EndPage();
$pdf->CloseFile();
done($out);
