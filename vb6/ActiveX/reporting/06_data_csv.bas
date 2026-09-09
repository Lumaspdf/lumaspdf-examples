Attribute VB_Name = "mod06_data_csv"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\06_data_csv.bas.
'  Same feature: a CSV-backed datasource driving a report, exported to
'  PDF + CSV + text, through pdf.Rpt* COM methods.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Const RPT_EXP_CSV As Long = 2
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

Public Sub Main()
    On Error GoTo ErrHandler

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
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Sales by Region (ActiveX)</text>" & vbLf
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

    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError: GoTo Cleanup
    End If
    If pdf.RptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "rendered " & pdf.RptGetPageCount(Job) & " page(s)"
    If pdf.RptExport(Job, 0, OutPdf) = 0 Then
        Debug.Print "pdf export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    If pdf.RptExport(Job, RPT_EXP_CSV, OutCsv) = 0 Then
        Debug.Print "csv export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then
        Debug.Print "text export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    Debug.Print "wrote " & OutCsv
    Debug.Print "wrote " & OutTxt
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "06_data_csv (ActiveX)"
End Sub
