Attribute VB_Name = "mod07_data_json_xml"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\07_data_json_xml.bas.
'  Same feature: JSON-backed and XML-backed datasources each driving their
'  own report, through pdf.Rpt* COM methods.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Const RPT_EXP_TEXT As Long = 5

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

Private Function RunReport(ByVal Tag As String, ByVal Xml As String) As Boolean
    Dim Job As Long, Lrpt As String, OutPdf As String, OutTxt As String
    RunReport = False
    Lrpt = App.Path & "\07_" & Tag & ".lrpt"
    OutPdf = App.Path & "\07_" & Tag & ".pdf"
    OutTxt = App.Path & "\07_" & Tag & ".txt"
    WriteText Lrpt, Xml
    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print Tag & ": open failed": DumpRptError: Exit Function
    End If
    If pdf.RptRender(Job) = 0 Then
        Debug.Print Tag & ": render failed": DumpRptError: pdf.RptCloseReport Job: Exit Function
    End If
    Debug.Print Tag & ": rendered " & pdf.RptGetPageCount(Job) & " page(s)"
    If pdf.RptExport(Job, 0, OutPdf) = 0 Then
        Debug.Print Tag & ": pdf export failed": DumpRptError: pdf.RptCloseReport Job: Exit Function
    End If
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then
        Debug.Print Tag & ": text export failed": DumpRptError: pdf.RptCloseReport Job: Exit Function
    End If
    Debug.Print "wrote " & OutPdf & " + " & OutTxt
    RunReport = True
    pdf.RptCloseReport Job
End Function

Public Sub Main()
    On Error GoTo ErrHandler

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
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (JSON source, ActiveX)</text>" & vbLf
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
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (XML source, ActiveX)</text>" & vbLf
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
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "07_data_json_xml (ActiveX)"
End Sub
