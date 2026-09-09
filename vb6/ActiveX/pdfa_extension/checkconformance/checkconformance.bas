Attribute VB_Name = "modCheckConformance"
Option Explicit
' ============================================================================
'  pdfa_extension\checkconformance -- ActiveX/COM (LumasPdf.PDF) port of
'  ..\..\..\pdfa_extension\checkconformance\checkconformance.bas (native
'  Declare-based CPDF.cls wrapper).
'
'  Demonstrates: importing an arbitrary PDF and converting it to PDF/A-3b via
'  the multi-step manual pipeline -- SetImportFlags/SetImportFlags2,
'  OpenImportFileW/ImportPDFFile/CloseImportFile, then CheckConformance +
'  AddOutputIntentA -- as opposed to the single-call ConvertFile shown in the
'  sibling convert_conformance example. As in the native reference, the COM
'  CheckConformance(ConfType, Options) exposes no FontNotFound /
'  ReplaceICCProfile callbacks (unlike the flat pdfCheckConformance API), so
'  those callbacks are simply dropped; the missing-ICC-profile intent is
'  applied per the returned retval instead.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  late-bound to the registered "LumasPdf.PDF" COM server):
'    pdf.CreateNewPDF ""            -> pdf.CreateNewPDFW ""
'    pdf.OpenImportFile(...)        -> pdf.OpenImportFileW(...)
'    pdf.OpenOutputFile(...)        -> pdf.OpenOutputFileW(...)
'    pdf.AddOutputIntentA(...)      -> pdf.AddOutputIntentA(...)   (unchanged)
'    pdf.SetImportFlags/2/ImportPDFFile/CloseImportFile/CheckConformance/
'    HaveOpenDoc/CloseFile          -> unchanged (already COM-visible 1:1)
'
'  dynapdf_help.pdf is copied locally next to this .bas (rather than reached
'  via a fragile relative path) -- same pattern the vendor's own csharp/vbnet
'  ActiveX ports of this example already use.
' ============================================================================

'--- TConformanceType (see src\Lumas.Pdf.Types.pas) ------------------------------
Const ctPDFA_3b As Long = 3

'--- TPDFImportFlags / TPDFImportFlags2 ------------------------------------------
Const ifImportAll As Long = &HFFFFFFE
Const ifImportAsPage As Long = &H80000000
Const ifPrepareForPDFA As Long = &H10000000
Const if2UseProxy As Long = &H4
Const if2DuplicateCheck As Long = &H10

'--- TConvertOptions (subset used) ------------------------------------------------
Const coDefault As Long = &H10FFFF
Const coDeletePresentation As Long = &H400000
Const coDeleteEmbeddedFiles As Long = &H80&
Const coCheckImages As Long = &H800000
Const coRepairDamagedImages As Long = &H2000000

'--- TPDFPasswordType -------------------------------------------------------------
Const ptOpen As Long = 0

' Shared SDK test asset used to supply the missing output-intent ICC profile.
Const TEST_FILES As String = "E:\LUMASPDFSDK\examples\test_files\"

Private Function DoConvertFile(ByVal pdf As Object, ByVal ConvType As Long, _
        ByVal InFile As String, ByVal OutFile As String) As Boolean
    Dim retval As Long, convFlags As Long

    DoConvertFile = False
    pdf.CreateNewPDFW ""                ' The output file is opened later

    ' ctPDFA_3b: embedded files are allowed.
    convFlags = (coDefault Or coDeletePresentation) And (Not coDeleteEmbeddedFiles)
    ' These flags require some processing time but they are very useful.
    convFlags = convFlags Or coCheckImages
    convFlags = convFlags Or coRepairDamagedImages

    ' ifPrepareForPDFA is required. ifImportAsPage keeps pages as pages.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage Or ifPrepareForPDFA
    pdf.SetImportFlags2 if2UseProxy Or if2DuplicateCheck

    retval = pdf.OpenImportFileW(InFile, ptOpen, "")
    LogLine "OpenImportFileW(" & InFile & ") retval=" & retval
    If retval < 0 Then
        Debug.Print "Could not open the import file (it may be encrypted)!"
        Exit Function
    End If
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    retval = pdf.CheckConformance(ConvType, convFlags)
    LogLine "CheckConformance retval=" & retval
    Select Case retval
        Case 1: pdf.AddOutputIntentA TEST_FILES & "sRGB.icc"
        Case 2: pdf.AddOutputIntentA TEST_FILES & "ISOcoated_v2_bas.ICC"
        Case 3: pdf.AddOutputIntentA TEST_FILES & "gray.icc"
    End Select

    ' No fatal error occurred?
    LogLine "HaveOpenDoc=" & CBool(pdf.HaveOpenDoc())
    If CBool(pdf.HaveOpenDoc()) Then
        If Not CBool(pdf.OpenOutputFileW(OutFile)) Then Exit Function
        DoConvertFile = CBool(pdf.CloseFile())
    End If
End Function

Private Sub LogLine(ByVal s As String)
    Dim f As Integer
    f = FreeFile
    Open App.Path & "\result.txt" For Append As #f
    Print #f, s
    Close #f
End Sub

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    Dim filePath As String, inFile As String
    inFile = App.Path & "\dynapdf_help.pdf"
    filePath = App.Path & "\out.pdf"

    ' To create a ZUGFeRD invoice, attach the required XML invoice and set the
    ' conversion type to the ZUGFeRD/FacturX profile before calling
    ' DoConvertFile.
    If DoConvertFile(pdf, ctPDFA_3b, inFile, filePath) Then
        Debug.Print "PDF file """ & filePath & """ successfully created!"
        LogLine "PDF file """ & filePath & """ successfully created!"
    Else
        Debug.Print "DoConvertFile failed."
        LogLine "DoConvertFile failed."
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    LogLine "ERROR: " & Err.Description & extra
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "checkconformance (ActiveX)"
End Sub
