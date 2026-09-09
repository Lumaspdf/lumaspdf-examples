VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior = 0   'vbNone
  MTSTransactionMode = 0   'NotAnMTSObject
END
Attribute VB_Name = "TextExtraction2Evt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' WithEvents sink for the ParseContent COM events (see modTextExtraction2).

Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1
Public PageText As String
Public LastY As Double

' ShowText delivers already-decoded Unicode text + its text-space matrix.
' New line when the baseline Y moves up/down noticeably vs. the last run.
Private Sub Pdf_OnParseShowText(ByVal AText As String, ByVal Width As Double, ByVal M00 As Double, ByVal M01 As Double, ByVal M10 As Double, ByVal M11 As Double, ByVal M20 As Double, ByVal M21 As Double, ResultCode As Long)
    If LastY > -1E+29 Then
        If Abs(M21 - LastY) > 2 Then PageText = PageText & vbCrLf
    End If
    PageText = PageText & AText
    LastY = M21
    ResultCode = 0
End Sub
