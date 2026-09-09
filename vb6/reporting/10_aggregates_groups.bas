Attribute VB_Name = "mod10_aggregates_groups"
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
    Dim Job As Long
    Dim Csv As String, Lrpt As String, OutPdf As String, OutTxt As String
    Dim Xml As String, CsvData As String

    If Not BootEngine() Then Exit Sub

    Csv = App.Path & "\10_data.csv"
    Lrpt = App.Path & "\10_groups.lrpt"
    OutPdf = App.Path & "\10_groups.pdf"
    OutTxt = App.Path & "\10_groups.txt"

    CsvData = ""
    CsvData = CsvData & "Cat,Item,Amount" & vbLf
    CsvData = CsvData & "Fruit,Apple,10" & vbLf
    CsvData = CsvData & "Fruit,Pear,7" & vbLf
    CsvData = CsvData & "Fruit,Plum,5" & vbLf
    CsvData = CsvData & "Dairy,Milk,4" & vbLf
    CsvData = CsvData & "Dairy,Cheese,9" & vbLf
    CsvData = CsvData & "Dairy,Butter,6" & vbLf
    CsvData = CsvData & "Grain,Bread,3" & vbLf
    CsvData = CsvData & "Grain,Rice,8" & vbLf
    CsvData = CsvData & "Grain,Oats,2" & vbLf
    WriteText Csv, CsvData
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""Groups"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10""><text name=""t"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"" wordWrap=""0"">Grouped Catalog</text></band>" & vbLf
    Xml = Xml & "  <band kind=""groupheader"" name=""gh"" group=""d.Cat"" height=""7""><text name=""g"" x=""0"" y=""1"" w=""180"" h=""5"" fontSize=""12"" bold=""1"" wordWrap=""0"">Category: {{expr: d.Cat}}</text></band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""det"" height=""5"" data=""d""><text name=""i"" x=""6"" y=""0"" w=""110"" h=""4"" fontSize=""9"" wordWrap=""0"">{{Item}}</text><text name=""a"" x=""118"" y=""0"" w=""26"" h=""4"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{Amount}}</text><text name=""r"" x=""148"" y=""0"" w=""30"" h=""4"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">[{{expr: SUM(Amount)}}]</text></band>" & vbLf
    Xml = Xml & "  <band kind=""groupfooter"" name=""gf"" group=""d.Cat"" height=""6""><text name=""gt"" x=""4"" y=""0"" w=""176"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>" & vbLf
    Xml = Xml & "  <band kind=""summary"" name=""sm"" height=""8""><text name=""s"" x=""4"" y=""1"" w=""176"" h=""6"" fontSize=""11"" bold=""1"" wordWrap=""0"">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>" & vbLf
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
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s), grouped by Cat with per-group + grand totals"
    Pdf.RptExport Job, 0, OutPdf
    Pdf.RptExport Job, RPT_EXP_TEXT, OutTxt
    Debug.Print "wrote " & OutPdf & "  +  " & OutTxt
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
