Attribute VB_Name = "mod14_open_mem_and_print"
Option Explicit
' ============================================================================
'  ActiveX zero-wrapper conversion.
'  RptOpenReportMem takes a raw memory pointer (Int64 Buf) which VB6 early-
'  binding cannot supply, so the "open from memory" step is emulated by writing
'  the same markup to a temp .lrpt and using RptOpenReport (documented, same
'  substitution as the .vbs port). The headless-print step ports directly:
'  RptPrint -> "Microsoft Print to PDF" with an absolute output file (no dialog).
' ============================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""InMem"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
    s = s & "   <text name=""title"" x=""0"" y=""0""  w=""180"" h=""12"" fontSize=""20"" hAlign=""center"">In-memory report</text>" & vbLf
    s = s & "   <text name=""sub""   x=""0"" y=""14"" w=""180"" h=""6""  fontSize=""10"" hAlign=""center"">Opened via RptOpenReport (VB6 cannot pass a raw buffer to RptOpenReportMem).</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
    s = s & "   <text name=""ph1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""9"" hAlign=""left"">LumasReport example 14</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""detail"" name=""det"" height=""8"">" & vbLf
    s = s & "   <text name=""d1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""11"" hAlign=""left"">This band was rendered from an emitted temp .lrpt.</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""pagefooter"" name=""pf"" height=""8"">" & vbLf
    s = s & "   <text name=""pf1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""8"" hAlign=""right"">page {{var:PageNo}} of {{var:TotalPages}}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

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
    Dim Job As Long, Pages As Long
    Dim Dir_ As String, Lrpt As String, OutPdf As String, OutPrint As String

    If Not BootEngine() Then Exit Sub

    Dir_ = App.Path & "\"
    Lrpt = Dir_ & "14_open_mem.lrpt"
    OutPdf = Dir_ & "14_open_mem.pdf"
    OutPrint = Dir_ & "14_printed.pdf"

    Debug.Print "== Open (emulated in-memory) =="
    WriteText Lrpt, BuildXml()
    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "  open failed: " & Pdf.GetErrorMessage(): GoTo Cleanup

    If rptRender(Job) = 0 Then Debug.Print "  render failed: " & Pdf.GetErrorMessage(): GoTo CloseJob
    Pages = rptGetPageCount(Job)
    Debug.Print "  rendered " & Pages & " page(s)"

    Debug.Print "== Export =="
    If rptExportA(Job, 0, OutPdf) = 0 Then Debug.Print "  export failed: " & Pdf.GetErrorMessage(): GoTo CloseJob
    Debug.Print "  wrote " & OutPdf

    Debug.Print "== Headless print =="
    If Pdf.RptPrint(Job, "Microsoft Print to PDF", OutPrint) <> 0 Then
        Debug.Print "  ""Microsoft Print to PDF"" -> " & OutPrint
    Else
        Debug.Print "  ""Microsoft Print to PDF"" not available / print failed (non-fatal): " & Pdf.GetErrorMessage()
    End If
CloseJob:
    rptCloseReport Job

    Debug.Print "== Verify =="
    If (Dir(OutPdf) <> "") And (Pages >= 1) Then
        Debug.Print "  OK: " & OutPdf & " exists, report has " & Pages & " page(s)"
    Else
        Debug.Print "  VERIFY FAILED: in-memory PDF missing or zero pages"
    End If
Cleanup:
    rptDeleteEngine mEng
End Sub
