Attribute VB_Name = "modConvertConformance"
Option Explicit
' ============================================================================
'  convert_conformance -- ActiveX/COM (LumasPdf.PDF) port of
'  ..\..\convert_conformance\convert_conformance.bas (native Declare-based
'  CPDF.cls wrapper around the flat pdfConvertFileA/W C API).
'
'  Demonstrates: a single one-call conversion of a plain PDF into both PDF/A
'  and PDF/X via the ActiveX ConvertFile method -- the COM-visible collapse of
'  the flat API's pdfConvertFileW(IPDF, InFile, OutFile, ConfType, Flags,
'  RGBProfile, CMYKProfile, OwnerPwd, UserData, OnFontNotFound,
'  OnReplaceICCProfile) down to a 7-argument
'  ConvertFile(InFile, OutFile, ConfType, Flags, RGBProfile, CMYKProfile,
'  OwnerPwd) call (the UserData/callback trio has no COM-safe equivalent and
'  is simply dropped, exactly as the reference native example already notes).
'
'  TConformanceType values (see src\Lumas.Pdf.Types.pas / wrappers\vb6\
'  LumasPDFInt.bas) are late-bound plain Longs here since CreateObject gives
'  no typelib enum access:
'     ctPDFA_2b = 2   (sRGB + ISOcoated CMYK profiles get embedded)
'     ctPDFX_4  = 24
'
'  A compiled GUI exe has no stdout, so both rc lines are also written to
'  result.txt next to the exe (and Debug.Print'd in the IDE), matching the
'  native example's own convention.
' ============================================================================

Const ctPDFA_2b As Long = 2
Const ctPDFX_4 As Long = 24

' Shared SDK test assets -- referenced by absolute path so the compiled exe
' does not depend on the caller's current working directory.
Const TEST_FILES As String = "E:\LUMASPDFSDK\examples\test_files\"

Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    Dim a As Long, x As Long, f As Integer
    Dim outPDFA As String, outPDFX As String
    outPDFA = App.Path & "\out_pdfa.pdf"
    outPDFX = App.Path & "\out_pdfx.pdf"

    ' ctPDFA_2b = 2 ; sRGB + ISOcoated CMYK profiles embedded
    a = pdf.ConvertFile(TEST_FILES & "plain.pdf", outPDFA, ctPDFA_2b, 0, _
            TEST_FILES & "sRGB.icc", TEST_FILES & "ISOcoated_v2_bas.ICC", "")
    Debug.Print "plain -> PDF/A (ctPDFA_2b) rc=" & a

    ' ctPDFX_4 = 24
    x = pdf.ConvertFile(TEST_FILES & "plain.pdf", outPDFX, ctPDFX_4, 0, _
            TEST_FILES & "sRGB.icc", TEST_FILES & "ISOcoated_v2_bas.ICC", "")
    Debug.Print "plain -> PDF/X (ctPDFX_4)  rc=" & x

    f = FreeFile
    Open App.Path & "\result.txt" For Output As #f
    Print #f, "plain -> PDF/A (ctPDFA_2b) rc=" & a
    Print #f, "plain -> PDF/X (ctPDFX_4)  rc=" & x
    Close #f

    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "convert_conformance (ActiveX)"
End Sub
