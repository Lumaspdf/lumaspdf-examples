Attribute VB_Name = "modConvToZugferd"
Option Explicit
' ============================================================================
'  conv_to_zugferd -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at
'  examples\Vb6\zugferd_facturx_xrechnung\attach_invoice_and_conv_to_zugferd
'  (read-only reference, not modified). Converts a PDF to PDF/A-3 (FacturX
'  Comfort), attaches the factur-x.xml e-invoice and adds an output intent
'  based on CheckConformance's return code.
'
'  NOTE on callbacks: the reference passed FontNotFound + ReplaceICCProfile
'  callbacks to pdfCheckConformance. Those engine callbacks are delivered by
'  the ActiveX server as the COM events OnFontNotFound / OnReplaceICCProfile,
'  but their PDFFont parameter is an Int64 -- a type VB6 cannot express in a
'  WithEvents sink -- so the callbacks are dropped, same as the reference.
'  The COM CheckConformance(ConfType, Options) still returns the required
'  output intent code.
' ============================================================================

Private Const ctFacturX_Comfort As Long = 15      ' TConformanceType
Private Const ctFacturX_Extended As Long = 16
Private Const ctFacturX_XRechnung As Long = 17
Private Const coCheckImages As Long = &H800000       ' TCompressOptions
Private Const coRepairDamagedImages As Long = &H2000000
Private Const ifImportAll As Long = &HFFFFFFE        ' TImportFlags
Private Const ifImportAsPage As Long = &H80000000
Private Const ifPrepareForPDFA As Long = &H10000000
Private Const if2UseProxy As Long = &H4              ' TImportFlags2
Private Const ptOpen As Long = 0
Private Const adCatalog As Long = 1                  ' TAFDestObject
Private Const arAlternative As Long = 4              ' TAFRelationship
Private Const arSource As Long = 2
Private Const lcmDelayed As Long = 2                 ' TLoadCMapFlags
Private Const lcmRecursive As Long = 1

Private Function ConvertFile(ByVal pdf As Object, ByVal ConvType As Long, ByVal InFile As String, ByVal Invoice As String, ByVal OutFile As String) As Boolean
    Dim ef As Long, retval As Long, convFlags As Long

    ConvertFile = False
    pdf.CreateNewPDFA ""                 ' The output file is created later
    ' (SetDocInfoA diProducer, "" omitted: the engine rejects an empty value.)

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

    pdf.OpenImportFileA InFile, ptOpen, ""
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
        Case 1: pdf.AddOutputIntentA App.path & "\..\..\..\..\..\examples\test_files\sRGB.icc"
        Case 2: pdf.AddOutputIntentA App.path & "\..\..\..\..\..\examples\test_files\ISOcoated_v2_bas.ICC"
        Case 3: pdf.AddOutputIntentA App.path & "\..\..\..\..\..\examples\test_files\gray.icc"
    End Select

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        If Not pdf.OpenOutputFileA(OutFile) Then Exit Function
        ConvertFile = CBool(pdf.CloseFile())
    End If
End Function

Public Sub Main()
    Dim pdf As Object
    Dim outFile As String

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    ' Non embedded CID fonts usually depend on external cmaps; load them if possible.
    pdf.SetCMapDirA App.path & "\..\..\..\..\..\examples\Resource\CMap", lcmDelayed Or lcmRecursive

    outFile = App.path & "\out.pdf"

    ' The profiles Minimum, Basic, and Basic WL are not EN 16931 compliant.
    If ConvertFile(pdf, ctFacturX_Comfort, App.path & "\..\..\..\..\..\examples\test_files\test_invoice.pdf", App.path & "\..\..\..\..\..\examples\test_files\factur-x.xml", outFile) Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "conv_to_zugferd"
End Sub
