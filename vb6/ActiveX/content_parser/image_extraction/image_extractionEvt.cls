VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior = 0   'vbNone
  MTSTransactionMode = 0   'NotAnMTSObject
END
Attribute VB_Name = "ImageExtractionEvt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' WithEvents sink for the ParseContentEvents COM events fired by the LumasPdf
' ActiveX component (see modImageExtraction). VB6's WithEvents requires a
' compile-time-typed (early-bound) reference, so this project (unlike the
' late-bound complex_text/hello_world-style examples) carries one project
' Reference to the LumasPdfAX type library -- the only way to sink COM
' connection-point events in VB6. All pdf.Xxx calls in modImageExtraction are
' made through THIS SAME ev.Pdf instance (not a second, separate object) so
' that the events this sink receives actually correspond to the operations
' being performed.

Public WithEvents Pdf As LumasPdfAX.LumasPDF
Attribute Pdf.VB_VarHelpID = -1
Public Count As Long
Public Csv As String
Public Page As Long

' InsertImage carries geometry (not pixels): width, height, bpp, 4 dest corners.
' HONEST LIMITATION (same as the flat-DLL reference): rebuilding the actual
' image pixels would require the decompressed pixel buffer, which this COM
' event does not carry -- so, like the original, this reports image metadata
' (detection) rather than re-emitting pixels.
Private Sub Pdf_OnParseInsertImage(ByVal AWidth As Long, ByVal AHeight As Long, ByVal BitsPerPixel As Long, ByVal X1 As Double, ByVal Y1 As Double, ByVal X2 As Double, ByVal Y2 As Double, ByVal X3 As Double, ByVal Y3 As Double, ByVal X4 As Double, ByVal Y4 As Double, ResultCode As Long)
    Count = Count + 1
    Csv = Csv & Page & "," & AWidth & "," & AHeight & "," & BitsPerPixel & "," & _
          X1 & "," & Y1 & "," & X2 & "," & Y2 & "," & X3 & "," & Y3 & "," & X4 & "," & Y4 & vbCrLf
    ResultCode = 0
End Sub
