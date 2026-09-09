Attribute VB_Name = "mod16_data_odbc_northwind"
Option Explicit
' ============================================================================
'  LumasReport example 16 -- ODBC data provider over the real Northwind.mdb (VB6)
'  Covers: the "odbc" data provider, a live DB connection + JOIN + ORDER BY,
'  grouping (groupheader/groupfooter over a DB column), field interpolation.
'  Uses the 64-bit "Microsoft Access Driver (*.mdb, *.accdb)".
' ============================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long

Private Const MDB As String = "E:\LUMASPDFSDK\wrappers\vcl\Examples\Northwind.mdb"

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""Northwind"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <datasources>" & vbLf
    s = s & "  <datasource alias=""d"" provider=""odbc""" & vbLf
    ' NOTE: VB6 builds a 32-bit exe. The 32-bit ODBC stack here only has the legacy
    ' Jet "Microsoft Access Driver (*.mdb)" (the ACE "(*.mdb, *.accdb)" driver is
    ' 64-bit-only on this box). Northwind.mdb is legacy Jet, so the legacy driver reads it.
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

Public Sub Main()
    Dim Pdf As Long, Eng As Long, Job As Long
    Dim Dir_ As String, Lrpt As String, OutPdf As String, OutTxt As String
    If Dir(MDB) = "" Then Debug.Print "Northwind.mdb not found: " & MDB: Exit Sub
    If Not BootEngine(Pdf, Eng) Then Exit Sub

    Dir_ = App.Path & "\"
    Lrpt = Dir_ & "16_northwind.lrpt"
    OutPdf = Dir_ & "16_northwind.pdf"
    OutTxt = Dir_ & "16_northwind.txt"
    WriteText Lrpt, BuildXml()

    Job = rptOpenReport(Eng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError Eng: GoTo Cleanup
    If rptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError Eng: GoTo CloseJob
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s) from Northwind.mdb (odbc)"
    If rptExportA(Job, 0, OutPdf) = 0 Then Debug.Print "pdf export failed": DumpRptError Eng: GoTo CloseJob
    If rptExportA(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "text export failed": DumpRptError Eng: GoTo CloseJob
    Debug.Print "wrote " & OutPdf & "  +  " & OutTxt
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
