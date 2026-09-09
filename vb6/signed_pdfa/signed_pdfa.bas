Attribute VB_Name = "modSignedPDFA"
Option Explicit
' ============================================================================
'  signed_pdfa -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); all
'  enums (fsNone, cp1252, taCenter, fcBorderColor, csDeviceRGB, NO_COLOR,
'  cmWinding, fmNoFill, ctPDFA_1b_2005) come from the typelib. Creates a
'  PDF/A-1b compatible file with a digitally-signed signature field, checks
'  conformance, adds the matching output intent, then signs with a self-signed
'  certificate.
'  NOTE: the COM CheckConformance(ConfType, Options) exposes no FontNotFound /
'  ReplaceICCProfile callbacks (unlike the flat API), so those callbacks are
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim sigField As Long, sh As Long
    Dim outFile As String, body As String, tf As String
    Dim cr As String
    cr = Chr(13)
' pdf.RaiseExceptions = True

    ' Shared ICC profiles live in examples\test_files.
    tf = App.Path & "\..\..\test_files"

    pdf.CreateNewPDF ""                ' The output file is opened later

    pdf.Append
    pdf.SetFont "Arial", fsNone, 10#, True, cp1252
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
    pdf.WriteFText taLeft, body

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

    pdf.SetFont "Arial", fsBold Or fsUnderlined, 11#, True, cp1252
    pdf.SetFillColor RGB(120, 120, 220)
    pdf.WriteFTextEx 50#, 60#, 150#, -1#, taCenter, "Digitally signed by:"
    pdf.SetFont "Arial", fsBold Or fsItalic, 18#, True, cp1252
    pdf.SetFillColor RGB(100, 100, 200)
    pdf.WriteFTextEx 50#, 45#, 150#, -1#, taCenter, "LumasPdf"

    pdf.EndTemplate                     ' Close the appearance template.
    ' ------------------------------------------------------------------------

    pdf.EndPage
    ' Check whether the file is compatible to PDF/A 1b. The COM CheckConformance
    ' takes (ConfType, Options) only; the font/ICC substitution callbacks that
    ' the flat API exposed are not available and are dropped.
    Select Case pdf.CheckConformance(ctPDFA_1b_2005, 0)
        Case 1, 3: pdf.AddOutputIntentA tf & "\sRGB.icc"             ' Gray, RGB
        Case 2:    pdf.AddOutputIntentA tf & "\ISOcoated_v2_bas.ICC" ' CMYK
    End Select

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
