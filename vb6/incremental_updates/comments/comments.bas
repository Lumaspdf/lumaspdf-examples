Attribute VB_Name = "modComments"
Option Explicit
' ============================================================================
'  comments -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Demonstrates incremental
'  updates: create a base file with one square annotation, then repeatedly
'  reply to the annotation (and to the reply), saving each step as an
'  incremental update.
'
'  The flat VB6 original round-trips the document through an in-memory buffer
'  (GetBuffer / OpenImportBuffer with raw pointers). Following the matching
'  ActiveX .vbs port, each incremental step is round-tripped through a file on
'  disk instead (semantically identical incremental update). Errors surface as
' pdf.RaiseExceptions = True
' ============================================================================

Private pdf As CPDF

Public Sub Main()
    Dim Pdf As New CPDF
    Dim pdf As New CPDF
    Dim reply As Long
    Dim step0 As String, step1 As String, step2 As String, outFile As String

    Set pdf = New CPDF
' pdf.RaiseExceptions = True

    step0 = App.Path & "\step0.pdf"
    step1 = App.Path & "\step1.pdf"
    step2 = App.Path & "\step2.pdf"
    outFile = App.Path & "\out.pdf"

    ' ---- base file with one square annotation ----
    pdf.CreateNewPDF step0
    pdf.SetPageCoords pcTopDown
    pdf.Append
        pdf.SquareAnnot 50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just a test..."
    pdf.EndPage
    If pdf.CloseFile = 0 Then Exit Sub

    ' ---- incremental step: reply from Harry ----
    LoadInc step0, step1
    reply = pdf.SetAnnotMigrationState(0, asCreateReply, "Harry")
    pdf.SetAnnotString reply, asContent, "Hi Jim, your test annotation looks fine!"
    If pdf.CloseFile = 0 Then Exit Sub

    ' ---- incremental step: reply to the reply from Tommy ----
    LoadInc step1, step2
    reply = pdf.SetAnnotMigrationState(reply, asCreateReply, "Tommy")
    pdf.SetAnnotString reply, asContent, "Just a test whether I can reply to a reply..."
    If pdf.CloseFile = 0 Then Exit Sub

    ' ---- final incremental step: reply from Jim ----
    LoadInc step2, outFile
    reply = pdf.SetAnnotMigrationState(reply, asCreateReply, "Jim")
    pdf.SetAnnotString reply, asContent, "Seems to work very well!"
    If pdf.HaveOpenDoc <> 0 Then
        If pdf.CloseFile <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

Private Sub LoadInc(ByVal inPath As String, ByVal outPath As String)
    pdf.CreateNewPDF outPath
    ' if2IncrementalUpd also implies ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict
    pdf.SetImportFlags2 if2IncrementalUpd
    If pdf.OpenImportFile(inPath, ptOpen, "") < 0 Then Exit Sub
    If pdf.ImportPDFFile(1, 1#, 1#) <= 0 Then Exit Sub
End Sub
