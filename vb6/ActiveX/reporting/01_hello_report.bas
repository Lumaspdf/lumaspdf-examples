Attribute VB_Name = "mod01_hello_report"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\01_hello_report.bas.
'  Same feature: boot a LumasReport engine, open/render a tiny inline .lrpt
'  and export it to PDF -- but through the LumasPdf ActiveX component's
'  Rpt* methods (pdf.RptCreateEngine / pdf.RptOpenReport / pdf.RptRender /
'  pdf.RptExport / pdf.RptCloseReport / pdf.RptDeleteEngine) instead of the
'  flat-DLL Declare-based rpt* functions + CPDF.cls wrapper.
'
'  Late-bound, no project reference needed (see NorthwindMegaDemo.bas /
'  hello_world.bas conventions).
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private pdf As Object       ' LumasPdf.PDF (late-bound)
Private mEng As Long

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    f = FreeFile
    Open Path For Output As #f
    Print #f, Content;
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

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, Xml As String

    If Not BootEngine() Then Exit Sub

    Lrpt = App.Path & "\01_hello.lrpt"
    OutPdf = App.Path & "\01_hello.pdf"
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""Hello"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""20"">" & vbLf
    Xml = Xml & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""20"" hAlign=""center"">Hello, LumasReport (ActiveX)!</text>" & vbLf
    Xml = Xml & "   <text name=""sub""   x=""0"" y=""12"" w=""180"" h=""6"" fontSize=""10"" hAlign=""center"">The minimal engine -&gt; render -&gt; PDF flow, via pdf.Rpt* COM methods.</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText Lrpt, Xml

    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError: GoTo Cleanup
    End If
    If pdf.RptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "rendered " & pdf.RptGetPageCount(Job) & " page(s)"
    If pdf.RptExport(Job, 0, OutPdf) = 0 Then
        Debug.Print "export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "01_hello_report (ActiveX)"
End Sub
