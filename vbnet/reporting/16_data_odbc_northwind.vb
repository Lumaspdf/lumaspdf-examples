' 16_data_odbc_northwind -- VB.NET port of examples\Vb6\reporting\16_data_odbc_northwind.bas
' The "odbc" data provider over the real Northwind.mdb: live DB connection + JOIN +
' ORDER BY, grouping (groupheader/groupfooter), field interpolation.
' x64 build -> uses the 64-bit "Microsoft Access Driver (*.mdb, *.accdb)".
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod16_data_odbc_northwind
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    Private Const MDB As String = "E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb"

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

    Sub DumpRptError(ByVal eng As IntPtr)
        Dim sz As Integer = Marshal.SizeOf(GetType(TRptErrorInfoC))
        Dim p As IntPtr = Marshal.AllocHGlobal(sz)
        Try
            If LumasPdf.rptGetLastError(eng, p) Then
                Dim info As TRptErrorInfoC = CType(Marshal.PtrToStructure(p, GetType(TRptErrorInfoC)), TRptErrorInfoC)
                If info.Code <> 0 Then
                    Console.WriteLine("  ! rpt error " & info.Code & " [" & TrimNull(info.Module_) & _
                        "] at " & TrimNull(info.Location) & ": " & TrimNull(info.Msg))
                End If
            End If
        Finally
            Marshal.FreeHGlobal(p)
        End Try
    End Sub

    Function BootEngine() As Boolean
        mPdf = LumasPdf.pdfNewPDF()
        If mPdf = IntPtr.Zero Then Console.WriteLine("pdfNewPDF failed") : Return False
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY)
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY)
        mEng = LumasPdf.rptCreateEngineA(mPdf, Nothing)
        If mEng = IntPtr.Zero Then Console.WriteLine("rptCreateEngine failed") : Return False
        Return True
    End Function

    Function BuildXml() As String
        Dim s As String = ""
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""Northwind"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <datasources>" & vbLf
        s = s & "  <datasource alias=""d"" provider=""odbc""" & vbLf
        ' x64 build: the 64-bit ACE "(*.mdb, *.accdb)" driver reads legacy Jet Northwind.mdb.
        s = s & "    conn=""Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" & MDB & ";""" & vbLf
        s = s & "    query=""SELECT c.CategoryName, p.ProductName, p.UnitPrice, p.UnitsInStock FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ORDER BY c.CategoryName, p.ProductName""/>" & vbLf
        s = s & " </datasources>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""14"">" & vbLf
        s = s & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"" wordWrap=""0"">Northwind Product Catalog</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        s = s & "   <text name=""c1"" x=""0""   y=""0"" w=""110"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Product</text>" & vbLf
        s = s & "   <text name=""c2"" x=""120"" y=""0"" w=""30""  h=""5"" fontSize=""9"" bold=""1"" hAlign=""right"" wordWrap=""0"">Price</text>" & vbLf
        s = s & "   <text name=""c3"" x=""152"" y=""0"" w=""28""  h=""5"" fontSize=""9"" bold=""1"" hAlign=""right"" wordWrap=""0"">Stock</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""groupheader"" name=""gh"" group=""d.CategoryName"" height=""8"">" & vbLf
        s = s & "   <text name=""g"" x=""0"" y=""1"" w=""180"" h=""6"" fontSize=""12"" bold=""1"" wordWrap=""0"">{{expr: d.CategoryName}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
        s = s & "   <text name=""p""  x=""4""   y=""0"" w=""110"" h=""5"" fontSize=""9"" wordWrap=""0"">{{ProductName}}</text>" & vbLf
        s = s & "   <text name=""pr"" x=""120"" y=""0"" w=""30""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>" & vbLf
        s = s & "   <text name=""sk"" x=""152"" y=""0"" w=""28""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{UnitsInStock}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""groupfooter"" name=""gf"" group=""d.CategoryName"" height=""4"">" & vbLf
        s = s & "   <text name=""ge"" x=""4"" y=""0"" w=""176"" h=""4"" fontSize=""7"" wordWrap=""0"">-- end of {{expr: d.CategoryName}} --</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""pagefooter"" name=""pf"" height=""6"">" & vbLf
        s = s & "   <text name=""f"" x=""0"" y=""0"" w=""180"" h=""5"" fontSize=""7"" hAlign=""right"" wordWrap=""0"">printed {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Main()
        If Not File.Exists(MDB) Then Console.WriteLine("Northwind.mdb not found: " & MDB) : Return
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim Lrpt As String = Dir_ & "16_northwind.lrpt"
        Dim OutPdf As String = Dir_ & "16_northwind.pdf"
        Dim OutTxt As String = Dir_ & "16_northwind.txt"
        WriteTextFile(Lrpt, BuildXml())

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup
        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s) from Northwind.mdb (odbc)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("pdf export failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("text export failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("wrote " & OutPdf & "  +  " & OutTxt)
CloseJob:
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
