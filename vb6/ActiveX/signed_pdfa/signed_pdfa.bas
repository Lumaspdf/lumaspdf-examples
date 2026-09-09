Attribute VB_Name = "modSignedPDFA"
Option Explicit
' ============================================================================
'  signed_pdfa -- ActiveX/COM (LumasPdf.PDF) port of ..\..\signed_pdfa\
'  signed_pdfa.bas (native Declare-based CPDF.cls wrapper).
'
'  Demonstrates: creating a PDF/A-1b compatible file with a digitally-signed
'  signature field (hand-drawn appearance template: axial shadings, an
'  ellipse, and text), checking PDF/A conformance, adding the matching
'  output intent, then signing with a self-signed certificate.
'
'  As in the native reference, the COM CheckConformance(ConfType, Options)
'  exposes no FontNotFound / ReplaceICCProfile callbacks (unlike the flat
'  API), so those are simply dropped.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  late-bound to the registered "LumasPdf.PDF" COM server):
'    pdf.CreateNewPDF ""        -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...            -> pdf.SetFontW ...
'    pdf.WriteFText ...         -> pdf.WriteFTextW ...
'    pdf.WriteFTextEx ...       -> pdf.WriteFTextExW ...
'    pdf.OpenOutputFile(...)    -> pdf.OpenOutputFileW(...)
'    pdf.AddOutputIntentA(...)  -> pdf.AddOutputIntentA(...)   (unchanged)
'    CreateSigField/SetFieldColor/PlaceSigFieldValidateIcon/CreateSigFieldAP/
'    SaveGraphicState/Rectangle/ClipPath/CreateAxialShading/ApplyShading/
'    RestoreGraphicState/Ellipse/EndTemplate/EndPage/SetFillColor/
'    HaveOpenDoc/CloseAndSignFile -> unchanged (already COM-visible 1:1)
'
'  Color values: LumasPdf uses 0x00BBGGRR, which is exactly what VB6's
'  built-in RGB(r,g,b) returns, so RGB() is used directly.
'
'  test_cert.pfx is copied locally next to this .bas (the native reference
'  keeps its own local copy too, rather than reaching up via a relative
'  path).
' ============================================================================

'--- TFStyle bits (see src\Lumas.Pdf.Types.pas) ----------------------------------
Const fsNone As Long = &H0
Const fsBold As Long = &H2BC00000
Const fsUnderlined As Long = &H4
Const fsItalic As Long = &H1

'--- TTextAlign --------------------------------------------------------------------
Const taLeft As Long = 0
Const taCenter As Long = 1

'--- TCodepage (index 2 = cp1252) ---------------------------------------------------
Const cp1252 As Long = 2

'--- TFieldColor / TPDFColorSpace / transparent color ------------------------------
Const fcBorderColor As Long = 1
Const csDeviceRGB As Long = 0
Const NO_COLOR As Long = &HFFFFFFF1

'--- TClippingMode / TPathFillMode --------------------------------------------------
Const cmWinding As Long = 1
Const fmNoFill As Long = 10

'--- TConformanceType --------------------------------------------------------------
Const ctPDFA_1b_2005 As Long = 0

' Shared SDK test asset used to supply the missing output-intent ICC profile.
Const TEST_FILES As String = "E:\LUMASPDFSDK\examples\test_files\"

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    Dim sigField As Long, sh As Long
    Dim outFile As String, body As String
    Dim cr As String
    cr = Chr(13)

    pdf.CreateNewPDFW ""                ' The output file is opened later

    pdf.Append
    pdf.SetFontW "Arial", fsNone, 10#, True, cp1252
    body = "This is a PDF/A 1b compatible PDF file that was digitally signed with " & _
        "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important " & _
        "to avoid the usage of the 14 Standard fonts." & cr & cr & _
        "When signing a PDF/A compliant PDF file with the default settings (without creation of a user " & _
        "defined appearance) the font Arial must be available on the system because it is used to print " & _
        "the certificate properties into the signature field." & cr & cr & _
        "The font Arial must also be available if an empty signature field was added to the file " & _
        "without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A " & _
        "compliant PDF file later with Adobe's Acrobat. The signed PDF file is still compatible " & _
        "to PDF/A." & cr & cr & _
        "Signature fields must be visible and the print flag must be set (default). CheckConformance() " & _
        "adjusts these flags if necessary and produces a warning if changes were applied." & cr & cr & _
        "\FC[255]Notice:\FC[0]" & cr & _
        "CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. " & _
        "Once the settings were found it is usually not longer recommended to execute this function."
    pdf.WriteFTextW taLeft, body

    ' ---------------------- Signature field appearance ----------------------
    sigField = pdf.CreateSigField("Signature", -1, 200#, 400#, 200#, 80#)
    pdf.SetFieldColor sigField, fcBorderColor, csDeviceRGB, NO_COLOR
    pdf.PlaceSigFieldValidateIcon sigField, 0#, 15#, 50#, 50#
    pdf.CreateSigFieldAP sigField

    pdf.SaveGraphicState
    pdf.Rectangle 0#, 0#, 200#, 80#, fmNoFill
    pdf.ClipPath cmWinding, fmNoFill
    sh = pdf.CreateAxialShading(0#, 0#, 200#, 0#, 0.5, RGB(120, 120, 220), RGB(255, 255, 255), 1, 1)
    pdf.ApplyShading sh
    pdf.RestoreGraphicState

    pdf.SaveGraphicState
    pdf.Ellipse 50.5, 1#, 148.5, 78#, fmNoFill
    pdf.ClipPath cmWinding, fmNoFill
    sh = pdf.CreateAxialShading(0#, 0#, 0#, 78#, 2#, RGB(255, 255, 255), RGB(120, 120, 220), 1, 1)
    pdf.ApplyShading sh
    pdf.RestoreGraphicState

    pdf.SetFontW "Arial", fsBold Or fsUnderlined, 11#, True, cp1252
    pdf.SetFillColor RGB(120, 120, 220)
    pdf.WriteFTextExW 50#, 60#, 150#, -1#, taCenter, "Digitally signed by:"
    pdf.SetFontW "Arial", fsBold Or fsItalic, 18#, True, cp1252
    pdf.SetFillColor RGB(100, 100, 200)
    pdf.WriteFTextExW 50#, 45#, 150#, -1#, taCenter, "LumasPdf"

    pdf.EndTemplate                     ' Close the appearance template.
    ' ------------------------------------------------------------------------

    pdf.EndPage

    ' Check whether the file is compatible to PDF/A 1b. The COM
    ' CheckConformance takes (ConfType, Options) only; the font/ICC
    ' substitution callbacks that the flat API exposed are not available and
    ' are dropped.
    Select Case pdf.CheckConformance(ctPDFA_1b_2005, 0)
        Case 1, 3: pdf.AddOutputIntentA TEST_FILES & "sRGB.icc"             ' Gray, RGB
        Case 2:    pdf.AddOutputIntentA TEST_FILES & "ISOcoated_v2_bas.ICC" ' CMYK
    End Select

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileW(outFile)) Then Exit Sub
    End If
    ' Original certificate ..\..\..\test_files\test_cert.pfx -> here App.Path & "\test_cert.pfx"
    If CBool(pdf.CloseAndSignFile(App.Path & "\test_cert.pfx", "123456", "Test", "")) Then
        Debug.Print "PDF file """ & outFile & """ successfully created and signed!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "signed_pdfa (ActiveX)"
End Sub
