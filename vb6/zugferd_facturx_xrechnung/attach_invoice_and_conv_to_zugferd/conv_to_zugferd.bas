Attribute VB_Name = "modConvToZugferd"
Option Explicit
' ============================================================================
'  conv_to_zugferd -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Converts a PDF to PDF/A-3 (FacturX Comfort), attaches the factur-x.xml
'  e-invoice and adds an output intent based on CheckConformance's return code.
'
'  NOTE on callbacks: the flat original passed FontNotFound + ReplaceICCProfile
'  callbacks to pdfCheckConformance. Those engine callbacks are delivered by the
'  AX server as the COM events OnFontNotFound / OnReplaceICCProfile, but their
'  PDFFont parameter is an Int64 -- a type VB6 cannot express in a WithEvents
'  sink -- so (as in pdfa_extension\checkconformance) the callbacks are dropped.
'  The COM CheckConformance(ConfType, Options) still returns the required output
' pdf.RaiseExceptions = True
' ============================================================================

Private Function ConvertFile(ByVal pdf As CPDF, ByVal ConvType As Long, ByVal InFile As String, ByVal Invoice As String, ByVal OutFile As String) As Boolean
    Dim ef As Long, retval As Long, convFlags As Long

    ConvertFile = False
    pdf.CreateNewPDF ""                 ' The output file is created later
    ' (SetDocInfoA diProducer, "" omitted: the AX engine rejects an empty value.)

    Select Case ConvType
        Case ctFacturX_Comfort, ctFacturX_Extended, ctFacturX_XRechnung
            ' We create e-invoices in this example and nothing else.
        Case Else
            Exit Function
    End Select

    ' These flags require some processing time but they are very useful.
    convFlags = coCheckImages Or coRepairDamagedImages

    ' ifPrepareForPDFA is required. ifImportAsPage keeps pages as pages.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage Or ifPrepareForPDFA
    ' if2UseProxy reduces the memory usage.
    pdf.SetImportFlags2 if2UseProxy

    pdf.OpenImportFile InFile, ptOpen, ""
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' The invoice should be the first attachment. Its file name is factur-x.xml
    ' (case sensitive); for the German XRechnung the name must be xrechnung.xml.
    ef = pdf.AttachFileA(Invoice, "EN 16931 compliant invoice", False)
    If ConvType <> ctFacturX_XRechnung Then
        pdf.AssociateEmbFile adCatalog, -1, arAlternative, ef
    Else
        pdf.AssociateEmbFile adCatalog, -1, arSource, ef
    End If

    ' An invoice should not use CMYK colors unless a CMYK ICC profile is embedded.
    retval = pdf.CheckConformance(ConvType, convFlags)
    Select Case retval
        Case 1: pdf.AddOutputIntentA "../../../test_files/sRGB.icc"
        Case 2: pdf.AddOutputIntentA "../../../test_files/ISOcoated_v2_bas.ICC"
        Case 3: pdf.AddOutputIntentA "../../../test_files/gray.icc"
    End Select

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        If pdf.OpenOutputFile(OutFile) = 0 Then Exit Function
        ConvertFile = (pdf.CloseFile() <> 0)
    End If
End Function

Public Sub Main()
    Dim pdf As New CPDF
    Dim outFile As String
' pdf.RaiseExceptions = True

    ' Non embedded CID fonts usually depend on external cmaps; load them if possible.
    pdf.SetCMapDir "../../../Resource/CMap", lcmDelayed Or lcmRecursive

    outFile = App.Path & "\out.pdf"

    ' The profiles Minimum, Basic, and Basic WL are not EN 16931 compliant.
    If ConvertFile(pdf, ctFacturX_Comfort, "../../../test_files/test_invoice.pdf", "../../../test_files/factur-x.xml", outFile) Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
End Sub
