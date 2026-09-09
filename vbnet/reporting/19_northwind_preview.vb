' 19_northwind_preview -- VB.NET port of examples\Vb6\reporting\19_northwind_preview.bas
' Build a .lrpt STEP-BY-STEP (STEP 1..14), bind it to the real Northwind.mdb (odbc),
' render + export, then optionally pop the SDK embedded viewer via rptPreviewA
' (blocks until closed; skipped with --headless / --no-preview).
' x64 build -> uses the 64-bit "Microsoft Access Driver (*.mdb, *.accdb)".
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod19_northwind_preview
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

    Function IsHeadless() As Boolean
        For Each a As String In Environment.GetCommandLineArgs()
            Dim c As String = a.ToLower()
            If c = "--headless" OrElse c = "--no-preview" OrElse c = "/headless" Then Return True
        Next
        Return False
    End Function

    Function BuildReportXml() As String
        Dim s As String = ""
        ' STEP 1 + 2  <report> + <page>
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""Northwind Catalog"" tagLangVersion=""1"">" & vbLf
        s = s & "  <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15""" & vbLf
        s = s & "        marginRight=""15"" marginBottom=""15""/>" & vbLf
        ' STEP 3  <datasources> -> Northwind.mdb (odbc)
        s = s & "  <datasources>" & vbLf
        s = s & "    <datasource alias=""d"" provider=""odbc""" & vbLf
        s = s & "      conn=""Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" & MDB & ";""" & vbLf
        s = s & "      query=""SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit," & vbLf
        s = s & "                    p.UnitPrice, p.UnitsInStock" & vbLf
        s = s & "             FROM Categories c INNER JOIN Products p" & vbLf
        s = s & "               ON c.CategoryID = p.CategoryID" & vbLf
        s = s & "             ORDER BY c.CategoryName, p.ProductName""/>" & vbLf
        s = s & "  </datasources>" & vbLf
        ' STEP 4  <params>
        s = s & "  <params>" & vbLf
        s = s & "    <param name=""Title""   default=""'Northwind Product Catalog'""/>" & vbLf
        s = s & "    <param name=""Company"" default=""'LumasPDF Trading Co.'""/>" & vbLf
        s = s & "  </params>" & vbLf
        ' STEP 5 + 6  <styles> + open <bands>
        s = s & "  <styles>" & vbLf
        s = s & "    <style name=""Bar""     backColor=""005F3A1F"" borderWidth=""0""/>" & vbLf
        s = s & "    <style name=""GrpBar""  backColor=""002A170F"" borderWidth=""0""/>" & vbLf
        s = s & "    <style name=""Title""   fontName=""Helvetica"" fontSize=""22"" bold=""1"" textColor=""00FFFFFF"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""Sub""     fontName=""Helvetica"" fontSize=""9""  textColor=""00FFFFFF"" hAlign=""2"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""ColH""    fontName=""Helvetica"" fontSize=""8""  bold=""1"" textColor=""00FFFFFF"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""ColHR""   fontName=""Helvetica"" fontSize=""8""  bold=""1"" textColor=""00FFFFFF"" hAlign=""2"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""Grp""     fontName=""Helvetica"" fontSize=""12"" bold=""1"" textColor=""00FFFFFF"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""Cell""    fontName=""Helvetica"" fontSize=""9""  textColor=""002A170F"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""CellR""   fontName=""Helvetica"" fontSize=""9""  textColor=""002A170F"" hAlign=""2"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""Muted""   fontName=""Helvetica"" fontSize=""8""  textColor=""008B7464"" vAlign=""1""/>" & vbLf
        s = s & "    <style name=""Sub L""   fontName=""Helvetica"" fontSize=""8.5"" bold=""1"" textColor=""005F3A1F""/>" & vbLf
        s = s & "    <style name=""SubR""    fontName=""Helvetica"" fontSize=""8.5"" bold=""1"" textColor=""005F3A1F"" hAlign=""2""/>" & vbLf
        s = s & "    <style name=""GTotL""   fontName=""Helvetica"" fontSize=""11"" bold=""1"" textColor=""00FFFFFF""/>" & vbLf
        s = s & "    <style name=""GTotR""   fontName=""Helvetica"" fontSize=""11"" bold=""1"" textColor=""00FFFFFF"" hAlign=""2""/>" & vbLf
        s = s & "    <style name=""Foot""    fontName=""Helvetica"" fontSize=""7.5"" textColor=""008B7464""/>" & vbLf
        s = s & "    <style name=""FootR""   fontName=""Helvetica"" fontSize=""7.5"" textColor=""008B7464"" hAlign=""2""/>" & vbLf
        s = s & "  </styles>" & vbLf
        s = s & "  <bands>" & vbLf
        ' STEP 7  reportheader
        s = s & "    <band kind=""reportheader"" name=""rh"" height=""26"">" & vbLf
        s = s & "      <shape name=""hbar""  x=""0"" y=""0"" w=""180"" h=""18"" style=""Bar"" shape=""0""/>" & vbLf
        s = s & "      <text  name=""ttl""   x=""5""  y=""1""  w=""120"" h=""10"" style=""Title"" wordWrap=""0"">{{var:Title}}</text>" & vbLf
        s = s & "      <text  name=""sub""   x=""95"" y=""6""  w=""80""  h=""6""  style=""Sub""   wordWrap=""0"">{{var:Company}}</text>" & vbLf
        s = s & "      <text  name=""asof""  x=""0""  y=""20"" w=""180"" h=""4""  style=""Muted"" wordWrap=""0"">Generated {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }} from Northwind.mdb (live ODBC)</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 8  pageheader
        s = s & "    <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        s = s & "      <shape name=""cbar"" x=""0"" y=""0"" w=""180"" h=""7"" style=""GrpBar"" shape=""0""/>" & vbLf
        s = s & "      <text name=""hP""  x=""3""   y=""1.5"" w=""64"" h=""4"" style=""ColH""  wordWrap=""0"">PRODUCT</text>" & vbLf
        s = s & "      <text name=""hK""  x=""69""  y=""1.5"" w=""44"" h=""4"" style=""ColH""  wordWrap=""0"">PACK</text>" & vbLf
        s = s & "      <text name=""hU""  x=""114"" y=""1.5"" w=""21"" h=""4"" style=""ColHR"" wordWrap=""0"">PRICE</text>" & vbLf
        s = s & "      <text name=""hS""  x=""137"" y=""1.5"" w=""18"" h=""4"" style=""ColHR"" wordWrap=""0"">STOCK</text>" & vbLf
        s = s & "      <text name=""hV""  x=""157"" y=""1.5"" w=""20"" h=""4"" style=""ColHR"" wordWrap=""0"">VALUE</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 9  groupheader
        s = s & "    <band kind=""groupheader"" name=""gh"" group=""d.CategoryName"" height=""9"">" & vbLf
        s = s & "      <shape name=""gbar"" x=""0"" y=""1"" w=""180"" h=""7"" style=""GrpBar"" shape=""0""/>" & vbLf
        s = s & "      <text  name=""gname"" x=""4"" y=""1.7"" w=""140"" h=""5"" style=""Grp"" wordWrap=""0"">{{expr: d.CategoryName}}</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 10  detail
        s = s & "    <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
        s = s & "      <shape name=""zebra"" x=""0"" y=""0"" w=""180"" h=""6"" shape=""0"" backColor=""00F9F5F1"" visible=""RowNum % 2 = 0""/>" & vbLf
        s = s & "      <text name=""cP"" x=""3""   y=""1"" w=""64"" h=""4"" style=""Cell""  wordWrap=""0"">{{ProductName}}</text>" & vbLf
        s = s & "      <text name=""cK"" x=""69""  y=""1"" w=""44"" h=""4"" style=""Muted"" wordWrap=""0"">{{QuantityPerUnit}}</text>" & vbLf
        s = s & "      <text name=""cU"" x=""114"" y=""1"" w=""21"" h=""4"" style=""CellR"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>" & vbLf
        s = s & "      <text name=""cS"" x=""137"" y=""1"" w=""18"" h=""4"" style=""CellR"" wordWrap=""0"">{{UnitsInStock}}</text>" & vbLf
        s = s & "      <text name=""cV"" x=""157"" y=""1"" w=""20"" h=""4"" style=""CellR"" wordWrap=""0"">{{expr: FORMATNUM('#,##0', UnitPrice*UnitsInStock) }}</text>" & vbLf
        s = s & "      <line name=""drow"" orient=""h"" scope=""section"" vAlign=""bottom"" width=""0.15"" color=""00E2D8CE""/>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 11  groupfooter
        s = s & "    <band kind=""groupfooter"" name=""gf"" group=""d.CategoryName"" height=""7"">" & vbLf
        s = s & "      <line name=""gtop"" orient=""h"" scope=""section"" vAlign=""top"" width=""0.4"" color=""005F3A1F""/>" & vbLf
        s = s & "      <text name=""sl"" x=""3""   y=""1.5"" w=""110"" h=""4"" style=""Sub L"" wordWrap=""0"">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>" & vbLf
        s = s & "      <text name=""sv"" x=""137"" y=""1.5"" w=""40""  h=""4"" style=""SubR""  wordWrap=""0"">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 12  summary
        s = s & "    <band kind=""summary"" name=""sm"" height=""16"">" & vbLf
        s = s & "      <shape name=""tbar"" x=""0"" y=""2"" w=""180"" h=""10"" style=""Bar"" shape=""0""/>" & vbLf
        s = s & "      <text name=""gl"" x=""4""   y=""4.2"" w=""120"" h=""6"" style=""GTotL"" wordWrap=""0"">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>" & vbLf
        s = s & "      <text name=""gv"" x=""120"" y=""4.2"" w=""56""  h=""6"" style=""GTotR"" wordWrap=""0"">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 13  pagefooter
        s = s & "    <band kind=""pagefooter"" name=""pf"" height=""9"">" & vbLf
        s = s & "      <line name=""ft"" orient=""h"" scope=""section"" vAlign=""top"" width=""0.3"" color=""00B9B9B9""/>" & vbLf
        s = s & "      <text name=""fl"" x=""0""   y=""2.5"" w=""120"" h=""4"" style=""Foot""  wordWrap=""0"">{{var:Company}} -- confidential</text>" & vbLf
        s = s & "      <text name=""fr"" x=""120"" y=""2.5"" w=""57""  h=""4"" style=""FootR"" wordWrap=""0"">Page {{var:PageNo}} of {{var:TotalPages}}</text>" & vbLf
        s = s & "    </band>" & vbLf
        ' STEP 14  close </bands></report>
        s = s & "  </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Main()
        If Not File.Exists(MDB) Then Console.WriteLine("Northwind.mdb not found: " & MDB) : Return
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim Lrpt As String = Dir_ & "19_northwind.lrpt"
        Dim OutPdf As String = Dir_ & "19_northwind.pdf"
        Dim OutTxt As String = Dir_ & "19_northwind.txt"
        Dim Pages As Integer = 0

        Dim Xml As String = BuildReportXml()
        WriteTextFile(Lrpt, Xml)
        Console.WriteLine("STEP 1-14: wrote " & Lrpt & " (" & Xml.Length & " bytes)")

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup

        LumasPdf.rptSetParamStr(Job, "Title", "Northwind Product Catalog")
        LumasPdf.rptSetParamStr(Job, "Company", "LumasPDF Trading Co.")

        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        Pages = LumasPdf.rptGetPageCount(Job)
        Console.WriteLine("RENDER: " & Pages & " page(s) bound from Northwind.mdb")

        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("pdf export failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("text export failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("EXPORT: " & OutPdf & "  +  " & OutTxt)

        ' *** EMBEDDED PREVIEW *** (blocks until the viewer window is closed)
        If IsHeadless() Then
            Console.WriteLine("PREVIEW: skipped (--headless). Open " & OutPdf & " to view.")
        Else
            Console.WriteLine("PREVIEW: opening the embedded viewer -- close the window to continue...")
            If Not LumasPdf.rptPreviewA(Job, "Northwind Product Catalog") Then
                Console.WriteLine("  preview failed (continuing -- not fatal):")
                DumpRptError(mEng)
            End If
        End If
CloseJob:
        LumasPdf.rptCloseReport(Job)

        If File.Exists(OutPdf) AndAlso (Pages >= 1) Then
            Console.WriteLine("OK: " & OutPdf & " exists, " & Pages & " page(s).")
        Else
            Console.WriteLine("VERIFY FAILED: PDF missing or zero pages")
        End If
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
