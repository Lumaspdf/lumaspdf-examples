' 04_bands -- VB.NET port of examples\Vb6\reporting\04_bands.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod04_bands
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    Private mPdf As IntPtr
    Private mEng As IntPtr

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Function TrimNull(ByVal s As String) As String
        If s Is Nothing Then Return ""
        Dim p As Integer = s.IndexOf(ChrW(0))
        If p >= 0 Then Return s.Substring(0, p) Else Return s
    End Function

    Sub WriteTextFile(ByVal path As String, ByVal content As String)
        File.WriteAllText(path, content)
    End Sub

    Function GetRptErr(ByVal eng As IntPtr, ByRef info As TRptErrorInfoC) As Boolean
        Dim sz As Integer = Marshal.SizeOf(GetType(TRptErrorInfoC))
        Dim p As IntPtr = Marshal.AllocHGlobal(sz)
        Try
            Dim ok As Boolean = LumasPdf.rptGetLastError(eng, p)
            If ok Then info = CType(Marshal.PtrToStructure(p, GetType(TRptErrorInfoC)), TRptErrorInfoC)
            Return ok
        Finally
            Marshal.FreeHGlobal(p)
        End Try
    End Function

    Sub DumpRptError(ByVal eng As IntPtr)
        Dim info As TRptErrorInfoC
        If GetRptErr(eng, info) Then
            If info.Code <> 0 Then
                Console.WriteLine("  ! rpt error " & info.Code & " [" & TrimNull(info.Module_) & _
                    "] at " & TrimNull(info.Location) & ": " & TrimNull(info.Msg))
            End If
        End If
    End Sub

    Function BootEngine() As Boolean
        mPdf = LumasPdf.pdfNewPDF()
        If mPdf = IntPtr.Zero Then
            Console.WriteLine("pdfNewPDF failed")
            Return False
        End If
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY)
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY)
        mEng = LumasPdf.rptCreateEngineA(mPdf, Nothing)
        If mEng = IntPtr.Zero Then
            Console.WriteLine("rptCreateEngine failed:")
            DumpRptError(IntPtr.Zero)
            Return False
        End If
        Return True
    End Function

    Function BuildCsv() As String
        Dim sb As String = "grp,item,val" & vbLf
        Dim g As Integer, r As Integer
        For g = 1 To 3
            For r = 1 To 30
                sb = sb & "Group-" & g & ",Item " & g & "-" & r.ToString("00") & "," & (g * 100 + r) & vbLf
            Next
        Next
        Return sb
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        Dim Csv As String = AppPath() & "\04_data.csv"
        Dim Lrpt As String = AppPath() & "\04_report.lrpt"
        Dim OutPdf As String = AppPath() & "\04_out.pdf"
        WriteTextFile(Csv, BuildCsv())
        Dim Xml As String = ""
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
        WriteTextFile(Lrpt, Xml)

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then
            Console.WriteLine("open failed")
            DumpRptError(mEng)
            GoTo Cleanup
        End If
        If Not LumasPdf.rptRender(Job) Then
            Console.WriteLine("render failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Dim Pages As Integer = LumasPdf.rptGetPageCount(Job)
        Console.WriteLine("rendered " & Pages & " page(s)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("wrote " & OutPdf)
        If Pages < 2 Then
            Console.WriteLine("FAIL: expected >= 2 pages, got " & Pages)
        Else
            Console.WriteLine("OK: multi-page grouped report with all band kinds")
        End If
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
