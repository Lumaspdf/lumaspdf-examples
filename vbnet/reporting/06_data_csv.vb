' 06_data_csv -- VB.NET port of examples\Vb6\reporting\06_data_csv.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod06_data_csv
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

        Dim Lrpt As String = AppPath() & "\06_data.lrpt"
        Dim Csv As String = AppPath() & "\06_data.csv"
        Dim OutPdf As String = AppPath() & "\06_data.pdf"
        Dim OutCsv As String = AppPath() & "\06_data_out.csv"
        Dim OutTxt As String = AppPath() & "\06_data.txt"

        Dim CsvData As String = ""
        CsvData = CsvData & "Region,Product,Qty,Price" & vbLf
        CsvData = CsvData & "North,Widget,10,2.50" & vbLf
        CsvData = CsvData & "North,Gadget,4,9.99" & vbLf
        CsvData = CsvData & "South,Widget,7,2.50" & vbLf
        CsvData = CsvData & "South,Sprocket,20,1.25" & vbLf
        CsvData = CsvData & "East,Gadget,3,9.99" & vbLf
        CsvData = CsvData & "West,Sprocket,15,1.25" & vbLf
        WriteTextFile(Csv, CsvData)
        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""CsvSales"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""12"">" & vbLf
        Xml = Xml & "   <text name=""ttl"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"">Sales by Region</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        Xml = Xml & "   <text name=""h1"" x=""0""   y=""0"" w=""50"" h=""6"" fontSize=""9"" style="""">REGION</text>" & vbLf
        Xml = Xml & "   <text name=""h2"" x=""50""  y=""0"" w=""60"" h=""6"" fontSize=""9"">PRODUCT</text>" & vbLf
        Xml = Xml & "   <text name=""h3"" x=""110"" y=""0"" w=""30"" h=""6"" fontSize=""9"" hAlign=""right"">QTY</text>" & vbLf
        Xml = Xml & "   <text name=""h4"" x=""140"" y=""0"" w=""40"" h=""6"" fontSize=""9"" hAlign=""right"">PRICE</text>" & vbLf
        Xml = Xml & "   <line name=""hl"" x=""0"" y=""7"" w=""180"" h=""0.3"" toX=""180"" toY=""0""/>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
        Xml = Xml & "   <text name=""c1"" x=""0""   y=""0"" w=""50"" h=""5"" fontSize=""9"" wordWrap=""0"">{{d.Region}}</text>" & vbLf
        Xml = Xml & "   <text name=""c2"" x=""50""  y=""0"" w=""60"" h=""5"" fontSize=""9"" wordWrap=""0"">{{d.Product}}</text>" & vbLf
        Xml = Xml & "   <text name=""c3"" x=""110"" y=""0"" w=""30"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{d.Qty}}</text>" & vbLf
        Xml = Xml & "   <text name=""c4"" x=""140"" y=""0"" w=""40"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{d.Price}}</text>" & vbLf
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
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("pdf export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_CSV, OutCsv) Then
            Console.WriteLine("csv export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then
            Console.WriteLine("text export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("wrote " & OutPdf)
        Console.WriteLine("wrote " & OutCsv)
        Console.WriteLine("wrote " & OutTxt)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
