Attribute VB_Name = "modAttachInvoice"
Option Explicit
' ============================================================================
'  attach_invoice -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at
'  examples\Vb6\zugferd_facturx_xrechnung\attach_invoice (read-only
'  reference, not modified). Imports an existing PDF/A-3 invoice, attaches
'  the factur-x.xml e-invoice, associates it with the catalog and sets the
'  FacturX Comfort PDF version.
' ============================================================================

Private Const ifImportAsPage As Long = &H80000000
Private Const ifImportAll As Long = &HFFFFFFE
Private Const ptOpen As Long = 0
Private Const adCatalog As Long = 1            ' TAFDestObject
Private Const arAlternative As Long = 4         ' TAFRelationship
Private Const pvFacturX_Comfort As Long = &H400000  ' TPDFVersion

Public Sub Main()
    Dim pdf As Object
    Dim ef As Long, outFile As String

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True
    pdf.CreateNewPDFA ""              ' The output file is opened later

    ' We assume that the pdf invoice is already a valid PDF/A 3 file in this example.
    pdf.SetImportFlags ifImportAsPage Or ifImportAll
    pdf.OpenImportFileA App.path & "\..\..\..\..\..\examples\test_files\test_invoice.pdf", ptOpen, ""
    pdf.ImportPDFFile 1, 1#, 1#

    ef = pdf.AttachFileA(App.path & "\..\..\..\..\..\examples\test_files\factur-x.xml", "EN 16931 compliant invoice", False)
    pdf.AssociateEmbFile adCatalog, -1, arAlternative, ef

    ' ZUGFeRD 2.1+ and FacturX are identically defined in PDF and share version constants.
    pdf.SetPDFVersion pvFacturX_Comfort

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        outFile = App.path & "\out.pdf"
        If Not pdf.OpenOutputFileA(outFile) Then Exit Sub
        If pdf.CloseFile() Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "attach_invoice"
End Sub
