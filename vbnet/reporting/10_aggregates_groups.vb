' 10_aggregates_groups -- VB.NET port of examples\Vb6\reporting\10_aggregates_groups.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod10_aggregates_groups
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

    Sub Main()
        If Not BootEngine() Then Return

        Dim Csv As String = AppPath() & "\10_data.csv"
        Dim Lrpt As String = AppPath() & "\10_groups.lrpt"
        Dim OutPdf As String = AppPath() & "\10_groups.pdf"
        Dim OutTxt As String = AppPath() & "\10_groups.txt"

        Dim CsvData As String = ""
        CsvData = CsvData & "Cat,Item,Amount" & vbLf
        CsvData = CsvData & "Fruit,Apple,10" & vbLf
        CsvData = CsvData & "Fruit,Pear,7" & vbLf
        CsvData = CsvData & "Fruit,Plum,5" & vbLf
        CsvData = CsvData & "Dairy,Milk,4" & vbLf
        CsvData = CsvData & "Dairy,Cheese,9" & vbLf
        CsvData = CsvData & "Dairy,Butter,6" & vbLf
        CsvData = CsvData & "Grain,Bread,3" & vbLf
        CsvData = CsvData & "Grain,Rice,8" & vbLf
        CsvData = CsvData & "Grain,Oats,2" & vbLf
        WriteTextFile(Csv, CsvData)
        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""Groups"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""10""><text name=""t"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"" wordWrap=""0"">Grouped Catalog</text></band>" & vbLf
        Xml = Xml & "  <band kind=""groupheader"" name=""gh"" group=""d.Cat"" height=""7""><text name=""g"" x=""0"" y=""1"" w=""180"" h=""5"" fontSize=""12"" bold=""1"" wordWrap=""0"">Category: {{expr: d.Cat}}</text></band>" & vbLf
        Xml = Xml & "  <band kind=""detail"" name=""det"" height=""5"" data=""d""><text name=""i"" x=""6"" y=""0"" w=""110"" h=""4"" fontSize=""9"" wordWrap=""0"">{{Item}}</text><text name=""a"" x=""118"" y=""0"" w=""26"" h=""4"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{Amount}}</text><text name=""r"" x=""148"" y=""0"" w=""30"" h=""4"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">[{{expr: SUM(Amount)}}]</text></band>" & vbLf
        Xml = Xml & "  <band kind=""groupfooter"" name=""gf"" group=""d.Cat"" height=""6""><text name=""gt"" x=""4"" y=""0"" w=""176"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>" & vbLf
        Xml = Xml & "  <band kind=""summary"" name=""sm"" height=""8""><text name=""s"" x=""4"" y=""1"" w=""176"" h=""6"" fontSize=""11"" bold=""1"" wordWrap=""0"">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>" & vbLf
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
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s), grouped by Cat with per-group + grand totals")
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt)
        Console.WriteLine("wrote " & OutPdf & "  +  " & OutTxt)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
