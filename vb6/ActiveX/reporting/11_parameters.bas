Attribute VB_Name = "mod11_parameters"
Option Explicit
' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\11_parameters.bas.
'  Same feature: declare <params> in the .lrpt and drive them from VB at JOB
'  level via pdf.RptSetParamStr / pdf.RptSetParamNum / pdf.RptSetParamInt
'  (AFTER RptOpenReport, BEFORE RptRender). The report is rendered TWICE with
'  different parameter values -- via the LumasPdf ActiveX component's Rpt*
'  methods instead of the flat-DLL Declare-based rptSetParamStr/Num/Int.
'
'  Late-bound, no project reference needed (see NorthwindMegaDemo.bas /
'  hello_world.bas conventions).
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
    s = s & "<report name=""Params"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <params>" & vbLf
    s = s & "  <param name=""Customer"" default=""ACME (default)""/>" & vbLf
    s = s & "  <param name=""UnitPrice"" default=""0""/>" & vbLf
    s = s & "  <param name=""Qty"" default=""0""/>" & vbLf
    s = s & " </params>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""30"">" & vbLf
    s = s & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">Invoice for {{var:Customer}}</text>" & vbLf
    s = s & "   <text name=""line1"" x=""0"" y=""14"" w=""180"" h=""6"" fontSize=""11"">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>" & vbLf
    s = s & "   <text name=""line2"" x=""0"" y=""22"" w=""180"" h=""6"" fontSize=""11"">TOTAL = {{expr: UnitPrice * Qty}}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

' Render the report once with a specific set of parameter values.
Private Function RunOnce(ByVal Lrpt As String, ByVal OutPdf As String, ByVal OutTxt As String, _
    ByVal Customer As String, ByVal UnitPrice As Double, ByVal Qty As Long) As Boolean
    Dim Job As Long
    RunOnce = False
    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "  open failed": DumpRptError: Exit Function
    ' --- drive the declared params from VB (JOB level), via the ActiveX Rpt* methods ---
    If pdf.RptSetParamStr(Job, "Customer", Customer) = 0 Then Debug.Print "  RptSetParamStr failed": DumpRptError: GoTo Done
    If pdf.RptSetParamNum(Job, "UnitPrice", UnitPrice) = 0 Then Debug.Print "  RptSetParamNum failed": DumpRptError: GoTo Done
    If pdf.RptSetParamInt(Job, "Qty", Qty) = 0 Then Debug.Print "  RptSetParamInt failed": DumpRptError: GoTo Done
    If pdf.RptRender(Job) = 0 Then Debug.Print "  render failed": DumpRptError: GoTo Done
    If pdf.RptExport(Job, RPT_EXP_PDF, OutPdf) = 0 Then Debug.Print "  export PDF failed": DumpRptError: GoTo Done
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "  export TEXT failed": DumpRptError: GoTo Done
    Debug.Print "  wrote " & OutPdf & "  (Customer=""" & Customer & """ UnitPrice=" & UnitPrice & " Qty=" & Qty & " TOTAL=" & (UnitPrice * Qty) & ")"
    RunOnce = True
Done:
    pdf.RptCloseReport Job
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Dir_ As String, Lrpt As String
    If Not BootEngine() Then Exit Sub
    Dir_ = App.Path & "\"
    Lrpt = Dir_ & "11_parameters.lrpt"
    WriteText Lrpt, BuildXml()

    Debug.Print "Run #1:"
    If Not RunOnce(Lrpt, Dir_ & "11_run1.pdf", Dir_ & "11_run1.txt", "Globex Corporation", 12.5, 4) Then GoTo Cleanup

    Debug.Print "Run #2:"
    If Not RunOnce(Lrpt, Dir_ & "11_run2.pdf", Dir_ & "11_run2.txt", "Initech LLC", 9.99, 10) Then GoTo Cleanup

    Debug.Print "OK"
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "11_parameters (ActiveX)"
End Sub
