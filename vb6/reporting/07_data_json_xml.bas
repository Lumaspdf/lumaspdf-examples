Attribute VB_Name = "mod07_data_json_xml"
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

Private Function RunReport(ByVal Tag As String, ByVal Xml As String) As Boolean
    Dim Job As Long, Lrpt As String, OutPdf As String, OutTxt As String
    RunReport = False
    Lrpt = App.Path & "\07_" & Tag & ".lrpt"
    OutPdf = App.Path & "\07_" & Tag & ".pdf"
    OutTxt = App.Path & "\07_" & Tag & ".txt"
    WriteText Lrpt, Xml
    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print Tag & ": open failed": DumpRptError mEng: Exit Function
    End If
    If rptRender(Job) = 0 Then
        Debug.Print Tag & ": render failed": DumpRptError mEng: rptCloseReport Job: Exit Function
    End If
    Debug.Print Tag & ": rendered " & rptGetPageCount(Job) & " page(s)"
    If rptExportA(Job, 0, OutPdf) = 0 Then
        Debug.Print Tag & ": pdf export failed": DumpRptError mEng: rptCloseReport Job: Exit Function
    End If
    If rptExportA(Job, RPT_EXP_TEXT, OutTxt) = 0 Then
        Debug.Print Tag & ": text export failed": DumpRptError mEng: rptCloseReport Job: Exit Function
    End If
    Debug.Print "wrote " & OutPdf & " + " & OutTxt
    RunReport = True
    rptCloseReport Job
End Function

Public Sub Main()
    Dim Jsn As String, Xm As String, JsonData As String, XmlData As String, Xml As String

    If Not BootEngine() Then Exit Sub

    Jsn = App.Path & "\07_data.json"
    Xm = App.Path & "\07_data.xml"
    JsonData = "[{""City"":""Paris"",""Country"":""FR"",""Pop"":2100},{""City"":""Lyon"",""Country"":""FR"",""Pop"":515},{""City"":""Nice"",""Country"":""FR"",""Pop"":340}]"
    WriteText Jsn, JsonData
    XmlData = ""
    XmlData = XmlData & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    XmlData = XmlData & "<rows>" & vbLf
    XmlData = XmlData & " <row City=""Berlin"" Country=""DE"" Pop=""3600""/>" & vbLf
    XmlData = XmlData & " <row City=""Munich"" Country=""DE"" Pop=""1500""/>" & vbLf
    XmlData = XmlData & " <row City=""Hamburg"" Country=""DE"" Pop=""1900""/>" & vbLf
    XmlData = XmlData & "</rows>" & vbLf
    WriteText Xm, XmlData

    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""JsonCities"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""j"" provider=""json"" conn=""" & Jsn & """ query=""""/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10"">" & vbLf
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (JSON source)</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""jd"" height=""6"" data=""j"">" & vbLf
    Xml = Xml & "   <text name=""c1"" x=""0""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{j.City}}</text>" & vbLf
    Xml = Xml & "   <text name=""c2"" x=""60"" y=""0"" w=""30"" h=""5"" fontSize=""9"" wordWrap=""0"">{{j.Country}}</text>" & vbLf
    Xml = Xml & "   <text name=""c3"" x=""90"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{j.Pop}}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    If Not RunReport("json", Xml) Then GoTo Cleanup
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""XmlCities"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""x"" provider=""xml"" conn=""" & Xm & """ query=""rows/row""/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10"">" & vbLf
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (XML source)</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""xd"" height=""6"" data=""x"">" & vbLf
    Xml = Xml & "   <text name=""c1"" x=""0""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{x.City}}</text>" & vbLf
    Xml = Xml & "   <text name=""c2"" x=""60"" y=""0"" w=""30"" h=""5"" fontSize=""9"" wordWrap=""0"">{{x.Country}}</text>" & vbLf
    Xml = Xml & "   <text name=""c3"" x=""90"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{x.Pop}}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    If Not RunReport("xml", Xml) Then GoTo Cleanup
Cleanup:
    rptDeleteEngine mEng
End Sub
