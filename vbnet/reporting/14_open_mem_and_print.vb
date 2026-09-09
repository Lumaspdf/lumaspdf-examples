' 14_open_mem_and_print -- VB.NET port of examples\Vb6\reporting\14_open_mem_and_print.bas
'   1. rptOpenReportMem: hand the .lrpt markup bytes straight to the engine.
'   2. rptPrintA: headless print via "Microsoft Print to PDF" (fails softly).
' Exports covered: rptOpenReportMem, rptRender, rptGetPageCount, rptExportA, rptPrintA.
Imports System
Imports System.IO
Imports System.Text
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod14_open_mem_and_print
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
        s = s & "<report name=""InMem"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
        s = s & "   <text name=""title"" x=""0"" y=""0""  w=""180"" h=""12"" fontSize=""20"" hAlign=""center"">In-memory report</text>" & vbLf
        s = s & "   <text name=""sub""   x=""0"" y=""14"" w=""180"" h=""6""  fontSize=""10"" hAlign=""center"">Opened with rptOpenReportMem -- no file on disk.</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
        s = s & "   <text name=""ph1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""9"" hAlign=""left"">LumasReport example 14</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""detail"" name=""det"" height=""8"">" & vbLf
        s = s & "   <text name=""d1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""11"" hAlign=""left"">This band was rendered from bytes handed to the engine directly.</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""pagefooter"" name=""pf"" height=""8"">" & vbLf
        s = s & "   <text name=""pf1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""8"" hAlign=""right"">page {{var:PageNo}} of {{var:TotalPages}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim OutPdf As String = Dir_ & "14_open_mem.pdf"
        Dim OutPrint As String = Dir_ & "14_printed.pdf"

        ' --- 1. Open straight from memory (no temp file) ------------------------
        Console.WriteLine("== Open from memory ==")
        Dim bytes() As Byte = Encoding.UTF8.GetBytes(BuildXml())
        Dim nBytes As Integer = bytes.Length
        Console.WriteLine("  blob is " & nBytes & " bytes")
        Dim buf As IntPtr = Marshal.AllocHGlobal(nBytes)
        Dim Job As IntPtr = IntPtr.Zero
        Dim Pages As Integer = 0
        Try
            Marshal.Copy(bytes, 0, buf, nBytes)
            Job = LumasPdf.rptOpenReportMem(mEng, buf, nBytes)
            If Job = IntPtr.Zero Then Console.WriteLine("  rptOpenReportMem failed") : DumpRptError(mEng) : GoTo Cleanup

            If Not LumasPdf.rptRender(Job) Then Console.WriteLine("  render failed") : DumpRptError(mEng) : GoTo CloseJob
            Pages = LumasPdf.rptGetPageCount(Job)
            Console.WriteLine("  rendered " & Pages & " page(s) from the in-memory report")

            ' --- 2a. Export the in-memory report to a PDF -----------------------
            Console.WriteLine("== Export ==")
            If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("  export failed") : DumpRptError(mEng) : GoTo CloseJob
            Console.WriteLine("  wrote " & OutPdf)

            ' --- 2b. Headless print via "Microsoft Print to PDF" ----------------
            Console.WriteLine("== Headless print ==")
            If LumasPdf.rptPrintA(Job, "Microsoft Print to PDF", OutPrint) Then
                Console.WriteLine("  ""Microsoft Print to PDF"" -> " & OutPrint)
            Else
                Console.WriteLine("  ""Microsoft Print to PDF"" not available / print failed (continuing -- not fatal):")
                DumpRptError(mEng)
            End If

            ' --- 2c. Preview (documented, deliberately NOT called) --------------
            '  rptPreviewA(Job, "In-memory report") would pop the built-in modal viewer.
CloseJob:
            LumasPdf.rptCloseReport(Job)

            ' --- 3. Verify the in-memory PDF is real ----------------------------
            Console.WriteLine("== Verify ==")
            If File.Exists(OutPdf) AndAlso (Pages >= 1) Then
                Console.WriteLine("  OK: " & OutPdf & " exists, report has " & Pages & " page(s)")
            Else
                Console.WriteLine("  VERIFY FAILED: in-memory PDF missing or zero pages")
            End If
        Finally
            Marshal.FreeHGlobal(buf)
        End Try
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
