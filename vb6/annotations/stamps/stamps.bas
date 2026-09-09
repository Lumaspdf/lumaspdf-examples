Attribute VB_Name = "modStamps"
Option Explicit
' ============================================================================
'  stamps -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound to
'  CPDF). A pre-defined "Approved" stamp rendered in English, German
'  and French.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim a As Long
    Dim outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    ' A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
    a = pdf.StampAnnotA(rsApproved, 135#, 50#, 300#, 10#, "Test app", "Stamp Annotations", "The default language is English!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(120, 190, 92)

    pdf.SetLanguage "DE"
    a = pdf.StampAnnotA(rsApproved, 135#, 150#, 300#, 10#, "Test app", "Stamp Annotations", "The same stamp in German!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(230, 65, 132)

    pdf.SetLanguage "FR"
    a = pdf.StampAnnotA(rsApproved, 135#, 250#, 300#, 10#, "Test app", "Stamp Annotations", "The same stamp in French!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(78, 157, 232)
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub
