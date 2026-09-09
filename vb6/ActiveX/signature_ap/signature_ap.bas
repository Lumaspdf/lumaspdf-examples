Attribute VB_Name = "modSignatureAP"
Option Explicit
' ============================================================================
'  signature_ap -- ActiveX/COM (LumasPdf.PDF) port of ..\..\signature_ap\
'  signature_ap.bas (native Declare-based CPDF.cls wrapper).
'
'  Demonstrates: building a page with a digitally-signed signature field
'  whose appearance template is drawn with normal PDF drawing functions
'  (shadings, an ellipse, text) rather than an imported page/EMF/image, then
'  signing the file with a self-signed certificate.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  late-bound to the registered "LumasPdf.PDF" COM server):
'    pdf.CreateNewPDF ""        -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...            -> pdf.SetFontW ...
'    pdf.WriteFText ...         -> pdf.WriteFTextW ...
'    pdf.WriteFTextEx ...       -> pdf.WriteFTextExW ...
'    pdf.OpenOutputFile(...)    -> pdf.OpenOutputFileW(...)
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

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    Dim sigField As Long, sh As Long
    Dim outFile As String, body As String

    pdf.CreateNewPDFW ""                ' The output file is opened later

    pdf.Append
    pdf.SetFontW "Arial", fsNone, 14#, True, cp1252
    body = "This file is digitally signed with a self sign certificate. " & _
        "The appearance of the signature field is created with normal PDF functions. However, it " & _
        "would also be possible to import a PDF page, an EMF file, or an image into the " & _
        "appearance template." & Chr(10) & Chr(10) & _
        "When creating an individual signature appearance make sure to place the validation icon " & _
        "properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon " & _
        "depends on the Acrobat version with which the file is opened. However, the unscaled size " & _
        "of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want " & _
        "but it is usually best to preserve the aspect ratio and the icon must be placed fully " & _
        "inside the appearance template."
    pdf.WriteFTextW taLeft, body

    ' ---------------------- Signature field appearance ----------------------
    sigField = pdf.CreateSigField("Signature", -1, 200#, 500#, 200#, 80#)
    pdf.SetFieldColor sigField, fcBorderColor, csDeviceRGB, NO_COLOR
    ' Place the validation icon on the left side of the signature field.
    pdf.PlaceSigFieldValidateIcon sigField, 0#, 15#, 50#, 50#
    ' Creates a template that is already opened; must be closed with EndTemplate().
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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "signature_ap (ActiveX)"
End Sub
