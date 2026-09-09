Attribute VB_Name = "mod04_bands"
Option Explicit

' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\04_bands.bas.
'  Same feature: every band kind (background/overlay/reportheader/
'  pageheader/groupheader/detail/groupfooter/pagefooter/summary) in one
'  grouped, multi-page report, through pdf.Rpt* COM methods.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

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

Private Function BuildCsv() As String
    Dim sb As String, g As Long, r As Long
    sb = "grp,item,val" & vbLf
    For g = 1 To 3
        For r = 1 To 30
            sb = sb & "Group-" & g & ",Item " & g & "-" & Format$(r, "00") & "," & (g * 100 + r) & vbLf
        Next
    Next
    BuildCsv = sb
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long, Pages As Long
    Dim Csv As String, Lrpt As String, OutPdf As String, Xml As String

    If Not BootEngine() Then Exit Sub

    Csv = App.Path & "\04_data.csv"
    Lrpt = App.Path & "\04_report.lrpt"
    OutPdf = App.Path & "\04_out.pdf"
    WriteText Csv, BuildCsv()
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""BandsDemo"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
    Xml = Xml & " <styles>" & vbLf
    Xml = Xml & "  <style name=""Wm""  fontSize=""48"" bold=""1"" textColor=""00EEEEEE"" hAlign=""1"" vAlign=""1""/>" & vbLf
    Xml = Xml & "  <style name=""Ov""  fontSize=""8""  textColor=""00B0B0B0"" hAlign=""2""/>" & vbLf
    Xml = Xml & "  <style name=""Grp"" fontSize=""12"" bold=""1"" textColor=""00FFFFFF"" backColor=""002A6099"" vAlign=""1""/>" & vbLf
    Xml = Xml & " </styles>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""background"" name=""bg"" height=""297"">" & vbLf
    Xml = Xml & "   <text name=""wm"" x=""20"" y=""120"" w=""150"" h=""40"" style=""Wm"" rotation=""45"" wordWrap=""0"">BACKGROUND</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""overlay"" name=""ov"" height=""297"">" & vbLf
    Xml = Xml & "   <text name=""ol"" x=""0"" y=""150"" w=""180"" h=""6"" style=""Ov"" rotation=""90"" wordWrap=""0"">overlay band</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""16"">" & vbLf
    Xml = Xml & "   <text name=""rt"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">reportheader band</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
    Xml = Xml & "   <text name=""pt"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""9"" wordWrap=""0"">pageheader band - grp / item / val</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""groupheader"" name=""gh"" group=""d.grp"" height=""8"">" & vbLf
    Xml = Xml & "   <text name=""gt"" x=""0"" y=""0"" w=""180"" h=""7"" style=""Grp"" wordWrap=""0"">groupheader band: {{d.grp}}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
    Xml = Xml & "   <text name=""di"" x=""4""   y=""0"" w=""120"" h=""5"" fontSize=""9"" wordWrap=""0"">detail band: {{d.item}}</text>" & vbLf
    Xml = Xml & "   <text name=""dv"" x=""130"" y=""0"" w=""46""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{d.val}}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""groupfooter"" name=""gf"" group=""d.grp"" height=""7"">" & vbLf
    Xml = Xml & "   <text name=""ft"" x=""0"" y=""1"" w=""180"" h=""5"" fontSize=""9"" italic=""1"" wordWrap=""0"">groupfooter band: end of {{d.grp}}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""pagefooter"" name=""pf"" height=""7"">" & vbLf
    Xml = Xml & "   <text name=""pft"" x=""0"" y=""1"" w=""180"" h=""5"" fontSize=""8"" hAlign=""center"" wordWrap=""0"">pagefooter band</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""summary"" name=""sm"" height=""16"">" & vbLf
    Xml = Xml & "   <text name=""st"" x=""0"" y=""2"" w=""180"" h=""10"" fontSize=""14"" hAlign=""center"">summary band - report complete</text>" & vbLf
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
    Pages = pdf.RptGetPageCount(Job)
    Debug.Print "rendered " & Pages & " page(s)"
    If pdf.RptExport(Job, 0, OutPdf) = 0 Then
        Debug.Print "export failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    If Pages < 2 Then
        Debug.Print "FAIL: expected >= 2 pages, got " & Pages
    Else
        Debug.Print "OK: multi-page grouped report with all band kinds"
    End If
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "04_bands (ActiveX)"
End Sub
