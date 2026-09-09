' 12_custom_function -- VB.NET port of examples\Vb6\reporting\12_custom_function.bas
' Registers a VB-implemented expression function GREET on the engine via
' rptRegisterFunction. The callback matches the engine C user-function ABI:
'   Function(User, Args:PRptCValue, NArgs, ResultV:PRptCValue) As Integer ' 0=ok
' TRptCValue = { Kind:Int32; B:Int32; I:Int64; F:Double; S:IntPtr }.
' Invoked from the report via {{expr: GREET('World')}}.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod12_custom_function
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    Private Const VK_INT As Integer = 2
    Private Const VK_STR As Integer = 5

    ' Callback ABI (stdcall). Args/ResultV are PRptCValue.
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Delegate Function TRptUserFn(ByVal User As IntPtr, ByVal Args As IntPtr, ByVal NArgs As Integer, ByVal ResultV As IntPtr) As Integer

    Private mPdf As IntPtr
    Private mEng As IntPtr
    ' Keep the delegate alive so the GC does not collect the thunk.
    Private gGreet As TRptUserFn
    ' Backing store for the string handed back to the engine (must outlive the return).
    Private gResult As IntPtr = IntPtr.Zero

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

    ' GREET(name) -> 'Hello, <name>!'
    Function GreetFn(ByVal User As IntPtr, ByVal Args As IntPtr, ByVal NArgs As Integer, ByVal ResultV As IntPtr) As Integer
        If (NArgs <> 1) OrElse (Args = IntPtr.Zero) OrElse (ResultV = IntPtr.Zero) Then Return -1
        Dim arg As TRptCValue = CType(Marshal.PtrToStructure(Args, GetType(TRptCValue)), TRptCValue)
        Dim argStr As String = ""
        If arg.Kind = VK_STR Then
            If arg.S <> IntPtr.Zero Then argStr = Marshal.PtrToStringAnsi(arg.S)
        ElseIf arg.Kind = VK_INT Then
            argStr = arg.I.ToString()
        Else
            Return -2
        End If

        ' Hand back a Kind=Str value. Keep the ANSI buffer alive past this return.
        If gResult <> IntPtr.Zero Then Marshal.FreeHGlobal(gResult)
        gResult = Marshal.StringToHGlobalAnsi("Hello, " & argStr & "!")
        Dim res As New TRptCValue()
        res.Kind = VK_STR
        res.S = gResult
        Marshal.StructureToPtr(res, ResultV, False)
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
        s = s & "<report name=""CustomFn"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
        s = s & "   <text name=""g1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">{{expr: GREET('World') }}</text>" & vbLf
        s = s & "   <text name=""g2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">{{expr: GREET('LumasReport') }}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Main()
        If Not BootEngine() Then Return

        ' Register BEFORE opening/rendering so the compiler resolves GREET.
        gGreet = New TRptUserFn(AddressOf GreetFn)
        Dim fnPtr As IntPtr = Marshal.GetFunctionPointerForDelegate(gGreet)
        If Not LumasPdf.rptRegisterFunction(mEng, "GREET", 1, 1, fnPtr, IntPtr.Zero) Then
            Console.WriteLine("rptRegisterFunction failed") : DumpRptError(mEng) : GoTo Cleanup
        End If
        Console.WriteLine("registered custom function GREET/1")

        Dim Dir_ As String = AppPath() & "\"
        Dim Lrpt As String = Dir_ & "12_custom_function.lrpt"
        Dim OutPdf As String = Dir_ & "12_custom_function.pdf"
        Dim OutTxt As String = Dir_ & "12_custom_function.txt"
        WriteTextFile(Lrpt, BuildXml())

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup
        If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("export PDF failed") : DumpRptError(mEng) : GoTo CloseJob
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("export TEXT failed") : DumpRptError(mEng) : GoTo CloseJob
        Console.WriteLine("wrote " & OutPdf)
        Console.WriteLine("OK")
CloseJob:
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
        If gResult <> IntPtr.Zero Then Marshal.FreeHGlobal(gResult)
    End Sub
End Module
