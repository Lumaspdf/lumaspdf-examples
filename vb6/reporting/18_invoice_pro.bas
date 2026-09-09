Attribute VB_Name = "mod18_invoice_pro"
Option Explicit
' ============================================================================
'  LumasReport example 18 -- Professional FRAMED invoice (VB6 mirror)
'  A polished, print-ready invoice built from the banded model + the SECTION-
'  BOUNDED line feature (scope="section"): horizontal rules auto-span the band
'  WIDTH, vertical rules auto-span the band HEIGHT. Money columns right-aligned;
'  totals use inline SUM(Qty*Price). Exports to PDF/HTML/SVG/TEXT + CSV/XLSX/XLS.
' ============================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

' Colours are COLORREF 00BBGGRR (low byte = red).
Private Const NAVY As String = "005F3A1F"    ' #1F3A5F  brand / rules / totals
Private Const INK As String = "00222222"     ' near-black body text
Private Const GREY As String = "00808080"    ' muted labels
Private Const GRID As String = "00B9B9B9"    ' table grid lines
Private Const HAIR As String = "00D8D8D8"    ' hairline row rules
Private Const SHADE As String = "00F4F1EC"   ' zebra row tint
Private Const WHITE As String = "00FFFFFF"

Private Function CsvData() As String
    Dim s As String
    s = s & "Item,Qty,Price" & vbLf
    s = s & "Precision Widget Assembly,4,42.50" & vbLf
    s = s & "Gadget Control Module,2,149.50" & vbLf
    s = s & "Shielded Signal Cable (3m),10,4.75" & vbLf
    s = s & "Universal Power Adapter,3,28.00" & vbLf
    s = s & "Steel Mounting Bracket,12,3.25" & vbLf
    s = s & "Thermal Interface Kit,5,11.20" & vbLf
    CsvData = s
End Function

' The five vertical column dividers, section-scoped so each spans its band.
Private Function ColGrid(ByVal Tag As String) As String
    Dim s As String
    s = s & "   <line name=""" & Tag & "a"" orient=""v"" scope=""section"" x=""0""   width=""0.35"" color=""" & GRID & """/>" & vbLf
    s = s & "   <line name=""" & Tag & "b"" orient=""v"" scope=""section"" x=""95""  width=""0.35"" color=""" & GRID & """/>" & vbLf
    s = s & "   <line name=""" & Tag & "c"" orient=""v"" scope=""section"" x=""117"" width=""0.35"" color=""" & GRID & """/>" & vbLf
    s = s & "   <line name=""" & Tag & "d"" orient=""v"" scope=""section"" x=""149"" width=""0.35"" color=""" & GRID & """/>" & vbLf
    s = s & "   <line name=""" & Tag & "e"" orient=""v"" scope=""section"" x=""182"" width=""0.35"" color=""" & GRID & """/>" & vbLf
    ColGrid = s
End Function

Private Function BuildXml(ByVal Csv As String) As String
    Dim s As String
    Dim dot As String
    dot = ChrW(183)   ' middle dot U+00B7
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
    BuildXml = s
End Function

Private Sub ExportOne(ByVal Job As Long, ByVal Target As Long, ByVal Path As String)
    If rptExportA(Job, Target, Path) <> 0 Then Debug.Print "  wrote " & Path Else Debug.Print "  EXPORT FAILED: " & Path
End Sub

Public Sub Main()
    Dim Pdf As Long, Eng As Long, Job As Long
    Dim Dir_ As String, Csv As String, Lrpt As String
    If Not BootEngine(Pdf, Eng) Then Exit Sub

    Dir_ = App.Path & "\"
    Csv = Dir_ & "18_items.csv"
    WriteText Csv, CsvData()
    Lrpt = Dir_ & "18_invoice.lrpt"
    WriteText Lrpt, BuildXml(Csv)

    Job = rptOpenReport(Eng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError Eng: GoTo Cleanup
    If rptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError Eng: GoTo CloseJob
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s); exporting:"
    ExportOne Job, 0, Dir_ & "18_invoice.pdf"
    ExportOne Job, 3, Dir_ & "18_invoice.html"
    ExportOne Job, RPT_EXP_SVG, Dir_ & "18_invoice.svg"
    ExportOne Job, RPT_EXP_TEXT, Dir_ & "18_invoice.txt"
    ExportOne Job, 4, Dir_ & "18_invoice.csv"
    ExportOne Job, RPT_EXP_XLSX, Dir_ & "18_invoice.xlsx"
    ExportOne Job, 5, Dir_ & "18_invoice.xls"
CloseJob:
    rptCloseReport Job
Cleanup:
    rptDeleteEngine Eng
End Sub

' --- shared boilerplate (mirror of _shared.inc) -----------------------------

Private Function BootEngine(ByRef Pdf As Long, ByRef Eng As Long) As Boolean
    BootEngine = False
    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Call rptSetRptLicenseKeyA(Pdf.GetInstancePtr(), RPT_DEMO_KEY)
    mEng = rptCreateEngineA(Pdf.GetInstancePtr(), "")
    Eng = mEng
    Pdf = 0
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.GetErrorMessage(): Exit Function
    BootEngine = True
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    Dim b() As Byte
    f = FreeFile
    On Error Resume Next
    Kill Path
    On Error GoTo 0
    b = StrConv(Content, vbFromUnicode)
    Open Path For Binary Access Write As #f
    Put #f, 1, b
    Close #f
End Sub

Private Function Trim0(ByVal s As String) As String
    Dim p As Long
    p = InStr(s, vbNullChar)
    If p > 0 Then Trim0 = Left$(s, p - 1) Else Trim0 = s
End Function

Private Sub DumpRptError(ByVal Eng As Long)
    Debug.Print "  ! " & Pdf.GetErrorMessage()
End Sub
