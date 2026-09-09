Attribute VB_Name = "mod15_tags_and_formatting"
Option Explicit
' ============================================================================
'  ActiveX zero-wrapper conversion. Exercises the {{ }} tag language + text
'  formatting knobs, then proves (by exporting to TEXT and grepping it) that the
'  interpolations resolved. RptOpenReportMem (Int64 buffer ptr) cannot be driven
'  from VB6, so the markup is written to a temp .lrpt and opened with
'  RptOpenReport (documented substitution). Covers RptSetParamStr, RptRender,
'  RptExport (PDF + TEXT).
' ============================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

Private Function CsvData() As String
    Dim s As String
    s = s & "Col,Note" & vbLf
    s = s & "Alpha,first" & vbLf
    s = s & "Beta,second" & vbLf
    CsvData = s
End Function

' The report template. %CSV% is replaced with the absolute csv path at runtime.
Private Function ReportTmpl() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""TagTour"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""12"" marginTop=""12"" marginRight=""12"" marginBottom=""12""/>" & vbLf
    s = s & " <datasources>" & vbLf
    s = s & "  <datasource alias=""d"" provider=""csv"" conn=""%CSV%""/>" & vbLf
    s = s & " </datasources>" & vbLf
    s = s & " <params>" & vbLf
    s = s & "  <param name=""Name"" default=""(unset)""/>" & vbLf
    s = s & " </params>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""120"">" & vbLf
    s = s & "   <text name=""h""   x=""0"" y=""0""  w=""186"" h=""8"" fontSize=""16"" hAlign=""center"">Tag &amp; formatting tour</text>" & vbLf
    s = s & "   <text name=""ex""  x=""0"" y=""12"" w=""186"" h=""6"" fontSize=""11"">expr 2+3*4 = {{expr: 2+3*4 }}</text>" & vbLf
    s = s & "   <text name=""vr""  x=""0"" y=""20"" w=""186"" h=""6"" fontSize=""11"">var:Name = {{var:Name}}</text>" & vbLf
    s = s & "   <text name=""fn""  x=""0"" y=""28"" w=""186"" h=""6"" fontSize=""11"">FORMATNUM = {{expr: FORMATNUM('#,##0.00', 1234.5) }}</text>" & vbLf
    s = s & "   <text name=""fd""  x=""0"" y=""36"" w=""186"" h=""6"" fontSize=""11"">FORMATDATE = {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>" & vbLf
    s = s & "   <text name=""esc"" x=""0"" y=""44"" w=""186"" h=""6"" fontSize=""11"">escape literal = {{{{ }}</text>" & vbLf
    s = s & "   <text name=""a0"" x=""0"" y=""56"" w=""186"" h=""6"" fontSize=""10"" hAlign=""0"">hAlign 0 = left</text>" & vbLf
    s = s & "   <text name=""a1"" x=""0"" y=""63"" w=""186"" h=""6"" fontSize=""10"" hAlign=""1"">hAlign 1 = center</text>" & vbLf
    s = s & "   <text name=""a2"" x=""0"" y=""70"" w=""186"" h=""6"" fontSize=""10"" hAlign=""2"">hAlign 2 = right</text>" & vbLf
    s = s & "   <text name=""a3"" x=""0"" y=""77"" w=""186"" h=""6"" fontSize=""10"" hAlign=""3"">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>" & vbLf
    s = s & "   <text name=""v0"" x=""0""   y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""0"">vAlign 0 top</text>" & vbLf
    s = s & "   <text name=""v1"" x=""63""  y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""1"">vAlign 1 middle</text>" & vbLf
    s = s & "   <text name=""v2"" x=""126"" y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""2"">vAlign 2 bottom</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""detail"" name=""rows"" height=""7"" data=""d"">" & vbLf
    s = s & "   <text name=""r"" x=""0"" y=""0"" w=""186"" h=""6"" fontSize=""11"">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    ReportTmpl = s
End Function

Private Sub Prove(ByVal What As String, ByVal Needle As String, ByVal Hay As String)
    If InStr(Hay, Needle) > 0 Then
        Debug.Print "  OK   " & What & " found """ & Needle & """"
    Else
        Debug.Print "  MISS " & What & " expected """ & Needle & """"
    End If
End Sub

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

Private Function ReadAllText(ByVal Path As String) As String
    Dim f As Integer, n As Long, b() As Byte
    ReadAllText = ""
    If Dir(Path) = "" Then Exit Function
    f = FreeFile
    Open Path For Binary Access Read As #f
    n = LOF(f)
    If n > 0 Then
        ReDim b(0 To n - 1)
        Get #f, 1, b
        ReadAllText = StrConv(b, vbUnicode)
    End If
    Close #f
End Function

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
    Dim Dir_ As String, Csv As String, Lrpt As String, OutPdf As String, OutTxt As String
    Dim Xml As String, Txt As String, IsoToday As String

    If Not BootEngine() Then Exit Sub

    Dir_ = App.Path & "\"
    Csv = Dir_ & "15_data.csv"
    Lrpt = Dir_ & "15_tags.lrpt"
    OutPdf = Dir_ & "15_tags.pdf"
    OutTxt = Dir_ & "15_tags.txt"

    WriteText Csv, CsvData()
    Xml = Replace(ReportTmpl(), "%CSV%", Csv)
    WriteText Lrpt, Xml

    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed: " & Pdf.GetErrorMessage(): GoTo Cleanup

    ' Give the {{var:Name}} parameter a distinctive value to grep for.
    rptSetParamStr Job, "Name", "Ada_Lovelace"

    If rptRender(Job) = 0 Then Debug.Print "render failed: " & Pdf.GetErrorMessage(): GoTo CloseJob
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s)"

    If rptExportA(Job, 0, OutPdf) = 0 Then Debug.Print "PDF export failed: " & Pdf.GetErrorMessage(): GoTo CloseJob
    Debug.Print "wrote " & OutPdf
    If rptExportA(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "TEXT export failed: " & Pdf.GetErrorMessage(): GoTo CloseJob
    Debug.Print "wrote " & OutTxt
CloseJob:
    rptCloseReport Job

    Debug.Print "== Proof (grep the TEXT export) =="
    Txt = ReadAllText(OutTxt)
    IsoToday = Format$(Date, "yyyy-mm-dd")

    Prove "expr 2+3*4", "= 14", Txt
    Prove "var:Name", "Ada_Lovelace", Txt
    Prove "FORMATNUM", "1,234.50", Txt
    Prove "FORMATDATE", IsoToday, Txt
    Prove "escape {{}}", "{{ }}", Txt
    Prove "fields.d.Col", "Alpha", Txt
    Prove "bare d.Col", "Beta", Txt
Cleanup:
    rptDeleteEngine mEng
End Sub
