' 09_expressions -- VB.NET port of examples\Vb6\reporting\09_expressions.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod09_expressions
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

    Function LineEl(ByRef y As Integer, ByVal Label_ As String, ByVal Expr As String) As String
        Dim r As String = "   <text name=""l" & y & """ x=""0"" y=""" & y & """ w=""185"" h=""5"" fontSize=""9"" wordWrap=""0"">" & _
             Label_ & " -&gt; {{expr: " & Expr & "}}</text>" & vbLf
        y = y + 5
        Return r
    End Function

    Function BuildReport() As String
        Dim s As String = ""
        Dim y As Integer = 0
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
        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""Expressions"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""12"" marginTop=""12"" marginRight=""12"" marginBottom=""12""/>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""" & (y + 4) & """>" & vbLf
        Xml = Xml & s
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        Return Xml
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        Dim Xml As String = BuildReport()
        Dim Lrpt As String = AppPath() & "\09_expr.lrpt"
        Dim OutPdf As String = AppPath() & "\09_expr.pdf"
        Dim OutTxt As String = AppPath() & "\09_expr.txt"
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
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt)
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s); 41 expression lines -> " & OutTxt)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
