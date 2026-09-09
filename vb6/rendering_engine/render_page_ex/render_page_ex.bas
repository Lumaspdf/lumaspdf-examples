Attribute VB_Name = "modRenderPageEx"
Option Explicit
' ============================================================================
'  render_page_ex -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  The GUI on-screen rasterizer (CreateRasterizerEx/RenderPageEx) is not
'  exposed; this mirrors the achievable core: import the first page and render
'  it to a TIFF via RenderPageToImage. Width comes from the screen device caps
'  (Win32), reproducing the original flat-wrapper output byte-for-byte.
' ============================================================================

Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const HORZRES As Long = 8

Public Sub Main()
    Dim pdf As New CPDF
    Dim dc As Long, w As Long
    Dim outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""   ' We create no PDF file in this example
    pdf.SetCMapDirW App.Path & "\..\..\..\Resource\CMap\", lcmRecursive Or lcmDelayed

    If pdf.OpenImportFile(App.Path & "\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

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

    outFile = App.Path & "\render_page_ex.tif"
    If pdf.RenderPageToImageA(1, outFile, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) <> 0 Then
        Debug.Print "Rendered page 1 to " & outFile
    End If
End Sub
