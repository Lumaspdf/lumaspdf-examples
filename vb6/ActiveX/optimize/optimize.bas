Attribute VB_Name = "modOptimize"
Option Explicit
' ============================================================================
'  optimize -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\optimize -- same feature: import dynapdf_help.pdf, run
'  Optimize() over it with a set of flags, write the optimized result to
'  out.pdf.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""      -> pdf.CreateNewPDFW ""
'    pdf.OpenImportFile ...   -> pdf.OpenImportFileW ...
'    pdf.OpenOutputFile ...   -> pdf.OpenOutputFileW ...
'  Optimize(Flags, Parms) is unchanged -- Parms is a VARIANT; Array() (an
'  empty positional array) means "keep all TOptimizeParams defaults", exactly
'  as in the Declare-style original.
' ============================================================================

'--- TImportFlags (see wrappers\vb6\LumasPDFInt.bas) ----------------------------
Const ifImportAll As Long = &HFFFFFFE
Const ifImportAsPage As Long = &H80000000
Const ifPieceInfo As Long = &H2000000

'--- TImportFlags2 --------------------------------------------------------------
Const if2Normalize As Long = &H2
Const if2UseProxy As Long = &H4
Const if2DuplicateCheck As Long = &H10
Const if2NoResNameCheck As Long = &H20

'--- TPwdType --------------------------------------------------------------------
Const ptOpen As Long = 0

'--- TOptimizeFlags --------------------------------------------------------------
Const ofInMemory As Long = &H1
Const ofNewLinkNames As Long = &H20
Const ofDeleteInvPaths As Long = &H40

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim outFile As String, inFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""                             ' output file opened later

    ' ifImportAsPage avoids converting pages to templates; drop the piece info dictionary.
    pdf.SetImportFlags (ifImportAll Or ifImportAsPage) And Not ifPieceInfo
    ' if2UseProxy reduces memory usage; duplicate check + normalize recommended.
    pdf.SetImportFlags2 if2UseProxy Or if2DuplicateCheck Or if2Normalize Or if2NoResNameCheck

    inFile = App.Path & "\dynapdf_help.pdf"
    If pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then
        Debug.Print "Could not open import file!"
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' Optimize with default parameters (Array() = keep defaults / zero).
    pdf.Optimize ofInMemory Or ofNewLinkNames Or ofDeleteInvPaths, Array()

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc) Then
        outFile = App.Path & "\out.pdf"
        If CBool(pdf.OpenOutputFileW(outFile)) Then
            If CBool(pdf.CloseFile()) Then
                Debug.Print "PDF file """ & outFile & """ successfully created!"
            End If
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "optimize (ActiveX)"
End Sub
