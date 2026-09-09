Attribute VB_Name = "modMultipleSignatures"
Option Explicit
' ============================================================================
'  multiple_signatures -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no
'  project reference required. Equivalent of
'  ../../../../Vb6/incremental_updates/multiple_signatures (flat-DLL / CPDF.cls
'  wrapper style). Signs a PDF four times (two visible + two invisible
'  signatures) using incremental updates so each new signature does not
'  invalidate the previous ones. When signing a file in place, a temp file is
'  used and moved over the input (plain Win32 API calls -- unrelated to
'  LumasPdf, kept as native Declares).
'
'  pdf.RaiseExceptions = True turns internal engine errors into VB6 runtime
'  errors, caught below via On Error GoTo ErrHandler.
' ============================================================================

Private Declare Function GetTempFileNameA Lib "kernel32" (ByVal lpPathName As String, ByVal lpPrefixString As String, ByVal wUnique As Long, ByVal lpTempFileName As String) As Long
Private Declare Function MoveFileExA Lib "kernel32" (ByVal lpExistingFileName As String, ByVal lpNewFileName As String, ByVal dwFlags As Long) As Long
Private Declare Function DeleteFileA Lib "kernel32" (ByVal lpFileName As String) As Long

Private Const MAX_PATH As Long = 260
Private Const MOVEFILE_COPY_ALLOWED As Long = &H2
Private Const MOVEFILE_WRITE_THROUGH As Long = &H8

Private pdf As Object   ' LumasPdf.PDF (late-bound)
Private gCertFile As String

' --- enum values used below (see wrappers\activex\LumasPdfAX.ridl / src\Lumas.Pdf.Types.pas) ---
Private Const if2IncrementalUpd As Long = 256  ' TImportFlags2.if2IncrementalUpd ($100)
Private Const ptOpen As Long = 0               ' TPwdType.ptOpen
Private Const pcTopDown As Long = 1            ' TPageCoord.pcTopDown

Private Function SignFile(ByVal InFileName As String, ByVal OutFileName As String, ByVal FieldName As String, ByVal Reason As String, ByVal PosX As Double, ByVal VisibleSignature As Boolean) As Boolean
    Dim outName As String, tmp As String
    Dim sig As Long, usedTemp As Boolean

    SignFile = False
    outName = OutFileName
    usedTemp = False
    If LCase$(InFileName) = LCase$(OutFileName) Then
        tmp = String$(MAX_PATH + 1, vbNullChar)
        If GetTempFileNameA(App.path, vbNullString, 0, tmp) = 0 Then Exit Function
        tmp = Left$(tmp, InStr(tmp, vbNullChar) - 1)
        outName = tmp
        usedTemp = True
    End If

    pdf.CreateNewPDFW outName

    ' Adding multiple signatures with a demo version would add a demo string to each edited page,
    ' invalidating previous signatures. This special key avoids that.
    pdf.SetLicenseKey "SigDemo"

    ' if2IncrementalUpd also sets ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict.
    pdf.SetImportFlags2 if2IncrementalUpd
    If pdf.OpenImportFileW(InFileName, ptOpen, "") < 0 Then Exit Function
    pdf.ImportPDFFile 1, 1#, 1#

    If VisibleSignature Then
        pdf.SetPageCoords pcTopDown
        pdf.EditPage 1
            sig = pdf.CreateSigField(FieldName, -1, PosX, 30#, 180#, 40#)
            pdf.SetFieldBorderWidth sig, 0#
        pdf.EndPage
    End If

    SignFile = CBool(pdf.CloseAndSignFile(gCertFile, "123456", Reason, ""))
    If SignFile And usedTemp Then
        DeleteFileA OutFileName
        SignFile = (MoveFileExA(outName, OutFileName, MOVEFILE_COPY_ALLOWED Or MOVEFILE_WRITE_THROUGH) <> 0)
    End If
End Function

Public Sub Main()
    Dim filePath As String, srcFile As String

    On Error GoTo ErrHandler

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    ' We write the output file into the application directory.
    filePath = App.path & "\out.pdf"
    srcFile = "E:\LUMASPDFSDK\license.pdf"
    gCertFile = "E:\LUMASPDFSDK\examples\test_files\test_cert.pfx"

    ' We sign the file 4 times: two visible and two invisible signatures.
    If SignFile(srcFile, filePath, "Signature1", "Test signature 1", 50#, True) Then
        If SignFile(filePath, filePath, "Signature2", "Test signature 2", 430#, True) Then
            If SignFile(filePath, filePath, "", "Test signature 3", 0#, False) Then
                If SignFile(filePath, filePath, "", "Test signature 4", 0#, False) Then
                    Debug.Print "PDF file """ & filePath & """ successfully created!"
                    MsgBox "PDF file """ & filePath & """ successfully created!", vbInformation, "multiple_signatures (ActiveX)"
                End If
            End If
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "multiple_signatures (ActiveX)"
End Sub
