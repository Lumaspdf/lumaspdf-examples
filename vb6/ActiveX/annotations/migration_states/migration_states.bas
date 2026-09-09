Attribute VB_Name = "modMigrationStates"
Option Explicit
' ============================================================================
'  migration_states -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\migration_states -- same feature: a square
'  annotation whose review state is set to Completed then Accepted (right
'  click the annotation and choose Review History in a viewer to see it).
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""          -> pdf.CreateNewPDFW ""
'    pdf.SquareAnnot ...          -> pdf.SquareAnnotW ...
'    pdf.SetAnnotMigrationState . -> pdf.SetAnnotMigrationStateW .
'    pdf.SetAnnotString ...       -> pdf.SetAnnotStringW ...
'    pdf.OpenOutputFile ...       -> pdf.OpenOutputFileW ...
'  All other calls (SetPageCoords, Append, EndPage, HaveOpenDoc, CloseFile)
'  map 1:1, just with the instance handle dropped.
' ============================================================================

Private Const NO_COLOR As Long = &HFFFFFFF1   ' transparent

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPDFColorSpace ------------------------------------------------------------------
Const csDeviceRGB As Long = 0

'--- TAnnotState / TAnnotString -------------------------------------------------------
Const asCompleted As Long = 4
Const asAccepted As Long = 1
Const asContent As Long = 1

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim annot As Long, reply As Long
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    ' To see the migration state, right click on the annotation and then on Review History.
    annot = pdf.SquareAnnotW(50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...")
    reply = pdf.SetAnnotMigrationStateW(annot, asCompleted, "Harry")
    pdf.SetAnnotStringW reply, asContent, "The state was set to Completed!"

    reply = pdf.SetAnnotMigrationStateW(reply, asAccepted, "Jim")
    pdf.SetAnnotStringW reply, asContent, "The state was set to Accepted!"
    pdf.EndPage

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        pdf.OpenOutputFileW outFile
        pdf.CloseFile
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "migration_states (ActiveX)"
End Sub
