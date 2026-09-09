VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TextFormattingEvt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1

' Page-break event. Places the next column or starts a new page.
Private Sub Pdf_OnPageBreak(ByVal LastPosX As Double, ByVal LastPosY As Double, ByVal PageBreak As Boolean, ResultCode As Long)
    Dim x As Double
    Pdf.SetPageCoords pcTopDown            ' we use top down coordinates
    gColumn = gColumn + 1
    ' PageBreak is True if the string contains an explicit page-break tag.
    If (Not PageBreak) And (gColumn < gColCount) Then
        ' change the output rectangle to the next column, do NOT close the page
        x = gPosX + gColumn * (gWidth + gDistance)
        Pdf.SetTextRect x, gPosY, gWidth, gHeight
    Else
        ' the page is full: close it and append a new one
        Pdf.EndPage
        Pdf.Append
        Pdf.SetTextRect gPosX, gPosY, gWidth, gHeight
        gColumn = 0
    End If
    ResultCode = 0                          ' we do not change the alignment
End Sub

Private Sub Pdf_OnError(ByVal ErrCode As Long, ByVal ErrMsg As String, ByVal ErrType As Long, ResultCode As Long)
    ResultCode = 0
End Sub
