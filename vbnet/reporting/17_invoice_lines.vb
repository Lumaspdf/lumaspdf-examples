' 17_invoice_lines -- VB.NET port of examples\Vb6\reporting\17_invoice_lines.bas
' Invoice with comprehensive <line> usage, exported to PDF/HTML/SVG/TEXT + native
' CSV/XLSX/XLS. Ties in inline aggregates: SUM(Qty*Price) for the totals block.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod17_invoice_lines
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
        s = s & "Widget Assembly A,2,25.00" & vbLf
        s = s & "Gadget Module B,1,149.50" & vbLf
        s = s & "Shielded Cable C,5,4.75" & vbLf
        s = s & "Power Adapter D,3,12.00" & vbLf
        s = s & "Mounting Bracket E,8,3.25" & vbLf
        Return s
    End Function

    Function BuildXml() As String
        Dim s As String = ""
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""Invoice"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <datasources><datasource alias=""d"" provider=""csv"" conn=""{{CSV}}""/></datasources>" & vbLf
        s = s & " <styles>" & vbLf
        s = s & "  <style name=""h1"" fontName=""Helvetica"" fontSize=""22"" bold=""1""/>" & vbLf
        s = s & "  <style name=""lbl"" fontName=""Helvetica"" fontSize=""9"" bold=""1""/>" & vbLf
        s = s & "  <style name=""tot"" fontName=""Helvetica"" fontSize=""12"" bold=""1""/>" & vbLf
        s = s & " </styles>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""30"">" & vbLf
        s = s & "   <text name=""co""  x=""0""   y=""0""  w=""110"" h=""10"" fontSize=""20"" bold=""1"" wordWrap=""0"">ACME Corporation</text>" & vbLf
        s = s & "   <text name=""ti""  x=""110"" y=""0""  w=""70""  h=""10"" style=""h1"" hAlign=""right"" wordWrap=""0"">INVOICE</text>" & vbLf
        s = s & "   <text name=""m1""  x=""0""   y=""13"" w=""120"" h=""5""  fontSize=""9"" wordWrap=""0"">Invoice #: INV-1042    Date: 2026-07-19</text>" & vbLf
        s = s & "   <text name=""m2""  x=""110"" y=""13"" w=""70""  h=""5""  fontSize=""9"" hAlign=""right"" wordWrap=""0"">Terms: Net 30</text>" & vbLf
        s = s & "   <line name=""hr1"" orient=""h"" scope=""page"" x=""0"" y=""24"" w=""0"" h=""2"" vAlign=""middle"" width=""1.2"" color=""00CC0000""/>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        s = s & "   <text name=""ci"" x=""0""   y=""0"" w=""78""  h=""5"" style=""lbl"" wordWrap=""0"">Description</text>" & vbLf
        s = s & "   <text name=""cq"" x=""80""  y=""0"" w=""23""  h=""5"" style=""lbl"" hAlign=""right"" wordWrap=""0"">Qty</text>" & vbLf
        s = s & "   <text name=""cp"" x=""105"" y=""0"" w=""33""  h=""5"" style=""lbl"" hAlign=""right"" wordWrap=""0"">Unit Price</text>" & vbLf
        s = s & "   <text name=""ca"" x=""140"" y=""0"" w=""40""  h=""5"" style=""lbl"" hAlign=""right"" wordWrap=""0"">Amount</text>" & vbLf
        s = s & "   <line name=""phv1"" orient=""v"" scope=""section"" x=""79""  width=""0.2"" color=""00909090""/>" & vbLf
        s = s & "   <line name=""phv2"" orient=""v"" scope=""section"" x=""104"" width=""0.2"" color=""00909090""/>" & vbLf
        s = s & "   <line name=""phv3"" orient=""v"" scope=""section"" x=""139"" width=""0.2"" color=""00909090""/>" & vbLf
        s = s & "   <line name=""hr2"" orient=""h"" x=""0"" y=""6"" w=""180"" h=""1"" vAlign=""middle"" width=""0.5"" color=""00404040""/>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
        s = s & "   <text name=""Description"" x=""0""   y=""0"" w=""78""  h=""5"" fontSize=""9"" wordWrap=""0"">{{Item}}</text>" & vbLf
        s = s & "   <text name=""Qty""         x=""80""  y=""0"" w=""23""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{Qty}}</text>" & vbLf
        s = s & "   <text name=""UnitPrice""   x=""105"" y=""0"" w=""33""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Price)}}</text>" & vbLf
        s = s & "   <text name=""Amount""      x=""140"" y=""0"" w=""40""  h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>" & vbLf
        s = s & "   <line name=""dv1"" orient=""v"" scope=""section"" x=""79""  width=""0.2"" color=""00CCCCCC""/>" & vbLf
        s = s & "   <line name=""dv2"" orient=""v"" scope=""section"" x=""104"" width=""0.2"" color=""00CCCCCC""/>" & vbLf
        s = s & "   <line name=""dv3"" orient=""v"" scope=""section"" x=""139"" width=""0.2"" color=""00CCCCCC""/>" & vbLf
        s = s & "   <line name=""rr"" orient=""h"" x=""0"" y=""0"" w=""180"" h=""5.5"" vAlign=""bottom"" dash=""dot"" width=""0.2"" color=""00AAAAAA""/>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""summary"" name=""sm"" height=""52"">" & vbLf
        s = s & "   <text name=""sl1"" x=""115"" y=""1"" w=""30"" h=""5"" style=""lbl"" wordWrap=""0"">Subtotal</text>" & vbLf
        s = s & "   <text name=""sv1"" x=""145"" y=""1"" w=""35"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>" & vbLf
        s = s & "   <text name=""sl2"" x=""115"" y=""7"" w=""30"" h=""5"" style=""lbl"" wordWrap=""0"">Tax (10%)</text>" & vbLf
        s = s & "   <text name=""sv2"" x=""145"" y=""7"" w=""35"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.1)}}</text>" & vbLf
        s = s & "   <line name=""dl"" orient=""h"" x=""115"" y=""14"" w=""65"" h=""1"" double=""1"" width=""0.4"" color=""00404040""/>" & vbLf
        s = s & "   <text name=""tl"" x=""115"" y=""16"" w=""30"" h=""6"" style=""tot"" wordWrap=""0"">TOTAL</text>" & vbLf
        s = s & "   <text name=""tv"" x=""140"" y=""16"" w=""40"" h=""6"" style=""tot"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.1)}}</text>" & vbLf
        s = s & "   <line name=""ac"" orient=""h"" x=""115"" y=""24"" w=""65"" h=""1"" double=""1"" dash=""dot"" width=""0.35"" color=""000000CC""/>" & vbLf
        s = s & "   <line name=""sg"" orient=""h"" x=""0"" y=""40"" w=""70"" h=""1"" dash=""dash"" width=""0.4"" cap=""round"" color=""00404040""/>" & vbLf
        s = s & "   <text name=""sgl"" x=""0"" y=""41"" w=""70"" h=""5"" fontSize=""8"" wordWrap=""0"">Authorized Signature</text>" & vbLf
        s = s & "   <text name=""pd"" x=""127"" y=""34"" w=""40"" h=""7"" style=""tot"" wordWrap=""0"">PAID</text>" & vbLf
        s = s & "   <line name=""fr"" orient=""h"" x=""127"" y=""43"" length=""24"" width=""1.0"" cap=""round"" color=""000000CC""/>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub ExportOne(ByVal Job As IntPtr, ByVal Target As Integer, ByVal Path As String)
        If LumasPdf.rptExportA(Job, Target, Path) Then
            Console.WriteLine("  wrote " & Path)
        Else
            Console.WriteLine("  EXPORT FAILED for " & Path)
        End If
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim Csv As String = Dir_ & "17_items.csv"
        WriteTextFile(Csv, CsvData())

        Dim Xml As String = BuildXml().Replace("{{CSV}}", Csv)
        Dim Lrpt As String = Dir_ & "17_invoice.lrpt"
        WriteTextFile(Lrpt, Xml)

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup
        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s); exporting to 7 formats:")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_PDF, Dir_ & "17_invoice.pdf")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_HTML, Dir_ & "17_invoice.html")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_SVG, Dir_ & "17_invoice.svg")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_TEXT, Dir_ & "17_invoice.txt")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_CSV, Dir_ & "17_invoice.csv")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_XLSX, Dir_ & "17_invoice.xlsx")
        ExportOne(Job, LumasPdfConsts.RPT_EXP_XLS, Dir_ & "17_invoice.xls")
CloseJob:
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
