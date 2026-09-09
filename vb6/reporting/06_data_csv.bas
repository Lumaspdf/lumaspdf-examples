Attribute VB_Name = "mod06_data_csv"
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
    Dim Lrpt As String, Csv As String, OutPdf As String, OutCsv As String, OutTxt As String
    Dim Xml As String, CsvData As String

    If Not BootEngine() Then Exit Sub

    Lrpt = App.Path & "\06_data.lrpt"
    Csv = App.Path & "\06_data.csv"
    OutPdf = App.Path & "\06_data.pdf"
    OutCsv = App.Path & "\06_data_out.csv"
    OutTxt = App.Path & "\06_data.txt"

    CsvData = ""
    CsvData = CsvData & "Region,Product,Qty,Price" & vbLf
    CsvData = CsvData & "North,Widget,10,2.50" & vbLf
    CsvData = CsvData & "North,Gadget,4,9.99" & vbLf
    CsvData = CsvData & "South,Widget,7,2.50" & vbLf
    CsvData = CsvData & "South,Sprocket,20,1.25" & vbLf
    CsvData = CsvData & "East,Gadget,3,9.99" & vbLf
    CsvData = CsvData & "West,Sprocket,15,1.25" & vbLf
    WriteText Csv, CsvData
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""CsvSales"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""12"">" & vbLf
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Sales by Region</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
    Xml = Xml & "   <text name=""h1"" x=""0""   y=""0"" w=""50"" h=""6"" fontSize=""9"" style="""">REGION</text>" & vbLf
    Xml = Xml & "   <text name=""h2"" x=""50""  y=""0"" w=""60"" h=""6"" fontSize=""9"">PRODUCT</text>" & vbLf
    Xml = Xml & "   <text name=""h3"" x=""110"" y=""0"" w=""30"" h=""6"" fontSize=""9"" hAlign=""right"">QTY</text>" & vbLf
    Xml = Xml & "   <text name=""h4"" x=""140"" y=""0"" w=""40"" h=""6"" fontSize=""9"" hAlign=""right"">PRICE</text>" & vbLf
    Xml = Xml & "   <line name=""hl"" x=""0"" y=""7"" w=""180"" h=""0.3"" toX=""180"" toY=""0""/>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
    Xml = Xml & "   <text name=""c1"" x=""0""   y=""0"" w=""50"" h=""5"" fontSize=""9"" wordWrap=""0"">{{d.Region}}</text>" & vbLf
    Xml = Xml & "   <text name=""c2"" x=""50""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{d.Product}}</text>" & vbLf
    Xml = Xml & "   <text name=""c3"" x=""110"" y=""0"" w=""30"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{d.Qty}}</text>" & vbLf
    Xml = Xml & "   <text name=""c4"" x=""140"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{d.Price}}</text>" & vbLf
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
        Debug.Print "pdf export failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    If rptExportA(Job, 4, OutCsv) = 0 Then
        Debug.Print "csv export failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    If rptExportA(Job, RPT_EXP_TEXT, OutTxt) = 0 Then
        Debug.Print "text export failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    Debug.Print "wrote " & OutCsv
    Debug.Print "wrote " & OutTxt
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
