Attribute VB_Name = "mod02_license_and_errors"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\02_license_and_errors.bas.
'  Same feature: structured license info (skipped -- see note below),
'  deliberate-error paths (bad .lrpt, nil Job), and a valid render, all
'  through pdf.Rpt* COM methods instead of flat rpt* Declare calls.
'
'  RptGetLicenseInfo's [in,out] parameter is a raw byte-blob of a C record
'  with embedded pointers -- not buildable/decodable from VB6 (early or late
'  bound; same limitation as the flat-DLL/.vbs ports), so it is skipped here
'  too, exactly like the reference.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private pdf As Object       ' LumasPdf.PDF (late-bound)
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
    Dim GoodLrpt As String, BadLrpt As String, OutPdf As String, Xml As String

    If Not BootEngine() Then Exit Sub

    GoodLrpt = App.Path & "\02_good.lrpt"
    BadLrpt = App.Path & "\02_bad.lrpt"
    OutPdf = App.Path & "\02_out.pdf"

    Debug.Print "== License info =="
    Debug.Print "  (RptGetLicenseInfo returns a byte-blob record; not decodable from VB6 -- skipped)"

    Debug.Print "== Deliberate errors =="
    WriteText BadLrpt, "this is not a report at all" & vbLf
    Job = pdf.RptOpenReport(mEng, BadLrpt)
    If Job = 0 Then
        Debug.Print "  open(not-XML .lrpt) -> correctly failed (" & pdf.LastErrorMessage & ")"
    Else
        Debug.Print "  open(not-XML .lrpt) -> unexpectedly succeeded": pdf.RptCloseReport Job
    End If

    WriteText BadLrpt, "<notreport><oops/></notreport>" & vbLf
    Job = pdf.RptOpenReport(mEng, BadLrpt)
    If Job = 0 Then
        Debug.Print "  open(wrong-root .lrpt) -> correctly failed (" & pdf.LastErrorMessage & ")"
    Else
        Debug.Print "  open(wrong-root .lrpt) -> unexpectedly succeeded": pdf.RptCloseReport Job
    End If

    If pdf.RptRender(0) = 0 Then Debug.Print "  RptRender(nil) -> correctly returned False"
    If pdf.RptExport(0, 0, OutPdf) = 0 Then Debug.Print "  RptExport(nil) -> correctly returned False"

    Debug.Print "== Valid render =="
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""LicDemo"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""16"">" & vbLf
    Xml = Xml & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">License &amp; error demo (ActiveX)</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText GoodLrpt, Xml
    Job = pdf.RptOpenReport(mEng, GoodLrpt)
    If Job = 0 Then Debug.Print "  open failed: " & pdf.LastErrorMessage: GoTo Cleanup
    If pdf.RptRender(Job) = 0 Then Debug.Print "  render failed: " & pdf.LastErrorMessage: pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "  rendered " & pdf.RptGetPageCount(Job) & " page(s)"
    If pdf.RptExport(Job, 0, OutPdf) = 0 Then Debug.Print "  export failed: " & pdf.LastErrorMessage: pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "  wrote " & OutPdf
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "02_license_and_errors (ActiveX)"
End Sub
