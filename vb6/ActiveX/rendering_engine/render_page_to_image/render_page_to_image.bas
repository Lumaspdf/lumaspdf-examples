Attribute VB_Name = "modRenderPageToImage"
Option Explicit
' ============================================================================
'  render_page_to_image -- ActiveX/COM version (LumasPdf.PDF, late-bound),
'  mirrors the plain-DLL example at
'  examples\Vb6\rendering_engine\render_page_to_image (read-only reference,
'  not modified). Loads a PDF, imports the first page and renders it to a
'  TIFF image file via RenderPageToImageA. Width comes from the screen device
'  caps (Win32), matching the reference's output.
' ============================================================================

Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const HORZRES As Long = 8

Private Const ptOpen As Long = 0
Private Const ifImportAll As Long = &HFFFFFFE
Private Const ifImportAsPage As Long = &H80000000
Private Const rfDefault As Long = &H0
Private Const pxfRGB As Long = 2
Private Const cfLZW As Long = 4
Private Const ifmTIFF As Long = 0

Public Sub Main()
    Dim pdf As Object
    Dim dc As Long, w As Long
    Dim filePath As String

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFA ""   ' We create no PDF file in this example

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFileA(App.path & "\..\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

    ' We render only the first page in this example.
    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    dc = GetDC(0)
    w = GetDeviceCaps(dc, HORZRES)
    ReleaseDC 0, dc

    filePath = App.path & "\out.tif"
    If pdf.RenderPageToImageA(1, filePath, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) Then
        Debug.Print "TIFF image """ & filePath & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "render_page_to_image"
End Sub
