Attribute VB_Name = "mod03_export_targets"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\03_export_targets.bas.
'  Same feature: render one report and export it to every RPT_EXP_* target
'  (pdf/html/csv/json/xml/text/svg/xlsx/png/bmp), through pdf.Rpt* COM
'  methods instead of flat rpt* Declare calls.
'
'  RPT_EXP_* target ids (canonical, wrappers\c\lumaspdf.h / src\rpt\
'  Lumas.Rpt.Types.pas): PDF=0 HTML=1 CSV=2 JSON=3 XML=4 TEXT=5 SVG=6
'  XLSX=7 PNG=8 BMP=9 XLS=10. Declared locally since this ActiveX example
'  has no CPDF.cls-style wrapper module to source them from.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Const RPT_EXP_PDF As Long = 0
Private Const RPT_EXP_HTML As Long = 1
Private Const RPT_EXP_CSV As Long = 2
Private Const RPT_EXP_JSON As Long = 3
Private Const RPT_EXP_XML As Long = 4
Private Const RPT_EXP_TEXT As Long = 5
Private Const RPT_EXP_SVG As Long = 6
Private Const RPT_EXP_XLSX As Long = 7
Private Const RPT_EXP_PNG As Long = 8
Private Const RPT_EXP_BMP As Long = 9

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

Private Function FileExists(ByVal Path As String) As Boolean
    On Error Resume Next
    FileExists = (Len(Dir$(Path)) > 0)
    On Error GoTo 0
End Function

Private Function FileSizeOf(ByVal Path As String) As Long
    On Error GoTo fail
    FileSizeOf = FileLen(Path)
    Exit Function
fail:
    FileSizeOf = -1
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long, i As Long
    Dim Csv As String, Lrpt As String, OutFile As String, Xml As String, CsvData As String
    Dim Targets(0 To 9) As Long, Exts(0 To 9) As String

    Targets(0) = RPT_EXP_PDF:  Exts(0) = "pdf"
    Targets(1) = RPT_EXP_HTML: Exts(1) = "html"
    Targets(2) = RPT_EXP_CSV:  Exts(2) = "csv"
    Targets(3) = RPT_EXP_JSON: Exts(3) = "json"
    Targets(4) = RPT_EXP_XML:  Exts(4) = "xml"
    Targets(5) = RPT_EXP_TEXT: Exts(5) = "txt"
    Targets(6) = RPT_EXP_SVG:  Exts(6) = "svg"
    Targets(7) = RPT_EXP_XLSX: Exts(7) = "xlsx"
    Targets(8) = RPT_EXP_PNG:  Exts(8) = "png"
    Targets(9) = RPT_EXP_BMP:  Exts(9) = "bmp"

    If Not BootEngine() Then Exit Sub

    Csv = App.Path & "\03_data.csv"
    Lrpt = App.Path & "\03_report.lrpt"
    CsvData = ""
    CsvData = CsvData & "product,qty,price" & vbLf
    CsvData = CsvData & "Widget,4,9.95" & vbLf
    CsvData = CsvData & "Gadget,2,19.50" & vbLf
    CsvData = CsvData & "Sprocket,7,3.25" & vbLf
    WriteText Csv, CsvData
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""ExportDemo"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""14"">" & vbLf
    Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Order Lines</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""det"" height=""7"" data=""d"">" & vbLf
    Xml = Xml & "   <text name=""p"" x=""0""   y=""0"" w=""90"" h=""6"" fontSize=""10"" wordWrap=""0"">{{d.product}}</text>" & vbLf
    Xml = Xml & "   <text name=""q"" x=""90""  y=""0"" w=""30"" h=""6"" fontSize=""10"" hAlign=""right"" wordWrap=""0"">{{d.qty}}</text>" & vbLf
    Xml = Xml & "   <text name=""r"" x=""120"" y=""0"" w=""60"" h=""6"" fontSize=""10"" hAlign=""right"" wordWrap=""0"">{{d.price}}</text>" & vbLf
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
    Debug.Print "== Exporting to all targets =="
    For i = 0 To 9
        OutFile = App.Path & "\03_out." & Exts(i)
        If pdf.RptExport(Job, Targets(i), OutFile) <> 0 And FileExists(OutFile) Then
            Debug.Print "  [" & Exts(i) & "] id=" & Targets(i) & "  OK  " & FileSizeOf(OutFile) & " bytes"
        Else
            Debug.Print "  [" & Exts(i) & "] id=" & Targets(i) & "  FAILED"
            DumpRptError
        End If
    Next
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "03_export_targets (ActiveX)"
End Sub
