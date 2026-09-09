Attribute VB_Name = "modSignatureAP"
Option Explicit
' ============================================================================
'  signature_ap -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); all
'  enums (fsNone, fsBold, cp1252, taCenter, fcBorderColor, csDeviceRGB,
'  NO_COLOR, cmWinding, fmNoFill) come from the typelib. Builds a page with a
'  digitally-signed signature field whose appearance template is drawn with
'  normal PDF functions (shadings, ellipse, text), then signs the file with a
'  self-signed certificate. The flat error callback / marshalling helpers are
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim sigField As Long, sh As Long
    Dim outFile As String, body As String
' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""                ' The output file is opened later

    pdf.Append
    pdf.SetFont "Arial", fsNone, 14#, True, cp1252
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
    pdf.WriteFText taLeft, body

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

    pdf.SetFont "Arial", fsBold Or fsUnderlined, 11#, True, cp1252
    pdf.SetFillColor RGB(120, 120, 220)
    pdf.WriteFTextEx 50#, 60#, 150#, -1#, taCenter, "Digitally signed by:"
    pdf.SetFont "Arial", fsBold Or fsItalic, 18#, True, cp1252
    pdf.SetFillColor RGB(100, 100, 200)
    pdf.WriteFTextEx 50#, 45#, 150#, -1#, taCenter, "LumasPdf"

    pdf.EndTemplate                     ' Close the appearance template.
    ' ------------------------------------------------------------------------

    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    ' Original certificate ..\..\test_files\test_cert.pfx -> here App.Path & "\test_cert.pfx"
    If pdf.CloseAndSignFile(App.Path & "\test_cert.pfx", "123456", "Test", "") <> 0 Then
        Debug.Print "PDF file """ & outFile & """ successfully created and signed!"
    End If
End Sub
