' 07_data_json_xml -- VB.NET port of examples\Vb6\reporting\07_data_json_xml.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod07_data_json_xml
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

    Function RunReport(ByVal Tag As String, ByVal Xml As String) As Boolean
        Dim Lrpt As String = AppPath() & "\07_" & Tag & ".lrpt"
        Dim OutPdf As String = AppPath() & "\07_" & Tag & ".pdf"
        Dim OutTxt As String = AppPath() & "\07_" & Tag & ".txt"
        WriteTextFile(Lrpt, Xml)
        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then
            Console.WriteLine(Tag & ": open failed")
            DumpRptError(mEng)
            Return False
        End If
        If Not LumasPdf.rptRender(Job) Then
            Console.WriteLine(Tag & ": render failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            Return False
        End If
        Console.WriteLine(Tag & ": rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine(Tag & ": pdf export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            Return False
        End If
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then
            Console.WriteLine(Tag & ": text export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            Return False
        End If
        Console.WriteLine("wrote " & OutPdf & " + " & OutTxt)
        LumasPdf.rptCloseReport(Job)
        Return True
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        Dim Jsn As String = AppPath() & "\07_data.json"
        Dim Xm As String = AppPath() & "\07_data.xml"
        Dim JsonData As String = "[{""City"":""Paris"",""Country"":""FR"",""Pop"":2100},{""City"":""Lyon"",""Country"":""FR"",""Pop"":515},{""City"":""Nice"",""Country"":""FR"",""Pop"":340}]"
        WriteTextFile(Jsn, JsonData)
        Dim XmlData As String = ""
        XmlData = XmlData & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        XmlData = XmlData & "<rows>" & vbLf
        XmlData = XmlData & " <row City=""Berlin"" Country=""DE"" Pop=""3600""/>" & vbLf
        XmlData = XmlData & " <row City=""Munich"" Country=""DE"" Pop=""1500""/>" & vbLf
        XmlData = XmlData & " <row City=""Hamburg"" Country=""DE"" Pop=""1900""/>" & vbLf
        XmlData = XmlData & "</rows>" & vbLf
        WriteTextFile(Xm, XmlData)

        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""JsonCities"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <datasources><datasource alias=""j"" provider=""json"" conn=""" & Jsn & """ query=""""/></datasources>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10"">" & vbLf
        Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (JSON source)</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""detail"" name=""jd"" height=""6"" data=""j"">" & vbLf
        Xml = Xml & "   <text name=""c1"" x=""0""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{j.City}}</text>" & vbLf
        Xml = Xml & "   <text name=""c2"" x=""60"" y=""0"" w=""30"" h=""5"" fontSize=""9"" wordWrap=""0"">{{j.Country}}</text>" & vbLf
        Xml = Xml & "   <text name=""c3"" x=""90"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{j.Pop}}</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        If Not RunReport("json", Xml) Then GoTo Cleanup
        Xml = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""XmlCities"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <datasources><datasource alias=""x"" provider=""xml"" conn=""" & Xm & """ query=""rows/row""/></datasources>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10"">" & vbLf
        Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Cities (XML source)</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""detail"" name=""xd"" height=""6"" data=""x"">" & vbLf
        Xml = Xml & "   <text name=""c1"" x=""0""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{x.City}}</text>" & vbLf
        Xml = Xml & "   <text name=""c2"" x=""60"" y=""0"" w=""30"" h=""5"" fontSize=""9"" wordWrap=""0"">{{x.Country}}</text>" & vbLf
        Xml = Xml & "   <text name=""c3"" x=""90"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{x.Pop}}</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        If Not RunReport("xml", Xml) Then GoTo Cleanup
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
