' 11_parameters -- VB.NET port of examples\Vb6\reporting\11_parameters.bas
' Declares <params> and drives them from VB at JOB level via rptSetParamStr /
' rptSetParamNum / rptSetParamInt, rendering the whole report TWICE.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod11_parameters
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

    Function BuildXml() As String
        Dim s As String = ""
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""Params"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <params>" & vbLf
        s = s & "  <param name=""Customer"" default=""ACME (default)""/>" & vbLf
        s = s & "  <param name=""UnitPrice"" default=""0""/>" & vbLf
        s = s & "  <param name=""Qty"" default=""0""/>" & vbLf
        s = s & " </params>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""30"">" & vbLf
        s = s & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">Invoice for {{var:Customer}}</text>" & vbLf
        s = s & "   <text name=""line1"" x=""0"" y=""14"" w=""180"" h=""6"" fontSize=""11"">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>" & vbLf
        s = s & "   <text name=""line2"" x=""0"" y=""22"" w=""180"" h=""6"" fontSize=""11"">TOTAL = {{expr: UnitPrice * Qty}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Function RunOnce(ByVal Lrpt As String, ByVal OutPdf As String, ByVal OutTxt As String, _
        ByVal Customer As String, ByVal UnitPrice As Double, ByVal Qty As Integer) As Boolean
        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("  open failed") : DumpRptError(mEng) : Return False
        Try
            If Not LumasPdf.rptSetParamStr(Job, "Customer", Customer) Then Console.WriteLine("  SetParamStr failed") : DumpRptError(mEng) : Return False
            If Not LumasPdf.rptSetParamNum(Job, "UnitPrice", UnitPrice) Then Console.WriteLine("  SetParamNum failed") : DumpRptError(mEng) : Return False
            If Not LumasPdf.rptSetParamInt(Job, "Qty", Qty) Then Console.WriteLine("  SetParamInt failed") : DumpRptError(mEng) : Return False
            If Not LumasPdf.rptRender(Job) Then Console.WriteLine("  render failed") : DumpRptError(mEng) : Return False
            If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("  export PDF failed") : DumpRptError(mEng) : Return False
            If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("  export TEXT failed") : DumpRptError(mEng) : Return False
            Console.WriteLine("  wrote " & OutPdf & "  (Customer=""" & Customer & """ UnitPrice=" & UnitPrice & " Qty=" & Qty & " TOTAL=" & (UnitPrice * Qty) & ")")
            Return True
        Finally
            LumasPdf.rptCloseReport(Job)
        End Try
    End Function

    Sub Main()
        If Not BootEngine() Then Return
        Dim Dir_ As String = AppPath() & "\"
        Dim Lrpt As String = Dir_ & "11_parameters.lrpt"
        WriteTextFile(Lrpt, BuildXml())

        Console.WriteLine("Run #1:")
        If Not RunOnce(Lrpt, Dir_ & "11_run1.pdf", Dir_ & "11_run1.txt", "Globex Corporation", 12.5, 4) Then GoTo Cleanup
        Console.WriteLine("Run #2:")
        If Not RunOnce(Lrpt, Dir_ & "11_run2.pdf", Dir_ & "11_run2.txt", "Initech LLC", 9.99, 10) Then GoTo Cleanup
        Console.WriteLine("OK")
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
