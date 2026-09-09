Attribute VB_Name = "modMigrationStates"
Option Explicit
' ============================================================================
'  migration_states -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound
'  to CPDF). A square annotation whose review state is set to Completed
'  then Accepted.
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
    ' To see the migration state, right click on the annotation and then on Review History.
    annot = pdf.SquareAnnot(50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...")
    reply = pdf.SetAnnotMigrationState(annot, asCompleted, "Harry")
    pdf.SetAnnotString reply, asContent, "The state was set to Completed!"

    reply = pdf.SetAnnotMigrationState(reply, asAccepted, "Jim")
    pdf.SetAnnotString reply, asContent, "The state was set to Accepted!"
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub
