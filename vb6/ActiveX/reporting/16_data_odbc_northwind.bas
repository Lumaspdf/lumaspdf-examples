Attribute VB_Name = "mod16_data_odbc_northwind"
Option Explicit
' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\16_data_odbc_northwind.bas.
'  Same feature: the "odbc" data provider over the real Northwind.mdb, a live
'  DB connection + JOIN + ORDER BY, grouping (groupheader/groupfooter over a
'  DB column), field interpolation -- via the LumasPdf ActiveX component's
'  Rpt* methods.
'
'  VB6 is inherently a 32-bit process, and (see 13_plugin.bas) the ActiveX
'  component it loads is LumasPdfAX32.dll -- the engine itself therefore runs
'  the ODBC call in-process as 32-bit code too, so it needs a 32-bit ODBC
'  driver. This box's 32-bit ODBC stack only has the legacy Jet "Microsoft
'  Access Driver (*.mdb)" (the ACE "(*.mdb, *.accdb)" driver here is 64-bit
'  only); Northwind.mdb is legacy Jet format, so the legacy driver reads it
'  fine -- same substitution the flat-DLL VB6 original used, for the same
'  underlying (VB6-is-32-bit) reason.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Const RPT_EXP_PDF As Long = 0
Const RPT_EXP_TEXT As Long = 5

Private pdf As Object       ' LumasPdf.PDF (late-bound)
Private mEng As Long

Private Const MDB As String = "E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb"

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""Northwind"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <datasources>" & vbLf
    s = s & "  <datasource alias=""d"" provider=""odbc""" & vbLf
    s = s & "    conn=""Driver={Microsoft Access Driver (*.mdb)};Dbq=" & MDB & ";""" & vbLf
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
    BuildXml = s
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer, b() As Byte
    f = FreeFile
    On Error Resume Next
    Kill Path
    On Error GoTo 0
    b = StrConv(Content, vbFromUnicode)
    Open Path For Binary Access Write As #f
    Put #f, 1, b
    Close #f
End Sub

Private Sub DumpRptError()
    Debug.Print "  ! " & pdf.LastErrorMessage
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set pdf = CreateObject("LumasPdf.PDF")
    ' pdf.RaiseExceptions = True
    pdf.SetLicenseKey PDF_DEMO_KEY
    pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "RptCreateEngine failed: " & pdf.LastErrorMessage: Exit Function
    BootEngine = True
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long
    Dim Dir_ As String, Lrpt As String, OutPdf As String, OutTxt As String
    If Dir(MDB) = "" Then Debug.Print "Northwind.mdb not found: " & MDB: Exit Sub
    If Not BootEngine() Then Exit Sub

    Dir_ = App.Path & "\"
    Lrpt = Dir_ & "16_northwind.lrpt"
    OutPdf = Dir_ & "16_northwind.pdf"
    OutTxt = Dir_ & "16_northwind.txt"
    WriteText Lrpt, BuildXml()

    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError: GoTo Cleanup
    If pdf.RptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError: GoTo CloseJob
    Debug.Print "rendered " & pdf.RptGetPageCount(Job) & " page(s) from Northwind.mdb (odbc)"
    If pdf.RptExport(Job, RPT_EXP_PDF, OutPdf) = 0 Then Debug.Print "pdf export failed": DumpRptError: GoTo CloseJob
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "text export failed": DumpRptError: GoTo CloseJob
    Debug.Print "wrote " & OutPdf & "  +  " & OutTxt
CloseJob:
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "16_data_odbc_northwind (ActiveX)"
End Sub
