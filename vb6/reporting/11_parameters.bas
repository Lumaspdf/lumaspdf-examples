Attribute VB_Name = "mod11_parameters"
Option Explicit
' ============================================================================
'  LumasReport example 11 -- Report parameters  (VB6 mirror of 11_parameters.dpr)
'  Declares <params> in the .lrpt and drives them from VB at JOB level via
'  rptSetParamStr / rptSetParamNum / rptSetParamInt (AFTER rptOpenReport, BEFORE
'  rptRender). The whole report is rendered TWICE with different parameter values.
'  Exports covered: rptSetParamStr, rptSetParamNum, rptSetParamInt.
' ============================================================================

' Reporting requires BOTH a PDF SDK license AND a reporting license.
Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

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
Private Function RunOnce(ByVal Eng As Long, ByVal Lrpt As String, ByVal OutPdf As String, _
    ByVal OutTxt As String, ByVal Customer As String, ByVal UnitPrice As Double, ByVal Qty As Long) As Boolean
    Dim Job As Long
    RunOnce = False
    Job = rptOpenReport(Eng, Lrpt)
    If Job = 0 Then Debug.Print "  open failed": DumpRptError Eng: Exit Function
    ' --- drive the declared params from VB (JOB level) ---
    If rptSetParamStr(Job, "Customer", Customer) = 0 Then Debug.Print "  SetParamStr failed": DumpRptError Eng: GoTo Done
    If rptSetParamNum(Job, "UnitPrice", UnitPrice) = 0 Then Debug.Print "  SetParamNum failed": DumpRptError Eng: GoTo Done
    If rptSetParamNum(Job, "Qty", Qty) = 0 Then Debug.Print "  SetParamInt failed": DumpRptError Eng: GoTo Done
    If rptRender(Job) = 0 Then Debug.Print "  render failed": DumpRptError Eng: GoTo Done
    If rptExportA(Job, 0, OutPdf) = 0 Then Debug.Print "  export PDF failed": DumpRptError Eng: GoTo Done
    If rptExportA(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "  export TEXT failed": DumpRptError Eng: GoTo Done
    Debug.Print "  wrote " & OutPdf & "  (Customer=""" & Customer & """ UnitPrice=" & UnitPrice & " Qty=" & Qty & " TOTAL=" & (UnitPrice * Qty) & ")"
    RunOnce = True
Done:
    rptCloseReport Job
End Function

Public Sub Main()
    Dim Pdf As Long, Eng As Long
    Dim Dir_ As String, Lrpt As String
    If Not BootEngine(Pdf, Eng) Then Exit Sub
    Dir_ = App.Path & "\"
    Lrpt = Dir_ & "11_parameters.lrpt"
    WriteText Lrpt, BuildXml()

    Debug.Print "Run #1:"
    If Not RunOnce(Eng, Lrpt, Dir_ & "11_run1.pdf", Dir_ & "11_run1.txt", "Globex Corporation", 12.5, 4) Then GoTo Cleanup

    Debug.Print "Run #2:"
    If Not RunOnce(Eng, Lrpt, Dir_ & "11_run2.pdf", Dir_ & "11_run2.txt", "Initech LLC", 9.99, 10) Then GoTo Cleanup

    Debug.Print "OK"
Cleanup:
    rptDeleteEngine Eng
End Sub

' --- shared boilerplate (mirror of _shared.inc) -----------------------------

Private Function BootEngine(ByRef Pdf As Long, ByRef Eng As Long) As Boolean
    BootEngine = False
    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Call rptSetRptLicenseKeyA(Pdf.GetInstancePtr(), RPT_DEMO_KEY)
    mEng = rptCreateEngineA(Pdf.GetInstancePtr(), "")
    Eng = mEng
    Pdf = 0
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.GetErrorMessage(): Exit Function
    BootEngine = True
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    Dim b() As Byte
    f = FreeFile
    On Error Resume Next
    Kill Path
    On Error GoTo 0
    b = StrConv(Content, vbFromUnicode)
    Open Path For Binary Access Write As #f
    Put #f, 1, b
    Close #f
End Sub

Private Function Trim0(ByVal s As String) As String
    Dim p As Long
    p = InStr(s, vbNullChar)
    If p > 0 Then Trim0 = Left$(s, p - 1) Else Trim0 = s
End Function

Private Sub DumpRptError(ByVal Eng As Long)
    Debug.Print "  ! " & Pdf.GetErrorMessage()
End Sub
