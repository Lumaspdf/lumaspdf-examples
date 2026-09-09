Attribute VB_Name = "modRenderPage"
Option Explicit
' ============================================================================
'  render_page -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors the
'  plain-DLL example at examples\Vb6\rendering_engine\render_page (read-only
'  reference, not modified). The GUI on-screen rasterizer is not used here;
'  this reproduces the achievable core: import the first page of a PDF and
'  render it to a TIFF via RenderPageToImageA. Width comes from the screen
'  device caps (Win32), matching the reference's output.
'
'  Mapping: pdfXxx(IPDF, args) -> pdf.Xxx(args) (handle dropped, implicit via
'  the pdf object).
' ============================================================================

Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const HORZRES As Long = 8

' ---- LumasPdf enum constants (no project reference -> declared by value) ---
Private Const ptOpen As Long = 0                     ' TPasswordType
Private Const lcmRecursive As Long = 1                ' TLoadCMapFlags
Private Const lcmDelayed As Long = 2
Private Const ifContentOnly As Long = &H0&            ' TImportFlags
Private Const ifImportAll As Long = &HFFFFFFE
Private Const ifImportAsPage As Long = &H80000000
Private Const if2UseProxy As Long = &H4               ' TImportFlags2
Private Const rfDefault As Long = &H0                 ' TRasterFlags
Private Const pxfRGB As Long = 2                      ' TPDFPixFormat
Private Const cfLZW As Long = 4                       ' TCompressionFilter
Private Const ifmTIFF As Long = 0                     ' TImageFormat

Public Sub Main()
    Dim pdf As Object
    Dim dc As Long, w As Long
    Dim outFile As String

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFA ""   ' We create no PDF file in this example
    ' lcmDelayed loads the cmaps only if necessary.
    pdf.SetCMapDirA App.path & "\..\..\..\..\Resource\CMap\", lcmRecursive Or lcmDelayed

    If pdf.OpenImportFileA(App.path & "\..\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

    ' Import pages manually: only the output intent is needed for color management, then reset.
    pdf.SetImportFlags ifContentOnly
    pdf.ImportCatalogObjects
    pdf.SetImportFlags ifImportAll Or ifImportAsPage   ' don't convert pages to templates
    pdf.SetImportFlags2 if2UseProxy                    ' reduces memory usage

    If pdf.GetInPageCount() < 1 Then Exit Sub

    ' We render only the first page in this example.
    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    If pdf.GetPageObject(1) = 0 Then Exit Sub

    dc = GetDC(0)
    w = GetDeviceCaps(dc, HORZRES)
    ReleaseDC 0, dc

    outFile = App.path & "\render_page.tif"
    If pdf.RenderPageToImageA(1, outFile, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) Then
        Debug.Print "Rendered page 1 to " & outFile
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "render_page"
End Sub
