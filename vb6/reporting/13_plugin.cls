VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Fn13Evt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' PlugDouble(x) = x*2 registered plugin-free via the AX function event.

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1

Private mEng As Long

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer, b() As Byte
    f = FreeFile
    On Error Resume Next
    Kill Path
    On Error GoTo 0
    b = StrConv(Content, vbFromUnicode)
    Open Path For Binary Access Write As #f
    Put #f, 1, b
    Close #f
End Sub

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""CustomExt"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
    s = s & "   <text name=""p1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">PlugDouble('21') = {{expr: PlugDouble('21') }}</text>" & vbLf
    s = s & "   <text name=""p2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">PlugDouble('2.5') = {{expr: PlugDouble('2.5') }}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

Public Sub Run()
    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, OutTxt As String

    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = Pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.LastErrorMessage: Exit Sub

    If Not Pdf.RptRegisterFunctionEvent(mEng, "PlugDouble", 1) Then
        Debug.Print "RptRegisterFunctionEvent failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    End If
    ' Custom EXPORTER (target 100) -- registered plugin-free via the AX exporter
    ' event (RptRegisterExporterEvent + OnRptExport), full parity with flat VB6.
    If Not Pdf.RptRegisterExporterEvent(mEng, 100) Then
        Debug.Print "RptRegisterExporterEvent failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    End If
    Debug.Print "registered custom function PlugDouble/1 + custom exporter target 100 (plugin-free, via AX events)"

    Lrpt = App.Path & "\13_plugin.lrpt"
    OutPdf = App.Path & "\13_plugin.pdf"
    OutTxt = App.Path & "\13_plugin.txt"
    WriteText Lrpt, BuildXml()

    Job = Pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    If Pdf.RptRender(Job) = 0 Then Debug.Print "render failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    If Pdf.RptExport(Job, 0, OutPdf) = 0 Then Debug.Print "export PDF failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    If Pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "export TEXT failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    ' Invoke OUR custom exporter through the normal rptExport dispatch (target 100).
    If Pdf.RptExport(Job, 100, App.Path & "\13_custom.out") = 0 Then Debug.Print "custom export failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "wrote " & OutPdf & " + " & OutTxt & " + 13_custom.out"
    Debug.Print "OK"
    Pdf.RptCloseReport Job
Cleanup:
    Pdf.RptDeleteEngine mEng
End Sub

' PlugDouble(x) = x*2
Private Sub Pdf_OnRptFunction(ByVal FuncName As String, ByVal Args As Variant, ResultV As Variant, ResultCode As Long)
    Dim a As Double
    a = 0
    If IsArray(Args) Then
        If UBound(Args) >= 0 Then a = CDbl(Args(0))
    Else
        a = CDbl(Args)
    End If
    ' NOTE: the AX OnRptFunction bridge hangs if the argument arrives as a numeric
    ' Variant, so the report calls PlugDouble with STRING-literal args and the
    ' handler converts + returns the doubled value as a string.
    If UCase$(FuncName) = "PLUGDOUBLE" Then
        ResultV = CStr(a * 2#)
    Else
        ResultV = ""
    End If
    ResultCode = 0
End Sub

' Custom exporter for target 100: write a marker file at APath. Fired by
' rptExport(job, 100, path) via the AX exporter-event bridge.
Private Sub Pdf_OnRptExport(ByVal TargetId As Long, ByVal APath As String, ResultCode As Long)
    WriteText APath, "PLUGIN:OK -- written by a custom exporter registered via RptRegisterExporterEvent (no external plugin DLL)"
    ResultCode = 0
End Sub
