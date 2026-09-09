Attribute VB_Name = "modCheckConformance"
Option Explicit
' ============================================================================
'  checkconformance -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a PDF and converts it to PDF/A-3b via CheckConformance, then writes
'  the result. NOTE: the COM CheckConformance(ConfType, Options) exposes no
'  FontNotFound / ReplaceICCProfile callbacks (unlike the flat API), so those
' pdf.RaiseExceptions = True
'  is applied per the returned intent.
' ============================================================================

Private Function ConvertFile(ByVal pdf As CPDF, ByVal ConvType As Long, ByVal InFile As String, ByVal OutFile As String, ByVal tf As String) As Boolean
    Dim retval As Long, convFlags As Long

    ConvertFile = False
    pdf.CreateNewPDF ""                 ' The output file is opened later
    ' (SetDocInfoA diProducer, "" omitted: the AX engine rejects an empty value.)

    ' ctPDFA_3b: embedded files are allowed.
    convFlags = (coDefault Or coDeletePresentation) And (Not coDeleteEmbeddedFiles)
    ' These flags require some processing time but they are very useful.
    convFlags = convFlags Or coCheckImages
    convFlags = convFlags Or coRepairDamagedImages

    ' ifPrepareForPDFA is required. ifImportAsPage keeps pages as pages.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage Or ifPrepareForPDFA
    pdf.SetImportFlags2 if2UseProxy Or if2DuplicateCheck

    retval = pdf.OpenImportFile(InFile, ptOpen, "")
    If retval < 0 Then
        Debug.Print "Could not open the import file (it may be encrypted)!"
        Exit Function
    End If
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    retval = pdf.CheckConformance(ConvType, convFlags)
    Select Case retval
        Case 1: pdf.AddOutputIntentA tf & "\sRGB.icc"
        Case 2: pdf.AddOutputIntentA tf & "\ISOcoated_v2_bas.ICC"
        Case 3: pdf.AddOutputIntentA tf & "\gray.icc"
    End Select

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        If pdf.OpenOutputFile(OutFile) = 0 Then Exit Function
        ConvertFile = (pdf.CloseFile <> 0)
    End If
End Function

Public Sub Main()
    Dim pdf As New CPDF
    Dim filePath As String, inFile As String, tf As String
' pdf.RaiseExceptions = True

    tf = App.Path & "\..\..\..\test_files"
    inFile = App.Path & "\..\..\..\..\sample_multipage.pdf"
    filePath = App.Path & "\out.pdf"

    ' To create a ZUGFeRD invoice, attach the required XML invoice and set the
    ' conversion type to the ZUGFeRD/FacturX profile before calling ConvertFile.
    If ConvertFile(pdf, ctPDFA_3b, inFile, filePath, tf) Then
        Debug.Print "PDF file """ & filePath & """ successfully created!"
    End If
End Sub
