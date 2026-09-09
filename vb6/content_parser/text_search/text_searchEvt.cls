VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior = 0   'vbNone
  MTSTransactionMode = 0   'NotAnMTSObject
END
Attribute VB_Name = "TextSearchEvt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' WithEvents sink for the ParseContent COM events (see modTextSearch).

Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1
Public TextSize As Double
Public PageHits As Long
Public GS As Long

Private Const NEEDLE As String = "PDF"

Private Sub Pdf_OnParseSetFont(ByVal FontName As String, ByVal AStyle As Long, ByVal FontSize As Double, ByVal Embedded As Boolean, ResultCode As Long)
    TextSize = FontSize
    ResultCode = 0
End Sub

' ShowText: search the decoded run for NEEDLE; for each occurrence draw a
' proportional highlight rectangle. M20/M21 = run origin (page coords);
' Width = run advance; height ~ font size.
Private Sub Pdf_OnParseShowText(ByVal AText As String, ByVal Width As Double, ByVal M00 As Double, ByVal M01 As Double, ByVal M10 As Double, ByVal M11 As Double, ByVal M20 As Double, ByVal M21 As Double, ResultCode As Long)
    Dim n As Long, pos As Long
    Dim scaleX As Double, h As Double, x0 As Double, wRun As Double
    ResultCode = 0
    n = Len(AText)
    If n = 0 Then Exit Sub
    scaleX = M00
    If scaleX = 0 Then scaleX = 1
    h = TextSize * Abs(M11)
    If h <= 0 Then h = TextSize
    pos = 1
    Do
        pos = InStr(pos, AText, NEEDLE, vbTextCompare)   ' case-insensitive
        If pos = 0 Then Exit Do
        PageHits = PageHits + 1
        x0 = M20 + Width * ((pos - 1) / n) * scaleX
        wRun = Width * (Len(NEEDLE) / n) * scaleX
        Pdf.Rectangle x0, M21, wRun, h, fmFill
        pos = pos + Len(NEEDLE)
    Loop
End Sub
