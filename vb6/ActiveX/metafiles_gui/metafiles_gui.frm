VERSION 5.00
Begin VB.Form frmMetafilesGui
   Caption         =   "LumasPdf ActiveX - Metafile Viewer/Converter"
   ClientHeight    =   6045
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   8055
   LinkTopic       =   "Form1"
   ScaleHeight     =   6045
   ScaleWidth       =   8055
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdConvert
      Caption         =   "Convert to PDF"
      Height          =   495
      Left            =   120
      TabIndex        =   1
      Top             =   5460
      Width           =   1935
   End
   Begin VB.PictureBox picPreview
      BackColor       =   &H80000005&
      Height          =   5175
      Left            =   120
      ScaleHeight     =   5115
      ScaleWidth       =   7755
      TabIndex        =   0
      Top             =   120
      Width           =   7815
   End
   Begin VB.Label lblStatus
      Alignment       =   1  'Right Justify
      Caption         =   "Ready"
      Height          =   255
      Left            =   2280
      TabIndex        =   2
      Top             =   5520
      Width           =   5655
   End
End
Attribute VB_Name = "frmMetafilesGui"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
' ============================================================================
'  metafiles_gui -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no project
'  reference required. Equivalent of ../../../Vb6/metafiles_gui (flat-DLL /
'  CPDF.cls wrapper style, itself a plain Sub Main() reproduction of the
'  Delphi original's Forms-based metafile viewer/converter -- see that
'  module's header comment). The Delphi original's real UI shape (a metafile
'  viewer/converter form, PDF logic in tbConvertClick) is restored here as a
'  genuine VB6 Form: picPreview shows the EMF (a real device-context-backed
'  StdPicture, loaded via LoadPicture) and cmdConvert_Click runs the exact
'  same PDF-authoring call sequence as the flat-DLL Sub Main, now against the
'  LumasPdf ActiveX server.
'
'  GetLogMetafileSize is exposed by the AX server as four [in,out] VARIANT
'  out-parameters (Left/Top/Right/Bottom) -- see wrappers\activex\LumasPdfAX.ridl.
'
'  pdf.RaiseExceptions = True turns internal engine errors into VB6 runtime
'  errors, caught below via On Error GoTo ErrHandler.
' ============================================================================

Private Const MARGIN As Double = 10#

' --- enum values used below (see wrappers\activex\LumasPdfAX.ridl / src\Lumas.Pdf.Types.pas) ---
Private Const cfFlate As Long = 0          ' TCompressionFilter.cfFlate
Private Const clNone As Long = 0           ' TCompressionLevel.clNone
Private Const csDeviceRGB As Long = 0      ' TPDFColorSpace.csDeviceRGB
Private Const mfDefault As Long = 0        ' TMetaConvFlags.mfDefault
Private Const pcTopDown As Long = 1        ' TPageCoord.pcTopDown

Private pdf As Object   ' LumasPdf.PDF (late-bound)
Private inFile As String, outFile As String

Private Sub Form_Load()
    inFile = App.path & "\in.emf"
    outFile = App.path & "\out.pdf"

    ' Real device-context-backed preview: VB6's LoadPicture natively decodes
    ' EMF/WMF into a StdPicture and PaintPicture blits it through the
    ' PictureBox's own hDC, exactly what the Delphi original's metafile
    ' viewer did with a TMetafile/TImage.
    On Error Resume Next
    picPreview.Picture = LoadPicture(inFile)
    On Error GoTo 0
    picPreview.AutoRedraw = True
    RenderPreview

    lblStatus.Caption = "Loaded: " & inFile
End Sub

Private Sub picPreview_Resize()
    RenderPreview
End Sub

Private Sub RenderPreview()
    If picPreview.Picture Is Nothing Then Exit Sub
    picPreview.Cls
    picPreview.PaintPicture picPreview.Picture, 0, 0, picPreview.ScaleWidth, picPreview.ScaleHeight
End Sub

Private Sub cmdConvert_Click()
    On Error GoTo ErrHandler

    cmdConvert.Enabled = False
    lblStatus.Caption = "Converting..."
    DoEvents

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    ' We use flate compression for better transparency support.
    pdf.SetCompressionFilter cfFlate
    pdf.SetJPEGQuality 70

    If Not CBool(pdf.CreateNewPDFW("")) Then Exit Sub

    pdf.SetCompressionLevel clNone          ' "compress" checkbox default off
    pdf.SetCompressionFilter cfFlate        ' "JPEG" checkbox default off
    pdf.SetColorSpace csDeviceRGB           ' "CMYK" checkbox default off
    pdf.SetMetaConvFlags mfDefault          ' no preview flags selected
    pdf.SetPageCoords pcTopDown
    pdf.Append
    pdf.SetResolution 300
    pdf.SetJPEGQuality 70
    PlaceEMFCentered inFile, pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    If CBool(pdf.HaveOpenDoc()) Then
        If Not CBool(pdf.OpenOutputFileW(outFile)) Then Exit Sub
        If CBool(pdf.CloseFile()) Then
            Debug.Print "OK: " & outFile
            lblStatus.Caption = "OK: " & outFile
            MsgBox "PDF file """ & outFile & """ successfully created!", vbInformation, "metafiles_gui (ActiveX)"
        End If
    End If
    cmdConvert.Enabled = True
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    lblStatus.Caption = "Failed: " & Err.Description
    cmdConvert.Enabled = True
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "metafiles_gui (ActiveX)"
End Sub

' Places a metafile (given by file name) centered on the page, preserving the
' aspect ratio. Mirrors the flat-DLL PlaceEMFCentered helper 1:1.
Private Sub PlaceEMFCentered(ByVal MFile As String, ByVal Width_ As Double, ByVal Height_ As Double)
    Dim x As Double, y As Double, w As Double, h As Double, sx As Double
    Dim l As Variant, t As Variant, rt As Variant, b As Variant

    pdf.GetLogMetafileSize MFile, l, t, rt, b
    w = rt - l
    h = b - t
    Width_ = Width_ - 2# * MARGIN
    Height_ = Height_ - 2# * MARGIN
    sx = Width_ / w
    If (h * sx <= Height_) Then
        x = MARGIN
        y = MARGIN
        pdf.InsertMetafile MFile, x, y, Width_, 0#
    Else
        sx = Height_ / h
        w = w * sx
        x = MARGIN + (Width_ - w) / 2#
        y = MARGIN
        pdf.InsertMetafile MFile, x, y, 0#, Height_
    End If
End Sub
