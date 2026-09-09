' 08_custom_provider -- VB.NET port of examples\Vb6\reporting\08_custom_provider.bas
'  VB6 used AddressOf into a TRptProviderVTable of raw function pointers; here we
'  use managed delegates marshalled to function pointers (kept alive in module fields).
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod08_custom_provider
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    Private mPdf As IntPtr
    Private mEng As IntPtr

    ' value kinds
    Private Const vkNull As Integer = 0
    Private Const vkBool As Integer = 1
    Private Const vkInt As Integer = 2
    Private Const vkFloat As Integer = 3
    Private Const vkDate As Integer = 4
    Private Const vkStr As Integer = 5

    ' delegate types matching the C provider vtable signatures (stdcall)
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Private Delegate Function TOpen(ByVal U As IntPtr, ByVal Conn As IntPtr, ByVal Query As IntPtr, ByVal Params As IntPtr, ByVal NParams As Integer, ByRef Cursor As IntPtr) As Integer
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Private Delegate Function TGetSchema(ByVal Cursor As IntPtr, ByVal Fields As IntPtr, ByVal MaxFields As Integer) As Integer
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Private Delegate Function TFetch(ByVal Cursor As IntPtr) As Integer
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Private Delegate Function TGetVal(ByVal Cursor As IntPtr, ByVal Field As Integer, ByVal V As IntPtr) As Integer
    <UnmanagedFunctionPointer(CallingConvention.StdCall)>
    Private Delegate Sub TClose(ByVal Cursor As IntPtr)

    ' kept-alive delegate instances
    Private dOpen As TOpen
    Private dGetSchema As TGetSchema
    Private dFetch As TFetch
    Private dGetVal As TGetVal
    Private dClose As TClose

    ' in-memory table
    Private mRowId() As Long = {1, 2, 3, 4}
    Private mPrice() As Double = {12.5, 9.99, 0, 47.75}
    Private mActive() As Integer = {1, 0, 1, 1}
    Private mHasNote() As Boolean = {True, True, False, True}
    Private mName() As String = {"Alpha", "Beta", "Gamma", "Delta"}
    Private mNote() As String = {"first", "second", "", "fourth"}
    Private mNamePtr(3) As IntPtr
    Private mNotePtr(3) As IntPtr

    Private mFieldName() As String = {"Id", "Price", "Name", "Active", "Note"}
    Private mFieldKind() As Integer = {vkInt, vkFloat, vkStr, vkBool, vkStr}

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

    ' ---- provider callbacks ----
    Function MyOpen(ByVal U As IntPtr, ByVal Conn As IntPtr, ByVal Query As IntPtr, ByVal Params As IntPtr, ByVal NParams As Integer, ByRef Cursor As IntPtr) As Integer
        Dim p As IntPtr = Marshal.AllocHGlobal(4)
        Marshal.WriteInt32(p, -1)   ' row index starts before first row
        Cursor = p
        Return 0
    End Function

    Function MyGetSchema(ByVal Cursor As IntPtr, ByVal Fields As IntPtr, ByVal MaxFields As Integer) As Integer
        Dim n As Integer = 5
        If n > MaxFields Then n = MaxFields
        For i As Integer = 0 To n - 1
            Dim fd As New TRptCFieldDef()
            fd.Name = mFieldName(i)
            fd.Kind = mFieldKind(i)
            Dim dst As New IntPtr(Fields.ToInt64() + CLng(i) * 68)
            Marshal.StructureToPtr(fd, dst, False)
        Next
        Return n
    End Function

    Function MyFetch(ByVal Cursor As IntPtr) As Integer
        Dim r As Integer = Marshal.ReadInt32(Cursor)
        r += 1
        Marshal.WriteInt32(Cursor, r)
        If r <= 3 Then Return 1 Else Return 0
    End Function

    Function MyGetVal(ByVal Cursor As IntPtr, ByVal Field As Integer, ByVal V As IntPtr) As Integer
        Dim r As Integer = Marshal.ReadInt32(Cursor)
        Dim cv As New TRptCValue()
        cv.Kind = vkNull : cv.B = 0 : cv.I = 0 : cv.F = 0 : cv.S = IntPtr.Zero
        Select Case Field
            Case 0
                cv.Kind = vkInt
                cv.I = mRowId(r)
            Case 1
                cv.Kind = vkFloat
                cv.F = mPrice(r)
            Case 2
                cv.Kind = vkStr
                cv.S = mNamePtr(r)
            Case 3
                cv.Kind = vkBool
                cv.B = mActive(r)
            Case 4
                If Not mHasNote(r) Then
                    cv.Kind = vkNull
                Else
                    cv.Kind = vkStr
                    cv.S = mNotePtr(r)
                End If
            Case Else
                cv.Kind = vkNull
        End Select
        Marshal.StructureToPtr(cv, V, False)
        Return 0
    End Function

    Sub MyClose(ByVal Cursor As IntPtr)
        If Cursor <> IntPtr.Zero Then Marshal.FreeHGlobal(Cursor)
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        ' allocate persistent ANSI strings for the string columns
        For i As Integer = 0 To 3
            mNamePtr(i) = Marshal.StringToHGlobalAnsi(mName(i))
            If mHasNote(i) Then mNotePtr(i) = Marshal.StringToHGlobalAnsi(mNote(i)) Else mNotePtr(i) = IntPtr.Zero
        Next

        dOpen = New TOpen(AddressOf MyOpen)
        dGetSchema = New TGetSchema(AddressOf MyGetSchema)
        dFetch = New TFetch(AddressOf MyFetch)
        dGetVal = New TGetVal(AddressOf MyGetVal)
        dClose = New TClose(AddressOf MyClose)

        Dim vt As New TRptProviderVTable()
        vt.Open = Marshal.GetFunctionPointerForDelegate(dOpen)
        vt.GetSchema = Marshal.GetFunctionPointerForDelegate(dGetSchema)
        vt.Fetch = Marshal.GetFunctionPointerForDelegate(dFetch)
        vt.GetVal = Marshal.GetFunctionPointerForDelegate(dGetVal)
        vt.RewindC = IntPtr.Zero
        vt.RowCount = IntPtr.Zero
        vt.Exec = IntPtr.Zero
        vt.Tx = IntPtr.Zero
        vt.CloseC = Marshal.GetFunctionPointerForDelegate(dClose)

        Dim vtp As IntPtr = Marshal.AllocHGlobal(Marshal.SizeOf(GetType(TRptProviderVTable)))
        Marshal.StructureToPtr(vt, vtp, False)

        If Not LumasPdf.rptRegisterProvider(mEng, "mydata", vtp, IntPtr.Zero) Then
            Console.WriteLine("register provider failed")
            DumpRptError(mEng)
            GoTo Cleanup
        End If

        Dim Lrpt As String = AppPath() & "\08_custom.lrpt"
        Dim OutPdf As String = AppPath() & "\08_custom.pdf"
        Dim OutTxt As String = AppPath() & "\08_custom.txt"
        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""CustomProvider"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <datasources><datasource alias=""d"" provider=""mydata"" conn="""" query=""""/></datasources>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""12"">" & vbLf
        Xml = Xml & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"" wordWrap=""0"">Custom Provider - typed rows</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""pageheader"" name=""ph"" height=""7"">" & vbLf
        Xml = Xml & "   <text name=""h1"" x=""0""   y=""0"" w=""20"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Id</text>" & vbLf
        Xml = Xml & "   <text name=""h2"" x=""22""  y=""0"" w=""40"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Name</text>" & vbLf
        Xml = Xml & "   <text name=""h3"" x=""64""  y=""0"" w=""30"" h=""5"" fontSize=""9"" bold=""1"" hAlign=""right"" wordWrap=""0"">Price</text>" & vbLf
        Xml = Xml & "   <text name=""h4"" x=""98""  y=""0"" w=""24"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Active</text>" & vbLf
        Xml = Xml & "   <text name=""h5"" x=""126"" y=""0"" w=""50"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Note</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
        Xml = Xml & "   <text name=""c1"" x=""0""   y=""0"" w=""20"" h=""5"" fontSize=""9"" wordWrap=""0"">{{Id}}</text>" & vbLf
        Xml = Xml & "   <text name=""c2"" x=""22""  y=""0"" w=""40"" h=""5"" fontSize=""9"" wordWrap=""0"">{{Name}}</text>" & vbLf
        Xml = Xml & "   <text name=""c3"" x=""64""  y=""0"" w=""30"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Price) }}</text>" & vbLf
        Xml = Xml & "   <text name=""c4"" x=""98""  y=""0"" w=""24"" h=""5"" fontSize=""9"" wordWrap=""0"">{{expr: CSTR(Active) }}</text>" & vbLf
        Xml = Xml & "   <text name=""c5"" x=""126"" y=""0"" w=""50"" h=""5"" fontSize=""9"" wordWrap=""0"">{{expr: IFNULL(Note, '(none)') }}</text>" & vbLf
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
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s) from the custom provider")
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt)
        Console.WriteLine("wrote " & OutPdf & "  +  " & OutTxt)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module
