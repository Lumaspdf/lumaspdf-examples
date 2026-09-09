Attribute VB_Name = "mod01_hello_report"
Option Explicit

' ===========================================================================
'  VB6 mirror of examples\delphi\reporting -- LumasReport (rpt*) exports.
'  Translated 1:1 from the Delphi original; OO/flat rpt* calls -> flat rpt*.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long


Private Function TrimNull(ByVal s As String) As String
    Dim p As Long
    p = InStr(s, Chr$(0))
    If p > 0 Then TrimNull = Left$(s, p - 1) Else TrimNull = s
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    f = FreeFile
    Open Path For Output As #f
    Print #f, Content;
    Close #f
End Sub

Private Sub DumpRptError(ByVal Eng As Long)
    Debug.Print "  ! " & Pdf.GetErrorMessage()
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Call rptSetRptLicenseKeyA(Pdf.GetInstancePtr(), RPT_DEMO_KEY)
    mEng = rptCreateEngineA(Pdf.GetInstancePtr(), "")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.GetErrorMessage(): Exit Function
    BootEngine = True
End Function

Public Sub Main()
    Dim Job As Long, Mj As Long, Mn As Long, Pt As Long
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
    Xml = Xml & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""20"" hAlign=""center"">Hello, LumasReport!</text>" & vbLf
    Xml = Xml & "   <text name=""sub""   x=""0"" y=""12"" w=""180"" h=""6"" fontSize=""10"" hAlign=""center"">The minimal engine -&gt; render -&gt; PDF flow.</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText Lrpt, Xml

    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError mEng: GoTo Cleanup
    End If
    If rptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s)"
    If rptExportA(Job, 0, OutPdf) = 0 Then
        Debug.Print "export failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
