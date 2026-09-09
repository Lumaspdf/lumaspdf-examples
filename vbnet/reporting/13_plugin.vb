' 13_plugin -- Custom function + custom exporter, NO plugin DLL (VB.NET port)
' Instead of loading rpt_testplugin.dll via rptLoadPlugin, this registers the very
' same PlugDouble(x)=x*2 expression function AND a custom export target directly on
' the engine through native-callback delegates:
'   rptRegisterFunction(eng, "PlugDouble", 1, 1, fnPtr, 0)   ' {{expr: PlugDouble(21)}}
'   rptRegisterExporter (eng, 100, expPtr, 0)                ' rptExport(job, 100, path)
' Both callbacks use the engine's stdcall C ABI. The delegates are kept alive in
' module fields so the GC cannot collect the thunks. No external plugin DLL is used.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod13_plugin
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    ' TRptCValue ordinals and field offsets: Kind@0, B@4, I@8, F@16, S@24.
    Private Const VK_INT As Integer = 2
    Private Const VK_FLOAT As Integer = 3
    Private Const OFF_I As Integer = 8
    Private Const OFF_F As Integer = 16
    ' Custom export target id (must be >= 100).
    Private Const TARGET_CUSTOM As Integer = 100
    Private Const EXPORT_MARKER As String = _
        "PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)"

    ' stdcall callback ABIs. Args/ResultV are PRptCValue; Job/Path are opaque + PAnsiChar.
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Delegate Function TRptUserFn(ByVal User As IntPtr, ByVal Args As IntPtr, ByVal NArgs As Integer, ByVal ResultV As IntPtr) As Integer
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Delegate Function TRptExporterFn(ByVal User As IntPtr, ByVal Job As IntPtr, ByVal Path As IntPtr) As Integer

    Private mPdf As IntPtr
    Private mEng As IntPtr
    ' Keep the delegates alive so the GC does not collect the marshalled thunks.
    Private gPlugDouble As TRptUserFn
    Private gPlugExport As TRptExporterFn

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

    ' PlugDouble(x) -> x*2, preserving the numeric kind (int stays int, float stays float).
    Function PlugDoubleFn(ByVal User As IntPtr, ByVal Args As IntPtr, ByVal NArgs As Integer, ByVal ResultV As IntPtr) As Integer
        If (NArgs <> 1) OrElse (Args = IntPtr.Zero) OrElse (ResultV = IntPtr.Zero) Then Return -1
        Dim kind As Integer = Marshal.ReadInt32(Args, 0)
        If kind = VK_INT Then
            Dim v As Long = Marshal.ReadInt64(Args, OFF_I)
            Marshal.WriteInt32(ResultV, 0, VK_INT)
            Marshal.WriteInt64(ResultV, OFF_I, v * 2)
        ElseIf kind = VK_FLOAT Then
            Dim f As Double = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(Args, OFF_F))
            Marshal.WriteInt32(ResultV, 0, VK_FLOAT)
            Marshal.WriteInt64(ResultV, OFF_F, BitConverter.DoubleToInt64Bits(f * 2.0))
        Else
            Return -2
        End If
        Return 0
    End Function

    ' Custom exporter for target id 100: write a marker file to the requested path.
    Function PlugExportFn(ByVal User As IntPtr, ByVal Job As IntPtr, ByVal Path As IntPtr) As Integer
        Dim p As String = Marshal.PtrToStringAnsi(Path)
        If String.IsNullOrEmpty(p) Then Return -1
        Try
            File.WriteAllText(p, EXPORT_MARKER)
        Catch
            Return -2
        End Try
        Return 0
    End Function

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
        s = s & "<report name=""Plugin"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
        s = s & "   <text name=""p1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>" & vbLf
        s = s & "   <text name=""p2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        ' Register BEFORE opening the report so the compiler resolves PlugDouble and
        ' knows about the custom export target.
        gPlugDouble = New TRptUserFn(AddressOf PlugDoubleFn)
        Dim fnPtr As IntPtr = Marshal.GetFunctionPointerForDelegate(gPlugDouble)
        If Not LumasPdf.rptRegisterFunction(mEng, "PlugDouble", 1, 1, fnPtr, IntPtr.Zero) Then
            Console.WriteLine("rptRegisterFunction failed") : DumpRptError(mEng) : GoTo Cleanup
        End If
        gPlugExport = New TRptExporterFn(AddressOf PlugExportFn)
        Dim expPtr As IntPtr = Marshal.GetFunctionPointerForDelegate(gPlugExport)
        If Not LumasPdf.rptRegisterExporter(mEng, TARGET_CUSTOM, expPtr, IntPtr.Zero) Then
            Console.WriteLine("rptRegisterExporter failed") : DumpRptError(mEng) : GoTo Cleanup
        End If
        Console.WriteLine("registered custom function PlugDouble/1 (x -> x*2)")
        Console.WriteLine("registered custom export target " & TARGET_CUSTOM & " (no external plugin DLL)")

        Dim Dir_ As String = AppPath() & "\"
        Dim Lrpt As String = Dir_ & "13_plugin.lrpt"
        Dim OutPdf As String = Dir_ & "13_plugin.pdf"
        Dim OutTxt As String = Dir_ & "13_plugin.txt"
        Dim OutCustom As String = Dir_ & "13_custom.out"
        WriteTextFile(Lrpt, BuildXml())

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup
        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("export PDF failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("export TEXT failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, TARGET_CUSTOM, OutCustom) Then Console.WriteLine("export CUSTOM failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("wrote " & OutPdf)
        Console.WriteLine("wrote " & OutCustom & " (via custom exporter)")
        Console.WriteLine("OK")
CloseJob:
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
