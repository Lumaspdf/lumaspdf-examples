Attribute VB_Name = "modSoftmask"
Option Explicit
' ============================================================================
'  softmask -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors the
'  plain-DLL example at examples\Vb6\transparency\softmask (read-only
'  reference, not modified). Creates a transparency group used as a
'  luminosity soft mask (radial shading) and applies it to an image.
'
'  CreateExtGState takes a positional Variant array overlay of TPDFExtGState:
'  SoftMask is index 13 (the handle from CreateSoftMask), SoftMaskNone is
'  index 12. ComputeBBox returns the four box edges as separate [in,out]
'  Variant parameters (instead of the flat TPDFRect record). The whole call
'  chain is late-bound throughout, so CreateSoftMask's Int64 return value and
'  PlaceImage/InsertImageEx's handles marshal transparently -- no early-bound
'  object-view workaround is needed here.
' ============================================================================

Private Const fsRegular As Long = &H19000000
Private Const cp1252 As Long = 2
Private Const pcTopDown As Long = 1
Private Const esDeviceGray As Long = 2      ' TExtColorSpace
Private Const csDeviceGray As Long = 2      ' TPDFColorSpace
Private Const smtLuminosity As Long = 1     ' TSoftMaskType
Private Const cbfNone As Long = 0           ' TCompBBoxFlags
Private Const pbMediaBox As Long = 4        ' TPageBoundary

Public Sub Main()
    Dim pdf As Object
    Dim gs As Long, grp As Long, sh As Long, smHandle As Variant
    Dim outFile As String
    Dim g As Variant
    Dim bl As Variant, bb As Variant, br As Variant, bt As Variant

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True
    pdf.CreateNewPDFA ""              ' The output file is opened later

    pdf.SetPageCoords pcTopDown
    pdf.SetUseTransparency 0          ' Disable color key masking for images

    pdf.Append

    pdf.SetFontA "Helvetica", fsRegular, 12#, False, cp1252
    pdf.WriteTextA 50#, 50#, "Transparency effect with a soft mask."

    pdf.InsertImageEx 50#, 80#, pdf.GetPageWidth() - 100#, 0#, App.path & "\..\..\..\..\..\examples\test_files\images\meadow-110719_640.jpg", 1

    ' A transparency group used as a soft mask has no own coordinate system.
    grp = pdf.BeginTransparencyGroup(0#, 0#, pdf.GetPageWidth(), pdf.GetPageHeight(), 1, 0, esDeviceGray, -1)
        pdf.SetColorSpace csDeviceGray
        sh = pdf.CreateRadialShading(400#, 230#, 20#, 400#, 230#, 150#, 1#, 255, 0, 1, 0)
        pdf.ApplyShading sh
        ' Optional but recommended: compute the real bounding box of the group.
        pdf.ComputeBBox bl, bb, br, bt, cbfNone
        pdf.SetBBox pbMediaBox, bl, bb, br, bt
    pdf.EndTemplate

    ' SoftMask = handle from CreateSoftMask (TPDFExtGState index 13).
    smHandle = pdf.CreateSoftMask(grp, smtLuminosity, 0)
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, smHandle)
    gs = pdf.CreateExtGState(g)

    ' Activate the mask and draw an image.
    pdf.SetExtGState gs
    pdf.InsertImageEx 220#, 80#, 500#, 0#, App.path & "\..\..\..\..\..\examples\test_files\images\tree-frog-69813_640.jpg", 1

    ' Deactivate the soft mask: SoftMaskNone = 1 (index 12).
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 1)
    gs = pdf.CreateExtGState(g)
    pdf.SetExtGState gs

    pdf.WriteTextA 50#, 400#, "The soft mask is now deactivated."
    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        outFile = App.path & "\out.pdf"
        If Not pdf.OpenOutputFileA(outFile) Then Exit Sub
        If pdf.CloseFile() Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "softmask"
End Sub
