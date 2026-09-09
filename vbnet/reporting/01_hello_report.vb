' 01_hello_report -- VB.NET port of examples\Vb6\reporting\01_hello_report.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod01_hello_report
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

    Sub Main()
        ' rptGetVersion's out parameters are typed Integer() in the binding
        ' (matching the C# side), so the marshaller does the pinning. This used
        ' to AllocHGlobal three 4-byte buffers and read them back with
        ' Marshal.ReadInt32, because the VB generator flattened every array
        ' parameter to IntPtr -- a divergence from the C# binding since fixed in
        ' tools/gen_vb.py. Same native call, and no manual free to leak.
        Dim Mj(0) As Integer, Mn(0) As Integer, Pt(0) As Integer
        LumasPdf.rptGetVersion(Mj, Mn, Pt)
        Console.WriteLine("LumasReport v" & Mj(0) & "." & Mn(0) & "." & Pt(0))

        If Not BootEngine() Then Return

        Dim Lrpt As String = AppPath() & "\01_hello.lrpt"
        Dim OutPdf As String = AppPath() & "\01_hello.pdf"
        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""Hello"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""20"">" & vbLf
        Xml = Xml & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""20"" hAlign=""center"">Hello, LumasReport!</text>" & vbLf
        Xml = Xml & "   <text name=""sub""   x=""0"" y=""12"" w=""180"" h=""6"" fontSize=""10"" hAlign=""center"">The minimal engine -&gt; render -&gt; PDF flow.</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
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
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("wrote " & OutPdf)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
