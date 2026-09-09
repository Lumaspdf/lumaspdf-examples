' 03_export_targets -- VB.NET port of examples\Vb6\reporting\03_export_targets.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod03_export_targets
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

    Function FileSizeOf(ByVal path As String) As Long
        Try
            Return New FileInfo(path).Length
        Catch
            Return -1
        End Try
    End Function

    Sub Main()
        Dim Targets() As Integer = {LumasPdfConsts.RPT_EXP_PDF, LumasPdfConsts.RPT_EXP_HTML, LumasPdfConsts.RPT_EXP_CSV, _
            LumasPdfConsts.RPT_EXP_JSON, LumasPdfConsts.RPT_EXP_XML, LumasPdfConsts.RPT_EXP_TEXT, LumasPdfConsts.RPT_EXP_SVG, _
            LumasPdfConsts.RPT_EXP_XLSX, LumasPdfConsts.RPT_EXP_PNG, LumasPdfConsts.RPT_EXP_BMP}
        Dim Exts() As String = {"pdf", "html", "csv", "json", "xml", "txt", "svg", "xlsx", "png", "bmp"}

        If Not BootEngine() Then Return

        Dim Csv As String = AppPath() & "\03_data.csv"
        Dim Lrpt As String = AppPath() & "\03_report.lrpt"
        Dim CsvData As String = ""
        CsvData = CsvData & "product,qty,price" & vbLf
        CsvData = CsvData & "Widget,4,9.95" & vbLf
        CsvData = CsvData & "Gadget,2,19.50" & vbLf
        CsvData = CsvData & "Sprocket,7,3.25" & vbLf
        WriteTextFile(Csv, CsvData)
        Dim Xml As String = ""
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
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")
        Console.WriteLine("== Exporting to all targets ==")
        Dim i As Integer
        For i = 0 To 9
            Dim OutFile As String = AppPath() & "\03_out." & Exts(i)
            If LumasPdf.rptExportA(Job, Targets(i), OutFile) AndAlso File.Exists(OutFile) Then
                Console.WriteLine("  [" & Exts(i) & "] id=" & Targets(i) & "  OK  " & FileSizeOf(OutFile) & " bytes")
            Else
                Console.WriteLine("  [" & Exts(i) & "] id=" & Targets(i) & "  FAILED")
                DumpRptError(mEng)
            End If
        Next
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
