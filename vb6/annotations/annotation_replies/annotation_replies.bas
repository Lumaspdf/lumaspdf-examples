Attribute VB_Name = "modAnnotationReplies"
Option Explicit
' ============================================================================
'  annotation_replies -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound
'  to CPDF). A square annotation with a reply, and a reply to that reply.
' ============================================================================

Private Const NO_COLOR As Long = &HFFFFFFF1   ' transparent

Public Sub Main()
    Dim pdf As New CPDF
    Dim annot As Long, reply As Long
    Dim outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    ' To see the reply click on the annotation
    annot = pdf.SquareAnnot(50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...")
    reply = pdf.SetAnnotMigrationState(annot, asCreateReply, "Harry")
    pdf.SetAnnotString reply, asContent, "This is a reply!"

    reply = pdf.SetAnnotMigrationState(reply, asCreateReply, "Jim")
    pdf.SetAnnotString reply, asContent, "This is a reply to a reply!"
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub
