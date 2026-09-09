' 18_invoice_pro -- VB.NET port of examples\Vb6\reporting\18_invoice_pro.bas
' A polished, print-ready invoice built from the banded model + the SECTION-BOUNDED
' line feature (scope="section"). Exports to PDF/HTML/SVG/TEXT + CSV/XLSX/XLS.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod18_invoice_pro
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    ' Colours are COLORREF 00BBGGRR (low byte = red).
    Private Const NAVY As String = "005F3A1F"
    Private Const INK As String = "00222222"
    Private Const GREY As String = "00808080"
    Private Const GRID As String = "00B9B9B9"
    Private Const HAIR As String = "00D8D8D8"
    Private Const SHADE As String = "00F4F1EC"
    Private Const WHITE As String = "00FFFFFF"

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

    Function CsvData() As String
        Dim s As String = ""
        s = s & "Item,Qty,Price" & vbLf
        s = s & "Precision Widget Assembly,4,42.50" & vbLf
        s = s & "Gadget Control Module,2,149.50" & vbLf
        s = s & "Shielded Signal Cable (3m),10,4.75" & vbLf
        s = s & "Universal Power Adapter,3,28.00" & vbLf
        s = s & "Steel Mounting Bracket,12,3.25" & vbLf
        s = s & "Thermal Interface Kit,5,11.20" & vbLf
        Return s
    End Function

    ' The five vertical column dividers, section-scoped so each spans its band.
    Function ColGrid(ByVal Tag As String) As String
        Dim s As String = ""
        s = s & "   <line name=""" & Tag & "a"" orient=""v"" scope=""section"" x=""0""   width=""0.35"" color=""" & GRID & """/>" & vbLf
        s = s & "   <line name=""" & Tag & "b"" orient=""v"" scope=""section"" x=""95""  width=""0.35"" color=""" & GRID & """/>" & vbLf
        s = s & "   <line name=""" & Tag & "c"" orient=""v"" scope=""section"" x=""117"" width=""0.35"" color=""" & GRID & """/>" & vbLf
        s = s & "   <line name=""" & Tag & "d"" orient=""v"" scope=""section"" x=""149"" width=""0.35"" color=""" & GRID & """/>" & vbLf
        s = s & "   <line name=""" & Tag & "e"" orient=""v"" scope=""section"" x=""182"" width=""0.35"" color=""" & GRID & """/>" & vbLf
        Return s
    End Function

    Function BuildXml(ByVal Csv As String) As String
        Dim dot As String = ChrW(183)   ' middle dot U+00B7
        Dim s As String = ""
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""InvoicePro"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""14"" marginTop=""14"" marginRight=""14"" marginBottom=""16""/>" & vbLf
        s = s & " <datasources><datasource alias=""d"" provider=""csv"" conn=""" & Csv & """/></datasources>" & vbLf
        s = s & " <variables><variable name=""PageNo"" init=""1""/></variables>" & vbLf
        s = s & " <styles>" & vbLf
        s = s & "  <style name=""brand""  fontName=""Helvetica"" fontSize=""20"" bold=""1"" textColor=""" & NAVY & """/>" & vbLf
        s = s & "  <style name=""addr""   fontName=""Helvetica"" fontSize=""8""  textColor=""" & GREY & """/>" & vbLf
        s = s & "  <style name=""title""  fontName=""Helvetica"" fontSize=""30"" bold=""1"" textColor=""" & NAVY & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""mlbl""   fontName=""Helvetica"" fontSize=""8.5"" bold=""1"" textColor=""" & GREY & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""mval""   fontName=""Helvetica"" fontSize=""8.5"" textColor=""" & INK & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""billto"" fontName=""Helvetica"" fontSize=""8"" bold=""1"" textColor=""" & NAVY & """/>" & vbLf
        s = s & "  <style name=""cust""   fontName=""Helvetica"" fontSize=""9.5"" textColor=""" & INK & """/>" & vbLf
        s = s & "  <style name=""colh""   fontName=""Helvetica"" fontSize=""8.5"" bold=""1"" textColor=""" & WHITE & """/>" & vbLf
        s = s & "  <style name=""colhr""  fontName=""Helvetica"" fontSize=""8.5"" bold=""1"" textColor=""" & WHITE & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""cell""   fontName=""Helvetica"" fontSize=""9.5"" textColor=""" & INK & """/>" & vbLf
        s = s & "  <style name=""cellr""  fontName=""Helvetica"" fontSize=""9.5"" textColor=""" & INK & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""tlbl""   fontName=""Helvetica"" fontSize=""9.5"" bold=""1"" textColor=""" & INK & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""tval""   fontName=""Helvetica"" fontSize=""9.5"" textColor=""" & INK & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""glbl""   fontName=""Helvetica"" fontSize=""13"" bold=""1"" textColor=""" & WHITE & """/>" & vbLf
        s = s & "  <style name=""gval""   fontName=""Helvetica"" fontSize=""13"" bold=""1"" textColor=""" & WHITE & """ hAlign=""right""/>" & vbLf
        s = s & "  <style name=""note""   fontName=""Helvetica"" fontSize=""8.5"" textColor=""" & GREY & """/>" & vbLf
        s = s & "  <style name=""foot""   fontName=""Helvetica"" fontSize=""8"" textColor=""" & GREY & """/>" & vbLf
        s = s & "  <style name=""footr""  fontName=""Helvetica"" fontSize=""8"" textColor=""" & GREY & """ hAlign=""right""/>" & vbLf
        s = s & " </styles>" & vbLf
        s = s & " <bands>" & vbLf
        ' ============ REPORT HEADER ============
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""42"">" & vbLf
        s = s & "   <text name=""co""   x=""0""  y=""0""  w=""110"" h=""9"" style=""brand"" wordWrap=""0"">ACME Corporation</text>" & vbLf
        s = s & "   <text name=""a1""   x=""0""  y=""10"" w=""120"" h=""4"" style=""addr"" wordWrap=""0"">123 Industrial Way  " & dot & "  Springfield, IL 62704</text>" & vbLf
        s = s & "   <text name=""a2""   x=""0""  y=""14"" w=""120"" h=""4"" style=""addr"" wordWrap=""0"">+1 (555) 018-2245  " & dot & "  billing@acme.example</text>" & vbLf
        s = s & "   <text name=""ti""   x=""92"" y=""0""  w=""90""  h=""13"" style=""title"" wordWrap=""0"">INVOICE</text>" & vbLf
        s = s & "   <text name=""ml1""  x=""108"" y=""15"" w=""40"" h=""4"" style=""mlbl"" wordWrap=""0"">INVOICE #</text>" & vbLf
        s = s & "   <text name=""mv1""  x=""150"" y=""15"" w=""32"" h=""4"" style=""mval"" wordWrap=""0"">INV-1042</text>" & vbLf
        s = s & "   <text name=""ml2""  x=""108"" y=""20"" w=""40"" h=""4"" style=""mlbl"" wordWrap=""0"">ISSUE DATE</text>" & vbLf
        s = s & "   <text name=""mv2""  x=""150"" y=""20"" w=""32"" h=""4"" style=""mval"" wordWrap=""0"">2026-07-19</text>" & vbLf
        s = s & "   <text name=""ml3""  x=""108"" y=""25"" w=""40"" h=""4"" style=""mlbl"" wordWrap=""0"">DUE DATE</text>" & vbLf
        s = s & "   <text name=""mv3""  x=""150"" y=""25"" w=""32"" h=""4"" style=""mval"" wordWrap=""0"">2026-08-18</text>" & vbLf
        s = s & "   <text name=""bt""   x=""0""  y=""25"" w=""60"" h=""4"" style=""billto"" wordWrap=""0"">BILL TO</text>" & vbLf
        s = s & "   <text name=""c1""   x=""0""  y=""29.5"" w=""95"" h=""4.5"" style=""cust"" wordWrap=""0"">Globex Manufacturing Co.</text>" & vbLf
        s = s & "   <text name=""c2""   x=""0""  y=""33.5"" w=""95"" h=""4"" style=""addr"" wordWrap=""0"">500 Commerce Blvd, Metropolis, NY 10001</text>" & vbLf
        s = s & "   <line name=""rht"" orient=""h"" scope=""section"" vAlign=""top""    width=""0.3"" color=""" & HAIR & """/>" & vbLf
        s = s & "   <line name=""rhb"" orient=""h"" scope=""section"" vAlign=""bottom"" width=""1.1"" color=""" & NAVY & """/>" & vbLf
        s = s & "  </band>" & vbLf
        ' ============ COLUMN CAPTIONS (navy bar) ============
        s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        s = s & "   <shape name=""bar"" x=""0"" y=""0"" w=""182"" h=""8"" shape=""0"" backColor=""" & NAVY & """/>" & vbLf
        s = s & "   <text name=""hI"" x=""3""   y=""2"" w=""88"" h=""5"" style=""colh""  wordWrap=""0"">DESCRIPTION</text>" & vbLf
        s = s & "   <text name=""hQ"" x=""97""  y=""2"" w=""16"" h=""5"" style=""colhr"" wordWrap=""0"">QTY</text>" & vbLf
        s = s & "   <text name=""hP"" x=""119"" y=""2"" w=""26"" h=""5"" style=""colhr"" wordWrap=""0"">UNIT PRICE</text>" & vbLf
        s = s & "   <text name=""hA"" x=""151"" y=""2"" w=""29"" h=""5"" style=""colhr"" wordWrap=""0"">AMOUNT</text>" & vbLf
        s = s & ColGrid("phg")
        s = s & " </band>" & vbLf
        ' ============ DETAIL ROWS ============
        s = s & "  <band kind=""detail"" name=""det"" height=""7"" data=""d"">" & vbLf
        s = s & "   <shape name=""zebra"" x=""0"" y=""0"" w=""182"" h=""7"" shape=""0"" backColor=""" & SHADE & """ visible=""RowNum % 2 = 0""/>" & vbLf
        s = s & "   <text name=""dI"" x=""3""   y=""1.6"" w=""90"" h=""4"" style=""cell""  wordWrap=""0"">{{Item}}</text>" & vbLf
        s = s & "   <text name=""dQ"" x=""97""  y=""1.6"" w=""16"" h=""4"" style=""cellr"" wordWrap=""0"">{{Qty}}</text>" & vbLf
        s = s & "   <text name=""dP"" x=""119"" y=""1.6"" w=""26"" h=""4"" style=""cellr"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Price)}}</text>" & vbLf
        s = s & "   <text name=""dA"" x=""151"" y=""1.6"" w=""29"" h=""4"" style=""cellr"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>" & vbLf
        s = s & ColGrid("dg")
        s = s & "   <line name=""drb"" orient=""h"" scope=""section"" vAlign=""bottom"" width=""0.2"" color=""" & HAIR & """/>" & vbLf
        s = s & "  </band>" & vbLf
        ' ============ SUMMARY ============
        s = s & "  <band kind=""summary"" name=""sm"" height=""46"">" & vbLf
        s = s & "   <line name=""stop"" orient=""h"" scope=""section"" vAlign=""top"" width=""0.6"" color=""" & NAVY & """/>" & vbLf
        s = s & "   <text name=""nh"" x=""0"" y=""4""  w=""95"" h=""4"" style=""billto"" wordWrap=""0"">NOTES</text>" & vbLf
        s = s & "   <text name=""n1"" x=""0"" y=""8.5"" w=""100"" h=""4"" style=""note"" wordWrap=""0"">Payment due within 30 days. Bank transfer to</text>" & vbLf
        s = s & "   <text name=""n2"" x=""0"" y=""12""  w=""100"" h=""4"" style=""note"" wordWrap=""0"">ACME Corp " & dot & " IBAN GB00 ACME 0000 1042 " & dot & " Ref INV-1042.</text>" & vbLf
        s = s & "   <text name=""s1l"" x=""100"" y=""4""  w=""45"" h=""4.5"" style=""tlbl"" wordWrap=""0"">Subtotal</text>" & vbLf
        s = s & "   <text name=""s1v"" x=""149"" y=""4""  w=""31"" h=""4.5"" style=""tval"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>" & vbLf
        s = s & "   <text name=""s2l"" x=""100"" y=""9.5"" w=""45"" h=""4.5"" style=""tlbl"" wordWrap=""0"">Tax (8.5%)</text>" & vbLf
        s = s & "   <text name=""s2v"" x=""149"" y=""9.5"" w=""31"" h=""4.5"" style=""tval"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.085)}}</text>" & vbLf
        s = s & "   <shape name=""gbar"" x=""100"" y=""16"" w=""82"" h=""10"" shape=""0"" backColor=""" & NAVY & """/>" & vbLf
        s = s & "   <text name=""gl"" x=""104"" y=""18.5"" w=""40"" h=""6"" style=""glbl"" wordWrap=""0"">TOTAL</text>" & vbLf
        s = s & "   <text name=""gv"" x=""149"" y=""18.5"" w=""29"" h=""6"" style=""gval"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.085)}}</text>" & vbLf
        s = s & "   <text name=""gc"" x=""100"" y=""28"" w=""82"" h=""4"" style=""footr"" wordWrap=""0"">USD " & dot & " Total items {{expr: COUNT()}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        ' ============ PAGE FOOTER ============
        s = s & "  <band kind=""pagefooter"" name=""pf"" height=""12"">" & vbLf
        s = s & "   <line name=""pft"" orient=""h"" scope=""section"" vAlign=""top"" width=""0.3"" color=""" & GRID & """/>" & vbLf
        s = s & "   <text name=""ty"" x=""0""   y=""3"" w=""120"" h=""4"" style=""foot""  wordWrap=""0"">Thank you for your business.  Questions? billing@acme.example</text>" & vbLf
        s = s & "   <text name=""pg"" x=""120"" y=""3"" w=""62""  h=""4"" style=""footr"" wordWrap=""0"">Page {{var:PageNo}} of {{var:TotalPages}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub ExportOne(ByVal Job As IntPtr, ByVal Target As Integer, ByVal Path As String)
        If LumasPdf.rptExportA(Job, Target, Path) Then Console.WriteLine("  wrote " & Path) Else Console.WriteLine("  EXPORT FAILED: " & Path)
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim Csv As String = Dir_ & "18_items.csv"
        WriteTextFile(Csv, CsvData())
        Dim Lrpt As String = Dir_ & "18_invoice.lrpt"
        WriteTextFile(Lrpt, BuildXml(Csv))

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup
        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s); exporting:")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_PDF, Dir_ & "18_invoice.pdf")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_HTML, Dir_ & "18_invoice.html")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_SVG, Dir_ & "18_invoice.svg")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_TEXT, Dir_ & "18_invoice.txt")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_CSV, Dir_ & "18_invoice.csv")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_XLSX, Dir_ & "18_invoice.xlsx")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_XLS, Dir_ & "18_invoice.xls")
CloseJob:
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
