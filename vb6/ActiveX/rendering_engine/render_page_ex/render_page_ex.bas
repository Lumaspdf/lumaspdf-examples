Attribute VB_Name = "modRenderPageEx"
Option Explicit
' ============================================================================
'  render_page_ex -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at examples\Vb6\rendering_engine\render_page_ex
'  (read-only reference, not modified). The GUI on-screen rasterizer is not
'  used here; this reproduces the achievable core: import the first page and
'  render it to a TIFF via RenderPageToImageA. Width comes from the screen
'  device caps (Win32), matching the reference's output.
' ============================================================================

Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const HORZRES As Long = 8

Private Const ptOpen As Long = 0
Private Const lcmRecursive As Long = 1
Private Const lcmDelayed As Long = 2
Private Const ifContentOnly As Long = &H0&
Private Const ifImportAll As Long = &HFFFFFFE
Private Const ifImportAsPage As Long = &H80000000
Private Const if2UseProxy As Long = &H4
Private Const rfDefault As Long = &H0
Private Const pxfRGB As Long = 2
Private Const cfLZW As Long = 4
Private Const ifmTIFF As Long = 0

Public Sub Main()
    Dim pdf As Object
    Dim dc As Long, w As Long
    Dim outFile As String

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFA ""   ' We create no PDF file in this example
    pdf.SetCMapDirA App.path & "\..\..\..\..\Resource\CMap\", lcmRecursive Or lcmDelayed

    If pdf.OpenImportFileA(App.path & "\..\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

    pdf.SetImportFlags ifContentOnly
    pdf.ImportCatalogObjects
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    pdf.SetImportFlags2 if2UseProxy

    If pdf.GetInPageCount() < 1 Then Exit Sub

    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    If pdf.GetPageObject(1) = 0 Then Exit Sub

    dc = GetDC(0)
    w = GetDeviceCaps(dc, HORZRES)
    ReleaseDC 0, dc

    outFile = App.path & "\render_page_ex.tif"
    If pdf.RenderPageToImageA(1, outFile, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) Then
        Debug.Print "Rendered page 1 to " & outFile
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "render_page_ex"
End Sub
