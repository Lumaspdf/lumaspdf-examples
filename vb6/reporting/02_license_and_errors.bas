Attribute VB_Name = "mod02_license_and_errors"
Option Explicit

' ===========================================================================
'  ActiveX zero-wrapper conversion (early-bound to CPDF). The structured
'  license dump uses RptGetLicenseInfo, whose [in,out] OleVariant is a raw
'  byte-blob of a C record with embedded pointers -- not buildable/decodable
'  from VB6 early-binding (same limit as the .vbs port), so it is skipped. The
'  deliberate-error and valid-render paths are ported fully.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

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
    Dim Job As Long
    Dim GoodLrpt As String, BadLrpt As String, OutPdf As String, Xml As String

    If Not BootEngine() Then Exit Sub

    GoodLrpt = App.Path & "\02_good.lrpt"
    BadLrpt = App.Path & "\02_bad.lrpt"
    OutPdf = App.Path & "\02_out.pdf"

    Debug.Print "== License info =="
    Debug.Print "  (RptGetLicenseInfo returns a byte-blob record; not decodable from VB6 -- skipped)"

    Debug.Print "== Deliberate errors =="
    WriteText BadLrpt, "this is not a report at all" & vbLf
    Job = rptOpenReport(mEng, BadLrpt)
    If Job = 0 Then
        Debug.Print "  open(not-XML .lrpt) -> correctly failed (" & Pdf.GetErrorMessage() & ")"
    Else
        Debug.Print "  open(not-XML .lrpt) -> unexpectedly succeeded": rptCloseReport Job
    End If

    WriteText BadLrpt, "<notreport><oops/></notreport>" & vbLf
    Job = rptOpenReport(mEng, BadLrpt)
    If Job = 0 Then
        Debug.Print "  open(wrong-root .lrpt) -> correctly failed (" & Pdf.GetErrorMessage() & ")"
    Else
        Debug.Print "  open(wrong-root .lrpt) -> unexpectedly succeeded": rptCloseReport Job
    End If

    If rptRender(0) = 0 Then Debug.Print "  RptRender(nil) -> correctly returned False"
    If rptExportA(0, 0, OutPdf) = 0 Then Debug.Print "  RptExport(nil) -> correctly returned False"

    Debug.Print "== Valid render =="
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""LicDemo"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""16"">" & vbLf
    Xml = Xml & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">License &amp; error demo</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText GoodLrpt, Xml
    Job = rptOpenReport(mEng, GoodLrpt)
    If Job = 0 Then Debug.Print "  open failed: " & Pdf.GetErrorMessage(): GoTo Cleanup
    If rptRender(Job) = 0 Then Debug.Print "  render failed: " & Pdf.GetErrorMessage(): rptCloseReport Job: GoTo Cleanup
    Debug.Print "  rendered " & rptGetPageCount(Job) & " page(s)"
    If rptExportA(Job, 0, OutPdf) = 0 Then Debug.Print "  export failed: " & Pdf.GetErrorMessage(): rptCloseReport Job: GoTo Cleanup
    Debug.Print "  wrote " & OutPdf
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
