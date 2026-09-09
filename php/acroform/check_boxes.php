<?php
/**
 * Check boxes and radio groups. A radio group is a PARENT field whose
 * children share the name and differ by export value.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('check_boxes.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Check boxes and radio buttons');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 10.0, true, LumasPdf::cp1252);

// document-level widget colours (they take a colour only -- see form_fields.php)
$pdf->SetFieldBorderColor(rgb(90, 90, 90));

$y = 100.0;
foreach (['Newsletter' => true, 'Terms accepted' => false] as $caption => $checked) {
    // CreateCheckBox(Name, ExpValue, Checked, Parent, x, y, w, h)
    $cb = $pdf->CreateCheckBox(strtolower(str_replace(' ', '_', $caption)),
                               'On', $checked, -1, 50.0, $y, 14.0, 14.0);
    $pdf->WriteText(74.0, $y + 3.0, $caption);
    $y += 26.0;
}

$y += 12.0;
$pdf->WriteText(50.0, $y, 'Shipping:');
$y += 20.0;
$group = $pdf->CreateGroupField('shipping', -1);
foreach (['Air', 'Sea', 'Road'] as $i => $opt) {
    // CreateRadioButton(Name, ExpValue, Checked, Parent, x, y, w, h)
    $rb = $pdf->CreateRadioButton($opt, $opt, $i === 0, $group, 50.0, $y, 14.0, 14.0);
    $pdf->WriteText(74.0, $y + 3.0, $opt);
    $y += 24.0;
}

say('fields: ' . $pdf->GetFieldCount());
$pdf->EndPage();
$pdf->CloseFile();
done($out);
