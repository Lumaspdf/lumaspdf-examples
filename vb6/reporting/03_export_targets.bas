Attribute VB_Name = "mod03_export_targets"
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
    Dim Job As Long, i As Long
    Dim Csv As String, Lrpt As String, OutFile As String, Xml As String, CsvData As String
    Dim Targets(0 To 9) As Long, Exts(0 To 9) As String

    Targets(0) = 0:  Exts(0) = "pdf"
    Targets(1) = 3: Exts(1) = "html"
    Targets(2) = 4:  Exts(2) = "csv"
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

    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError mEng: GoTo Cleanup
    End If
    If rptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s)"
    Debug.Print "== Exporting to all targets =="
    For i = 0 To 9
        OutFile = App.Path & "\03_out." & Exts(i)
        If rptExportA(Job, Targets(i), OutFile) <> 0 And FileExists(OutFile) Then
            Debug.Print "  [" & Exts(i) & "] id=" & Targets(i) & "  OK  " & FileSizeOf(OutFile) & " bytes"
        Else
            Debug.Print "  [" & Exts(i) & "] id=" & Targets(i) & "  FAILED"
            DumpRptError mEng
        End If
    Next
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
