Attribute VB_Name = "modComments"
Option Explicit
' ============================================================================
'  comments -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no project
'  reference required. Equivalent of ../../../../Vb6/incremental_updates/comments
'  (flat-DLL / CPDF.cls wrapper style), translated per the mechanical mapping
'  pdfXxx(IPDF, args) -> pdf.Xxx(args): create a base file with one square
'  annotation, then repeatedly reply to the annotation (and to the reply),
'  saving each step as an incremental update. Each step is round-tripped
'  through a file on disk (CreateNewPDFW / OpenImportFileW / ImportPDFFile),
'  identical in spirit to the original's incremental-update flow.
'
'  pdf.RaiseExceptions = True turns internal engine errors into VB6 runtime
'  errors, caught below via On Error GoTo ErrHandler.
' ============================================================================

Private pdf As Object   ' LumasPdf.PDF (late-bound)

' --- enum values used below (see wrappers\activex\LumasPdfAX.ridl / src\Lumas.Pdf.Types.pas);
'     late binding via CreateObject means named typelib enums are not visible,
'     so their numeric values are declared locally, same technique as
'     wrappers\activex\Examples\NorthwindMegaDemo.bas ---
Private Const asCreateReply As Long = 5        ' TAnnotState.asCreateReply
Private Const asContent As Long = 1            ' TAnnotString.asContent
Private Const ptOpen As Long = 0               ' TPwdType.ptOpen
Private Const if2IncrementalUpd As Long = 256  ' TImportFlags2.if2IncrementalUpd ($100)
Private Const pcTopDown As Long = 1            ' TPageCoord.pcTopDown
Private Const csDeviceRGB As Long = 0          ' TPDFColorSpace.csDeviceRGB
Private Const NO_COLOR As Long = &HFFFFFFF1    ' Transparent color used by annotations/fields

Public Sub Main()
    Dim reply As Long
    Dim step0 As String, step1 As String, step2 As String, outFile As String

    On Error GoTo ErrHandler

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    step0 = App.path & "\step0.pdf"
    step1 = App.path & "\step1.pdf"
    step2 = App.path & "\step2.pdf"
    outFile = App.path & "\out.pdf"

    ' ---- base file with one square annotation ----
    pdf.CreateNewPDFW step0
    pdf.SetPageCoords pcTopDown
    pdf.Append
        pdf.SquareAnnotW 50#, 50#, 200#, 100#, 3#, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just a test..."
    pdf.EndPage
    If Not CBool(pdf.CloseFile()) Then Exit Sub

    ' ---- incremental step: reply from Harry ----
    LoadInc step0, step1
    reply = pdf.SetAnnotMigrationStateW(0, asCreateReply, "Harry")
    pdf.SetAnnotStringW reply, asContent, "Hi Jim, your test annotation looks fine!"
    If Not CBool(pdf.CloseFile()) Then Exit Sub

    ' ---- incremental step: reply to the reply from Tommy ----
    LoadInc step1, step2
    reply = pdf.SetAnnotMigrationStateW(reply, asCreateReply, "Tommy")
    pdf.SetAnnotStringW reply, asContent, "Just a test whether I can reply to a reply..."
    If Not CBool(pdf.CloseFile()) Then Exit Sub

    ' ---- final incremental step: reply from Jim ----
    LoadInc step2, outFile
    reply = pdf.SetAnnotMigrationStateW(reply, asCreateReply, "Jim")
    pdf.SetAnnotStringW reply, asContent, "Seems to work very well!"

    If CBool(pdf.HaveOpenDoc()) Then
        If CBool(pdf.CloseFile()) Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
            MsgBox "PDF file """ & outFile & """ successfully created!", vbInformation, "comments (ActiveX)"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "comments (ActiveX)"
End Sub

Private Sub LoadInc(ByVal inPath As String, ByVal outPath As String)
    pdf.CreateNewPDFW outPath
    ' if2IncrementalUpd also implies ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict
    pdf.SetImportFlags2 if2IncrementalUpd
    If pdf.OpenImportFileW(inPath, ptOpen, "") < 0 Then Exit Sub
    If pdf.ImportPDFFile(1, 1#, 1#) <= 0 Then Exit Sub
End Sub
