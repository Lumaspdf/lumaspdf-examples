Attribute VB_Name = "modEditPage"
Option Explicit
' ============================================================================
'  edit_page (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  Same feature as the flat-DLL "edit_page" example: imports a rotated page,
'  opens it for editing and writes formatted (\LI/\LD list-style) text onto
'  it via WriteFTextEx, demonstrating orientation + visible-coordinate
'  handling for edited/imported pages.
'
'  Mapping from the flat CPDF.cls calls (see the read-only reference at
'  examples\Vb6\edit_page\edit_page.bas):
'    pdf.CreateNewPDF ""                  -> pdf.CreateNewPDFA("")
'    pdf.OpenImportFile(path, pt, pwd)    -> pdf.OpenImportFileA(path, pt, pwd)
'    pdf.SetFont(Name, Style, Size, Embed, CP) -> pdf.SetFontA(Name, Style, Size, Embed, CP)
'    pdf.WriteFTextEx(...)                 -> pdf.WriteFTextExA(...)
'    pdf.OpenOutputFile(path)               -> pdf.OpenOutputFileA(path)
'    everything else (SetImportFlags, ImportPDFFile, CloseImportFile,
'    SetPageCoords, SetUseVisibleCoords, EditPage, GetOrientation,
'    SetOrientationEx, SetLeading, SetListFont, EndPage, HaveOpenDoc,
'    CloseFile, GetPageWidth) -> unchanged (already bare ActiveX names)
'  Enum values (ifImportAll, ifImportAsPage, ptOpen, pcTopDown, fsRegular,
'  cp1252, taJustify) copied verbatim from wrappers\vb6\LumasPDFInt.bas /
'  LumasPdfAX.ridl since a late-bound Object has no compile-time typelib
'  enums.
' ============================================================================

Const ifImportAll As Long = &HFFFFFFE      ' TImportFlags: default (import everything)
Const ifImportAsPage As Long = &H80000000  ' TImportFlags: don't convert page to template
Const ptOpen As Long = 0                   ' TPwdType: open password
Const pcTopDown As Long = 1                ' TPageCoords: top-down
Const fsRegular As Long = 419430400        ' TFStyle: regular
Const cp1252 As Long = 2                   ' TCodepage: Windows-1252
Const taJustify As Long = 3                ' TTextAlign: justify

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object                      ' LumasPdf.PDF (late-bound)
    Dim f As Long, orientation As Long
    Dim inFile As String, outFile As String, s As String
    Dim B As String, CR As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True             ' turn engine errors into VB6 errors

    If Not CBool(pdf.CreateNewPDFA("")) Then Err.Raise vbObjectError + 1, , "CreateNewPDFA failed"

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage

    ' NOTE: examples\test_files\rotated_270.pdf is a small unrelated placeholder;
    ' the real rotated/scanned page used by every language port of this example
    ' (incl. the flat-DLL reference examples\Vb6\edit_page\rotated_270.pdf) is
    ' the shared asset in examples\c\edit_page\.
    inFile = "E:\LUMASPDFSDK\examples\c\edit_page\rotated_270.pdf"
    If pdf.OpenImportFileA(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    pdf.SetPageCoords pcTopDown
    ' Move the coordinate origin into the visible area.
    pdf.SetUseVisibleCoords True

    pdf.EditPage 1
        orientation = pdf.GetOrientation
        If orientation <> 0 Then pdf.SetOrientationEx orientation
        pdf.SetLeading 14#
        f = pdf.SetFontA("Helvetica", fsRegular, 12#, False, cp1252)
        pdf.SetListFont f

        ' We call the ANSI (A) export, so the bullet is code page 1252 char 144.
        B = Chr$(144)
        CR = Chr$(13)
        s = "It is not difficult to edit an imported page but two things must be considered:" & CR & CR & "\LI[20," & B & "]\LD[16]The page's " _
          & "orientation.\EL#\LI[20," & B & "]\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#" & CR & "\LD[12]" _
          & "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. DynaPDF moves the zero point then automatically " _
          & "into the visible area of the page." & CR & CR _
          & "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present." & CR & CR _
          & "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated " _
          & "into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file." & CR & CR _
          & "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was " _
          & "not rotated. If this produces a wrong result then don't call SetOrientationEx()." & CR & CR _
          & "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() " _
          & "and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents."

        pdf.WriteFTextExA 50#, 200#, pdf.GetPageWidth - 100#, -1#, taJustify, s
    pdf.EndPage

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileA(outFile)) Then Exit Sub
        If CBool(pdf.CloseFile()) Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If

    Set pdf = Nothing
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "edit_page (ActiveX)"
End Sub
