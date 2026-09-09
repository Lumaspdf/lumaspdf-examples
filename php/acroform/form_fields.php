<?php
/**
 * AcroForm fields: text, combo, list, button, and the tab order.
 * Fields the engine creates get their appearance built when the file is
 * written -- /NeedAppearances is only for fields that came in from an import.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('form_fields.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();

$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Order form');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 10.0, true, LumasPdf::cp1252);

// SetFieldBackColor / SetFieldBorderColor / SetFieldTextColor are DOCUMENT
// defaults -- they take a colour and nothing else, and apply to fields created
// afterwards. The per-field setter is SetFieldColor(field, type, cs, colour).
$pdf->SetFieldBorderColor(rgb(120, 120, 120));
$pdf->SetFieldBackColor(rgb(245, 247, 250));
$pdf->SetFieldTextColor(LumasPdf::PDF_BLACK);

$y = 100.0;
$label = function (string $t) use ($pdf, &$y) { $pdf->WriteText(50.0, $y + 3.0, $t); };

$label('Customer');
// CreateTextField(Name, Parent, Multiline, MaxLen, x, y, w, h)
$name = $pdf->CreateTextField('customer', -1, false, 60, 160.0, $y, 260.0, 18.0);
$pdf->SetTextFieldValue($name, '', '', LumasPdf::taLeft);
$y += 30.0;

$label('Delivery');
// CreateComboBox(Name, Sort, Parent, x, y, w, h)
$combo = $pdf->CreateComboBox('delivery', false, -1, 160.0, $y, 260.0, 18.0);
foreach (['Standard', 'Express', 'Pickup'] as $i => $opt)
    $pdf->AddValToChoiceField($combo, $opt, $opt, $i === 0);
$y += 30.0;

$label('Notes');
$notes = $pdf->CreateTextField('notes', -1, true, 0, 160.0, $y, 260.0, 60.0);
$y += 74.0;

// Tab order: SetFieldIndex writes /TI, SortFieldsByIndex then stable-sorts the
// CURRENT PAGE's fields by it. Both act per page.
foreach ([$name => 1, $combo => 2, $notes => 3] as $f => $idx)
    $pdf->SetFieldIndex($f, $idx);
$pdf->SortFieldsByIndex();
$pdf->SetTabOrderMode('S');            // structure order -- what PDF/UA wants

say('fields on page: ' . $pdf->GetFieldCount());

$pdf->EndPage();
$pdf->CloseFile();
done($out);
