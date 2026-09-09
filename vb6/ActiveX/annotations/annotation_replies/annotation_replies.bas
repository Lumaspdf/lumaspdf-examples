Attribute VB_Name = "modAnnotationReplies"
Option Explicit
' ============================================================================
'  annotation_replies -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\annotation_replies -- same feature: a square
'  annotation with a reply, and a reply to that reply (SetAnnotMigrationState
'  with asCreateReply builds a reply chain instead of changing review state).
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
Const asCreateReply As Long = 5   ' don't add a migration state, create a reply instead
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
    ' To see the reply click on the annotation
    annot = pdf.SquareAnnotW(50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...")
    reply = pdf.SetAnnotMigrationStateW(annot, asCreateReply, "Harry")
    pdf.SetAnnotStringW reply, asContent, "This is a reply!"

    reply = pdf.SetAnnotMigrationStateW(reply, asCreateReply, "Jim")
    pdf.SetAnnotStringW reply, asContent, "This is a reply to a reply!"
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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "annotation_replies (ActiveX)"
End Sub
