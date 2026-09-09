Attribute VB_Name = "modMultipleSignatures"
Option Explicit
' ============================================================================
'  multiple_signatures -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Signs a PDF four times (two
'  visible + two invisible signatures) using incremental updates so each new
'  signature does not invalidate the previous ones. When signing a file in
'  place, a temp file is used and moved over the input. Errors surface as VB6
' pdf.RaiseExceptions = True
' ============================================================================

Private Declare Function GetTempFileNameA Lib "kernel32" (ByVal lpPathName As String, ByVal lpPrefixString As String, ByVal wUnique As Long, ByVal lpTempFileName As String) As Long
Private Declare Function MoveFileExA Lib "kernel32" (ByVal lpExistingFileName As String, ByVal lpNewFileName As String, ByVal dwFlags As Long) As Long
Private Declare Function DeleteFileA Lib "kernel32" (ByVal lpFileName As String) As Long

Private Const MAX_PATH As Long = 260
Private Const MOVEFILE_COPY_ALLOWED As Long = &H2
Private Const MOVEFILE_WRITE_THROUGH As Long = &H8

Private pdf As CPDF
Private gCertFile As String

Private Function SignFile(ByVal InFileName As String, ByVal OutFileName As String, ByVal FieldName As String, ByVal Reason As String, ByVal PosX As Double, ByVal VisibleSignature As Boolean) As Boolean
    Dim outName As String, tmp As String
    Dim sig As Long, usedTemp As Boolean

    SignFile = False
    outName = OutFileName
    usedTemp = False
    If LCase$(InFileName) = LCase$(OutFileName) Then
        tmp = String$(MAX_PATH + 1, vbNullChar)
        If GetTempFileNameA(App.Path, vbNullString, 0, tmp) = 0 Then Exit Function
        tmp = Left$(tmp, InStr(tmp, vbNullChar) - 1)
        outName = tmp
        usedTemp = True
    End If

    pdf.CreateNewPDF outName

    ' Adding multiple signatures with a demo version would add a demo string to each edited page,
    ' invalidating previous signatures. This special key avoids that.
    pdf.SetLicenseKey "SigDemo"

    ' if2IncrementalUpd also sets ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict.
    pdf.SetImportFlags2 if2IncrementalUpd
    If pdf.OpenImportFile(InFileName, ptOpen, "") < 0 Then Exit Function
    pdf.ImportPDFFile 1, 1#, 1#

    If VisibleSignature Then
        pdf.SetPageCoords pcTopDown
        pdf.EditPage 1
            sig = pdf.CreateSigField(FieldName, -1, PosX, 30#, 180#, 40#)
            pdf.SetFieldBorderWidth sig, 0#
        pdf.EndPage
    End If

    SignFile = (pdf.CloseAndSignFile(gCertFile, "123456", Reason, "") <> 0)
    If SignFile And usedTemp Then
        DeleteFileA OutFileName
        SignFile = (MoveFileExA(outName, OutFileName, MOVEFILE_COPY_ALLOWED Or MOVEFILE_WRITE_THROUGH) <> 0)
    End If
End Function

Public Sub Main()
    Dim Pdf As New CPDF
    Dim pdf As New CPDF
    Dim filePath As String, srcFile As String

    Set pdf = New CPDF
' pdf.RaiseExceptions = True

    ' We write the output file into the application directory.
    filePath = App.Path & "\out.pdf"
    srcFile = "E:\LUMASPDFSDK\license.pdf"
    gCertFile = "E:\LUMASPDFSDK\examples\test_files\test_cert.pfx"

    ' We sign the file 4 times: two visible and two invisible signatures.
    If SignFile(srcFile, filePath, "Signature1", "Test signature 1", 50#, True) Then
        If SignFile(filePath, filePath, "Signature2", "Test signature 2", 430#, True) Then
            If SignFile(filePath, filePath, "", "Test signature 3", 0#, False) Then
                If SignFile(filePath, filePath, "", "Test signature 4", 0#, False) Then
                    Debug.Print "PDF file """ & filePath & """ successfully created!"
                End If
            End If
        End If
    End If
End Sub
