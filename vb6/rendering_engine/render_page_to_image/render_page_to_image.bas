Attribute VB_Name = "modRenderPageToImage"
Option Explicit
' ============================================================================
'  render_page_to_image -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Loads a PDF, imports the first page and renders it to a TIFF image file via
'  RenderPageToImage. Width comes from the screen device caps (Win32),
'  reproducing the original flat-wrapper output byte-for-byte.
' ============================================================================

Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const HORZRES As Long = 8

Public Sub Main()
    Dim pdf As New CPDF
    Dim dc As Long, w As Long
    Dim filePath As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""   ' We create no PDF file in this example

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(App.Path & "\..\..\..\..\sample_multipage.pdf", ptOpen, "") < 0 Then Exit Sub

    ' We render only the first page in this example.
    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    dc = GetDC(0)
    w = GetDeviceCaps(dc, HORZRES)
    ReleaseDC 0, dc

    filePath = App.Path & "\out.tif"
    If pdf.RenderPageToImageA(1, filePath, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) <> 0 Then
        Debug.Print "TIFF image """ & filePath & """ successfully created!"
    End If
End Sub
