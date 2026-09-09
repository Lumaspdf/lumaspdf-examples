<?php
/**
 * Encryption: open (user) password, owner password and permission flags.
 * The restrictions are a request to the viewer -- they are not a guarantee.
 */
require __DIR__ . '/../bootstrap.php';

$out = out_path('encrypted.pdf');
$pdf = new_doc();
$pdf->CreateNewPDF($out);
$pdf->SetPageCoords(LumasPdf::pcTopDown);
$pdf->Append();
$pdf->SetFont('Helvetica', LumasPdf::fsBold, 16.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 55.0, 'Encrypted document');
$pdf->SetFont('Helvetica', LumasPdf::fsNone, 11.0, true, LumasPdf::cp1252);
$pdf->WriteText(50.0, 85.0, 'Open password: user   Owner password: owner');
$pdf->EndPage();

// Encryption is applied when the file is CLOSED, not while it is written.
// CloseFileEx(OpenPwd, OwnerPwd, KeyLen, Restrict) -- note the order: the
// OPEN (user) password comes first, and the restriction mask comes last.
$deny = LumasPdf::rsPrint | LumasPdf::rsCopyObj;
$pdf->CloseFileEx('user', 'owner', LumasPdf::kl128bitEx, $deny);
done($out);

// --- read it back ----------------------------------------------------------
$probe = new_doc();
$probe->CreateNewPDF('');

// With SetUseExactPwd off the engine also tries the empty owner password,
// which is what opens the very common "encrypted with no owner password" file.
$probe->SetUseExactPwd(true);

$rc = $probe->OpenImportFile($out, LumasPdf::ptOpen, 'wrong');
say('wrong password -> ' . ($rc < 0 ? 'refused (as it should be)' : "opened?! rc=$rc"));

$rc = $probe->OpenImportFile($out, LumasPdf::ptOpen, 'user');
say('correct password -> ' . ($rc >= 0 ? 'opened, ' . $probe->GetInPageCount() . ' page(s)' : "refused rc=$rc"));

// TestPassword works against the CURRENTLY OPEN import file, so it is a way to
// ask "is this also the owner password?" after you are already in -- not a way
// to test before opening. With no file open it answers no to everything.
say('TestPassword("owner") -> ' . ($probe->TestPassword(LumasPdf::ptOwner, 'owner') ? 'accepted' : 'refused'));
say('TestPassword("nope")  -> ' . ($probe->TestPassword(LumasPdf::ptOwner, 'nope') ? 'accepted' : 'refused'));

$probe->CloseImportFile();
