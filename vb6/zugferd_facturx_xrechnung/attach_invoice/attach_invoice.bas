Attribute VB_Name = "modAttachInvoice"
Option Explicit
' ============================================================================
'  attach_invoice -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports an existing PDF/A-3 invoice, attaches the factur-x.xml e-invoice,
'  associates it with the catalog and sets the FacturX Comfort PDF version.
'  Flat pdfMethod[A](pdf, args) -> pdf.Method[A](args); error callback dropped.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim ef As Long, outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""              ' The output file is opened later

    ' We assume that the pdf invoice is already a valid PDF/A 3 file in this example.
    pdf.SetImportFlags ifImportAsPage Or ifImportAll
    pdf.OpenImportFile "../../../test_files/test_invoice.pdf", ptOpen, ""
    pdf.ImportPDFFile 1, 1#, 1#

    ef = pdf.AttachFileA("../../../test_files/factur-x.xml", "EN 16931 compliant invoice", False)
    pdf.AssociateEmbFile adCatalog, -1, arAlternative, ef

    ' ZUGFeRD 2.1+ and FacturX are identically defined in PDF and share version constants.
    pdf.SetPDFVersion pvFacturX_Comfort

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub
