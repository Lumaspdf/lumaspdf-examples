VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior = 0   'vbNone
  MTSTransactionMode = 0   'NotAnMTSObject
END
Attribute VB_Name = "TextCoordinatesEvt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' WithEvents sink for the ParseContentEvents COM events (see
' modTextCoordinates). See image_extractionEvt.cls for why this example
' needs early binding (one project Reference) unlike most other ActiveX
' examples in this codebase: VB6's WithEvents requires a compile-time-typed
' variable, which is the only way to sink COM connection-point events.

Public WithEvents Pdf As LumasPdfAX.LumasPDF
Attribute Pdf.VB_VarHelpID = -1
Public Toggle As Long

' VCL TColor values (COLORREF): red in low byte, blue in high byte.
Private Const clRed As Long = 255
Private Const clBlue As Long = 16711680

' Draw a baseline under each text run: (M20,M21) -> (M20 + Width*scaleX, M21),
' alternating red/blue like the flat-DLL reference.
Private Sub Pdf_OnParseShowText(ByVal AText As String, ByVal Width As Double, ByVal M00 As Double, ByVal M01 As Double, ByVal M10 As Double, ByVal M11 As Double, ByVal M20 As Double, ByVal M21 As Double, ResultCode As Long)
    Dim scaleX As Double
    ResultCode = 0
    If Len(AText) = 0 Then Exit Sub
    scaleX = M00
    If scaleX = 0 Then scaleX = 1
    If Toggle = 0 Then Pdf.SetStrokeColor clRed Else Pdf.SetStrokeColor clBlue
    Toggle = 1 - Toggle
    Pdf.MoveTo M20, M21
    Pdf.LineTo M20 + Width * scaleX, M21
    Pdf.StrokePath
End Sub
