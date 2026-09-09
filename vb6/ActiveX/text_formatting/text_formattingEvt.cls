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
' ============================================================================
'  ActiveX/COM version of examples\Vb6\text_formatting\text_formattingEvt.cls
'  (read-only reference, not modified). The flat pdfSetOnPageBreakProc +
'  AddressOf callback becomes the COM event LumasPDF_OnPageBreak, which VB6
'  can only sink through an early-bound WithEvents declaration -- Pdf below
'  carries a project reference to the "LumasPdf PDF engine Automation
'  library" type library so WithEvents has a concrete type to bind to and
'  receive that event. The SAME early-bound Pdf variable is also used for
'  every real engine call, both here in the event handler and in
'  modTextFormatting.Main -- no late-bound alias is needed (see
'  text_formatting.bas for the investigation note on why an earlier version
'  of this example used one).
' ============================================================================
Public WithEvents Pdf As LumasPdfAX.LumasPDF
Attribute Pdf.VB_VarHelpID = -1

' Page-break event. Places the next column or starts a new page.
Private Sub Pdf_OnPageBreak(ByVal LastPosX As Double, ByVal LastPosY As Double, ByVal PageBreak As Boolean, ResultCode As Long)
    Dim x As Double
    Const pcTopDown As Long = 1
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
