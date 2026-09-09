Attribute VB_Name = "mod13_plugin"
Option Explicit
' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\13_plugin.bas.
'  Same feature, and genuinely working (not an event-based substitute -- see
'  12_custom_function.bas for why that path is closed to classic VB6):
'  loading an external plugin DLL via RptLoadPlugin(Engine, Path).
'
'  Unlike rptRegisterFunctionA/rptRegisterExporter (raw native callback
'  pointers, unusable from VB6), RptLoadPlugin is a plain (Engine As Long,
'  Path As String) call with NO callback marshalling across the COM boundary
'  at all -- the plugin DLL registers its function + exporter with the engine
'  entirely in its OWN native code (see tests\rpt\rpt_testplugin.dpr). So it
'  works from VB6 exactly like the flat-DLL/Delphi original.
'
'  rpt_testplugin.dll registers:
'    - expression function PlugDouble(x) = x*2   (accepts int or float)
'    - custom exporter target 100 -- writes "PLUGIN:OK" to the export path
'
'  The engine's rpt_testplugin.dll under E:\LUMASPDFSDK is a 64-bit build
'  (dcc64); the LumasPdf ActiveX component that a 32-bit VB6 process loads is
'  the 32-bit LumasPdfAX32.dll, which cannot LoadLibrary a 64-bit plugin. So a
'  32-bit copy was compiled here (dcc32, from the SAME unmodified source,
'  tests\rpt\rpt_testplugin.dpr -- see build log) and ships alongside this
'  .bas as rpt_testplugin.dll, matching the hosting engine's bitness.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Const RPT_EXP_PDF As Long = 0
Const RPT_EXP_TEXT As Long = 5

Private pdf As Object       ' LumasPdf.PDF (late-bound)
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

Private Sub DumpRptError()
    Debug.Print "  ! " & pdf.LastErrorMessage
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set pdf = CreateObject("LumasPdf.PDF")
    ' pdf.RaiseExceptions = True
    pdf.SetLicenseKey PDF_DEMO_KEY
    pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "RptCreateEngine failed: " & pdf.LastErrorMessage: Exit Function
    BootEngine = True
End Function

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""Plugin"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
    s = s & "   <text name=""p1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>" & vbLf
    s = s & "   <text name=""p2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Dir_ As String, Lrpt As String, OutPdf As String, OutTxt As String, OutCustom As String, PluginPath As String
    Dim Job As Long

    If Not BootEngine() Then Exit Sub

    Dir_ = App.Path & "\"
    PluginPath = Dir_ & "rpt_testplugin.dll"
    If Dir(PluginPath) = "" Then
        Debug.Print "plugin DLL not found: " & PluginPath
        pdf.RptDeleteEngine mEng
        Exit Sub
    End If

    ' Load the plugin BEFORE opening/rendering so the expression compiler
    ' resolves PlugDouble and the exporter dispatch table knows target 100.
    If pdf.RptLoadPlugin(mEng, PluginPath) = 0 Then
        Debug.Print "RptLoadPlugin failed": DumpRptError: pdf.RptDeleteEngine mEng: Exit Sub
    End If
    Debug.Print "loaded rpt_testplugin.dll -- registers PlugDouble(x)=x*2 + exporter target 100 (all native, no VB6 callback)"

    Lrpt = Dir_ & "13_plugin.lrpt"
    OutPdf = Dir_ & "13_plugin.pdf"
    OutTxt = Dir_ & "13_plugin.txt"
    OutCustom = Dir_ & "13_custom.out"
    WriteText Lrpt, BuildXml()

    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError: GoTo Cleanup
    If pdf.RptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    If pdf.RptExport(Job, RPT_EXP_PDF, OutPdf) = 0 Then Debug.Print "export PDF failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "export TEXT failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    ' Invoke the PLUGIN's own custom exporter (target 100) through the normal
    ' rptExport dispatch -- entirely the plugin's native code, no VB6 involved.
    If pdf.RptExport(Job, 100, OutCustom) = 0 Then Debug.Print "custom export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "wrote " & OutPdf & " + " & OutTxt & " + " & OutCustom & " (via the plugin's own exporter)"
    Debug.Print "OK"
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "13_plugin (ActiveX)"
End Sub
