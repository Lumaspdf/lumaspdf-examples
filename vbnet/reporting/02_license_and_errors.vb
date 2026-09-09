' 02_license_and_errors -- VB.NET port of examples\Vb6\reporting\02_license_and_errors.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod02_license_and_errors
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

    Function FeaturesToStr(ByVal F As UInteger) As String
        Dim r As String = ""
        If (F And LumasPdfConsts.RPT_FEAT_CORE) <> 0 Then r = r & "CORE "
        If (F And LumasPdfConsts.RPT_FEAT_EXPORT_PDF) <> 0 Then r = r & "PDF "
        If (F And LumasPdfConsts.RPT_FEAT_EXPORT_WEB) <> 0 Then r = r & "WEB "
        If (F And LumasPdfConsts.RPT_FEAT_EXPORT_DATA) <> 0 Then r = r & "DATA "
        If (F And LumasPdfConsts.RPT_FEAT_PREVIEW) <> 0 Then r = r & "PREVIEW "
        If (F And LumasPdfConsts.RPT_FEAT_PRINT) <> 0 Then r = r & "PRINT "
        If (F And LumasPdfConsts.RPT_FEAT_PLUGINS) <> 0 Then r = r & "PLUGINS "
        Return r.Trim()
    End Function

    Function LastErrorCode(ByVal eng As IntPtr) As Integer
        Dim info As TRptErrorInfoC
        If GetRptErr(eng, info) Then Return info.Code Else Return 0
    End Function

    Sub ShowError(ByVal Tag As String, ByVal eng As IntPtr)
        Dim info As TRptErrorInfoC
        If GetRptErr(eng, info) AndAlso info.Code <> 0 Then
            Console.WriteLine("  " & Tag & " -> code " & info.Code & "  module=" & TrimNull(info.Module_) & _
                "  location=" & TrimNull(info.Location) & "  msg=" & TrimNull(info.Msg))
        Else
            Console.WriteLine("  " & Tag & " -> (no structured error reported)")
        End If
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        Dim GoodLrpt As String = AppPath() & "\02_good.lrpt"
        Dim BadLrpt As String = AppPath() & "\02_bad.lrpt"
        Dim OutPdf As String = AppPath() & "\02_out.pdf"
        Dim Job As IntPtr, PrevCode As Integer, Xml As String

        Console.WriteLine("== License info ==")
        Dim sz As Integer = Marshal.SizeOf(GetType(TRptLicenseInfoC))
        Dim lp As IntPtr = Marshal.AllocHGlobal(sz)
        Marshal.WriteInt32(lp, 0, sz)   ' StructSize
        If LumasPdf.rptGetLicenseInfo(mEng, lp) Then
            Dim li As TRptLicenseInfoC = CType(Marshal.PtrToStructure(lp, GetType(TRptLicenseInfoC)), TRptLicenseInfoC)
            Console.WriteLine("  Edition  : " & li.Edition)
            Console.WriteLine("  Features : $" & li.Features.ToString("X8") & " (" & FeaturesToStr(li.Features) & ")")
            Console.WriteLine("  LicClass : " & li.LicClass)
            Console.WriteLine("  LockClass: " & li.LockClass)
            If li.Expiry = 0 Then
                Console.WriteLine("  Expiry   : 0 (perpetual / unbound)")
            Else
                Console.WriteLine("  Expiry   : " & li.Expiry)
            End If
            Console.WriteLine("  Customer : " & TrimNull(li.Customer))
        Else
            Console.WriteLine("  rptGetLicenseInfo failed")
            DumpRptError(mEng)
        End If
        Marshal.FreeHGlobal(lp)

        Console.WriteLine("== Deliberate errors ==")

        WriteTextFile(BadLrpt, "this is not a report at all" & vbLf)
        Job = LumasPdf.rptOpenReportA(mEng, BadLrpt)
        If Job = IntPtr.Zero Then
            ShowError("open(not-XML .lrpt)", mEng)
        Else
            Console.WriteLine("  open(not-XML .lrpt) -> unexpectedly succeeded")
            LumasPdf.rptCloseReport(Job)
        End If

        WriteTextFile(BadLrpt, "<notreport><oops/></notreport>" & vbLf)
        Job = LumasPdf.rptOpenReportA(mEng, BadLrpt)
        If Job = IntPtr.Zero Then
            ShowError("open(wrong-root .lrpt)", mEng)
        Else
            Console.WriteLine("  open(wrong-root .lrpt) -> unexpectedly succeeded")
            LumasPdf.rptCloseReport(Job)
        End If

        PrevCode = LastErrorCode(mEng)
        If LumasPdf.rptRender(IntPtr.Zero) Then
            Console.WriteLine("  rptRender(nil) -> unexpectedly succeeded")
        ElseIf LastErrorCode(mEng) = PrevCode Then
            Console.WriteLine("  rptRender(nil) -> returned False; no new engine error (last code still " & PrevCode & ")")
        Else
            ShowError("rptRender(nil)", mEng)
        End If

        PrevCode = LastErrorCode(mEng)
        If LumasPdf.rptExportA(IntPtr.Zero, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("  rptExportA(nil) -> unexpectedly succeeded")
        ElseIf LastErrorCode(mEng) = PrevCode Then
            Console.WriteLine("  rptExportA(nil) -> returned False; no new engine error (last code still " & PrevCode & ")")
        Else
            ShowError("rptExportA(nil)", mEng)
        End If

        Console.WriteLine("== Valid render ==")
        Xml = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""LicDemo"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""16"">" & vbLf
        Xml = Xml & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">License &amp; error demo</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        WriteTextFile(GoodLrpt, Xml)
        Job = LumasPdf.rptOpenReportA(mEng, GoodLrpt)
        If Job = IntPtr.Zero Then
            Console.WriteLine("  open failed")
            DumpRptError(mEng)
            GoTo Cleanup
        End If
        If Not LumasPdf.rptRender(Job) Then
            Console.WriteLine("  render failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("  rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("  export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("  wrote " & OutPdf)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
