Attribute VB_Name = "mod17_invoice_lines"
Option Explicit
' ============================================================================
'  LumasReport example 17 -- Invoice with comprehensive LINE usage, exported to
'  MULTIPLE formats (PDF, HTML, SVG, TEXT + native CSV, XLSX, XLS).  (VB6 mirror)
'  Demonstrates the full <line> surface: orient h/v/free, scope band/section/page,
'  hAlign/vAlign placement, dash solid/dot/dash/dashdot, double, width, color, cap
'  ...and ties in inline aggregates: SUM(Qty*Price) for the totals block.
' ============================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

Private Function CsvData() As String
    Dim s As String
    s = s & "Item,Qty,Price" & vbLf
    s = s & "Widget Assembly A,2,25.00" & vbLf
    s = s & "Gadget Module B,1,149.50" & vbLf
    s = s & "Shielded Cable C,5,4.75" & vbLf
    s = s & "Power Adapter D,3,12.00" & vbLf
    s = s & "Mounting Bracket E,8,3.25" & vbLf
    CsvData = s
End Function

Private Function BuildXml() As String
    Dim s As String
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
    ' --- report header ---
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""30"">" & vbLf
    s = s & "   <text name=""co""  x=""0""   y=""0""  w=""110"" h=""10"" fontSize=""20"" bold=""1"" wordWrap=""0"">ACME Corporation</text>" & vbLf
    s = s & "   <text name=""ti""  x=""110"" y=""0""  w=""70""  h=""10"" style=""h1"" hAlign=""right"" wordWrap=""0"">INVOICE</text>" & vbLf
    s = s & "   <text name=""m1""  x=""0""   y=""13"" w=""120"" h=""5""  fontSize=""9"" wordWrap=""0"">Invoice #: INV-1042    Date: 2026-07-19</text>" & vbLf
    s = s & "   <text name=""m2""  x=""110"" y=""13"" w=""70""  h=""5""  fontSize=""9"" hAlign=""right"" wordWrap=""0"">Terms: Net 30</text>" & vbLf
    s = s & "   <line name=""hr1"" orient=""h"" scope=""page"" x=""0"" y=""24"" w=""0"" h=""2"" vAlign=""middle"" width=""1.2"" color=""00CC0000""/>" & vbLf
    s = s & "  </band>" & vbLf
    ' --- page header ---
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
    ' --- detail rows ---
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
    ' --- summary ---
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
    BuildXml = s
End Function

Private Sub ExportOne(ByVal Job As Long, ByVal Target As Long, ByVal Path As String)
    If rptExportA(Job, Target, Path) <> 0 Then
        Debug.Print "  wrote " & Path
    Else
        Debug.Print "  EXPORT FAILED for " & Path
    End If
End Sub

Public Sub Main()
    Dim Pdf As Long, Eng As Long, Job As Long
    Dim Dir_ As String, Csv As String, Lrpt As String, Xml As String
    If Not BootEngine(Pdf, Eng) Then Exit Sub

    Dir_ = App.Path & "\"
    Csv = Dir_ & "17_items.csv"
    WriteText Csv, CsvData()

    ' splice the CSV path into the report
    Xml = Replace(BuildXml(), "{{CSV}}", Csv)
    Lrpt = Dir_ & "17_invoice.lrpt"
    WriteText Lrpt, Xml

    Job = rptOpenReport(Eng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError Eng: GoTo Cleanup
    If rptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError Eng: GoTo CloseJob
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s); exporting to 7 formats:"
    ' visual formats (lines rendered natively)
    ExportOne Job, 0, Dir_ & "17_invoice.pdf"
    ExportOne Job, 3, Dir_ & "17_invoice.html"
    ExportOne Job, RPT_EXP_SVG, Dir_ & "17_invoice.svg"
    ExportOne Job, RPT_EXP_TEXT, Dir_ & "17_invoice.txt"
    ' native data formats (data-true grid: header + detail rows)
    ExportOne Job, 4, Dir_ & "17_invoice.csv"
    ExportOne Job, RPT_EXP_XLSX, Dir_ & "17_invoice.xlsx"
    ExportOne Job, 5, Dir_ & "17_invoice.xls"
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
