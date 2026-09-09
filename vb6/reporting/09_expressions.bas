Attribute VB_Name = "mod09_expressions"
Option Explicit

' ===========================================================================
'  VB6 mirror of examples\delphi\reporting -- LumasReport (rpt*) exports.
'  Translated 1:1 from the Delphi original; OO/flat rpt* calls -> flat rpt*.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long


Private Function TrimNull(ByVal s As String) As String
    Dim p As Long
    p = InStr(s, Chr$(0))
    If p > 0 Then TrimNull = Left$(s, p - 1) Else TrimNull = s
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    f = FreeFile
    Open Path For Output As #f
    Print #f, Content;
    Close #f
End Sub

Private Sub DumpRptError(ByVal Eng As Long)
    Debug.Print "  ! " & Pdf.GetErrorMessage()
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Call rptSetRptLicenseKeyA(Pdf.GetInstancePtr(), RPT_DEMO_KEY)
    mEng = rptCreateEngineA(Pdf.GetInstancePtr(), "")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.GetErrorMessage(): Exit Function
    BootEngine = True
End Function

Private Function LineEl(ByRef y As Long, ByVal Label_ As String, ByVal Expr As String) As String
    LineEl = "   <text name=""l" & y & """ x=""0"" y=""" & y & """ w=""185"" h=""5"" fontSize=""9"" wordWrap=""0"">" & _
             Label_ & " -&gt; {{expr: " & Expr & "}}</text>" & vbLf
    y = y + 5
End Function

Private Function BuildReport() As String
    Dim s As String, y As Long, Xml As String
    y = 0
    s = ""
    s = s & LineEl(y, "UPPER", "UPPER('abc')")
    s = s & LineEl(y, "LOWER", "LOWER('ABC')")
    s = s & LineEl(y, "LEFT", "LEFT('LumasReport', 5)")
    s = s & LineEl(y, "RIGHT", "RIGHT('LumasReport', 6)")
    s = s & LineEl(y, "SUBSTR", "SUBSTR('LumasReport', 6, 6)")
    s = s & LineEl(y, "LEN", "LEN('LumasReport')")
    s = s & LineEl(y, "TRIM", "'[' + TRIM('  hi  ') + ']'")
    s = s & LineEl(y, "REPLACE", "REPLACE('a-b-c', '-', '+')")
    s = s & LineEl(y, "PADL", "PADL('7', 4, '0')")
    s = s & LineEl(y, "POS", "POS('Report', 'LumasReport')")
    s = s & LineEl(y, "REVERSE", "REVERSE('abc')")
    s = s & LineEl(y, "REPLICATE", "REPLICATE('ab', 3)")
    s = s & LineEl(y, "CONTAINS", "CONTAINS('LumasReport', 'Rep')")
    s = s & LineEl(y, "STARTSWITH", "STARTSWITH('LumasReport', 'Lumas')")
    s = s & LineEl(y, "ENDSWITH", "ENDSWITH('LumasReport', 'port')")
    s = s & LineEl(y, "ABS", "ABS(-42)")
    s = s & LineEl(y, "ROUND", "ROUND(3.14159, 2)")
    s = s & LineEl(y, "FLOOR", "FLOOR(3.9)")
    s = s & LineEl(y, "CEIL", "CEIL(3.1)")
    s = s & LineEl(y, "SQRT", "SQRT(144)")
    s = s & LineEl(y, "POWER", "POWER(2, 10)")
    s = s & LineEl(y, "MIN", "MIN(5, 3)")
    s = s & LineEl(y, "MAX", "MAX(5, 3)")
    s = s & LineEl(y, "SIGN", "SIGN(-7)")
    s = s & LineEl(y, "TRUNC", "TRUNC(9.87)")
    s = s & LineEl(y, "MOD_op", "17 % 5")
    s = s & LineEl(y, "YEAR", "YEAR(TODAY())")
    s = s & LineEl(y, "FORMATDATE", "FORMATDATE('yyyy-mm-dd', TODAY())")
    s = s & LineEl(y, "ADDDAYS", "FORMATDATE('yyyy-mm-dd', ADDDAYS(TODAY(), 7))")
    s = s & LineEl(y, "DATEDIFF", "DATEDIFF('d', TODAY(), ADDDAYS(TODAY(), 30))")
    s = s & LineEl(y, "CSTR", "CSTR(123)")
    s = s & LineEl(y, "CINT", "CINT('45')")
    s = s & LineEl(y, "CFLOAT", "CFLOAT('3.5') * 2")
    s = s & LineEl(y, "VAL", "VAL('19') + 1")
    s = s & LineEl(y, "FORMATNUM", "FORMATNUM('#,##0.00', 1234.5)")
    s = s & LineEl(y, "ISNULL", "ISNULL(NULLIF(3, 3))")
    s = s & LineEl(y, "IFNULL", "IFNULL(NULLIF(3, 3), 'was-null')")
    s = s & LineEl(y, "COALESCE", "COALESCE(NULLIF(1,1), NULLIF(2,2), 'fallback')")
    s = s & LineEl(y, "REGEXMATCH", "REGEXMATCH('abc123', '[a-z]+[0-9]+')")
    s = s & LineEl(y, "REGEXREPLACE", "REGEXREPLACE('a1b2c3', '[0-9]', '#')")
    s = s & LineEl(y, "REGEXEXTRACT", "REGEXEXTRACT('order 4567 ok', '[0-9]+')")
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""Expressions"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""12"" marginTop=""12"" marginRight=""12"" marginBottom=""12""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""" & (y + 4) & """>" & vbLf
    Xml = Xml & s
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    BuildReport = Xml
End Function

Public Sub Main()
    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, OutTxt As String, Xml As String

    If Not BootEngine() Then Exit Sub

    Xml = BuildReport()
    Lrpt = App.Path & "\09_expr.lrpt"
    OutPdf = App.Path & "\09_expr.pdf"
    OutTxt = App.Path & "\09_expr.txt"
    WriteText Lrpt, Xml

    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError mEng: GoTo Cleanup
    End If
    If rptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Pdf.RptExport Job, 0, OutPdf
    Pdf.RptExport Job, RPT_EXP_TEXT, OutTxt
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s); 41 expression lines -> " & OutTxt
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
