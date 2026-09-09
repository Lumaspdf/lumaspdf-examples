<?php
/* extension_loaded check removed: class dynapdf is provided by the LumasPdf FFI shim */

$pdf = new dynapdf();

// This file sets the license key and the constant FILES_ROOT.
include('config.inc.php');

// We create the PDF file in memory in this example.
$pdf->CreateNewPDF(NULL);
$pdf->SetDocInfo(dynapdf::diTitle, 'Merge PDF files');
$pdf->SetDocInfo(dynapdf::diSubject, 'DynaPDF PHP example');

$pdf->SetPageCoords(dynapdf::pcTopDown);

$pdf->Append();
	$pdf->SetFont('Helvetica', dynapdf::fsRegular, 14.0, false, dynapdf::cp1252);
	$pdf->WriteFTextEx(50.0, 50.0, $pdf->GetPageWidth() - 100.0, -1.0, dynapdf::taJustify,
		"The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that "
		."all destinations refer to the new page numbers after import.\n\n"
		."Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number "
		."of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().");
$pdf->EndPage();

// Import anything and avoid the conversion of pages to templates
$pdf->SetImportFlags(dynapdf::ifImportAll | dynapdf::ifImportAsPage);
// Reduce the memory usage. Note that the parser instance will not be deleted if this flag is set.
// CloseImportFile() or CloseImportFileEx() should be called to delete the parser instance if no longer needed.
$pdf->SetImportFlags2(dynapdf::if2UseProxy);

$path = FILES_ROOT.'/test_files/merge';
$files = array();
if (($handle = opendir($path)) !== false)
{
	while (($file = readdir($handle)) !== false)
	{
		if (pathinfo($file, PATHINFO_EXTENSION) != 'pdf') continue;
		$files[] = $file;
	}
	closedir($handle);
}
sort($files, SORT_STRING);

$first        = true;
$destPage     = 1;
$haveXFA      = false;
$isCollection = false;
for ($i = 0; $i < count($files); $i++)
{
	if ($pdf->OpenImportFile($path.'/'.$files[$i], dynapdf::ptOpen, NULL) < 0) die('Cannot open file!');
	/*
		Not all PDF files can be merged:
			- An Interactive Form is a global structure that cannot be simply merged. The names of all form fields must be
			  be unique. But also if name collusions will be solved, there is no guarantee that embedded Javascripts or Javascript
			  actions will work as expected. Interactive Forms should not be merged!

			- A PDF collection is a special PDF file that consists of a container PDF and an array of embedded files.
			  It is possible to merge two or more PDF Collections but it is not meaningful to merge a PDF Collection
			  with normal PDF files or vice versa.
	*/
	if ($first)
	{
		$first        = false;
		$haveXFA      = $pdf->GetInIsXFAForm();
		$isCollection = $pdf->GetInIsCollection();
		if (($destPage = $pdf->ImportPDFFile($destPage + 1, 1.0, 1.0)) < 0) break;
	}else
	{
		// Special handling for PDF Collections
		if ($isCollection)
		{
			if ($pdf->GetInIsCollection())
			{
				// Import the embedded files only
				$pdf->SetImportFlags(dynapdf::ifEmbeddedFiles);
				// We could also use ImportPDFFile() but this function is more efficient since no pages will be imported.
				if (!$pdf->ImportCatalogObjects()) break;
			}else
			{
				$pdf->CloseImportFile();
				// Add the file to the collection
				$pdf->AttachFile($path.'/'.$files[$i], $files[$i], true);
			}
		}else
		{
			if ($pdf->GetInIsCollection() || (($pdf->GetInIsXFAForm() || $pdf->GetInFieldCount()) && ($pdf->GetFieldCount() > 0 || $haveXFA))) break;
			if (($destPage = $pdf->ImportPDFFile($destPage + 1, 1.0, 1.0)) < 0) break;
		}
	}
	$pdf->CloseImportFile();
}

$pdf->CloseFile();

// The file pdf_headers.inc.php sends the http headers in order to download a PDF file.
// The variables $fileName and $fileSize must be set before including the file.
// If $attach is true, the file is downloaded as attachment, inline otherwise.
$attach   = false;
$fileName = 'merge.pdf';
$fileSize = $pdf->GetBufSize();
include('pdf_headers.inc.php');
$pdf->WriteBuffer();
exit;
?>