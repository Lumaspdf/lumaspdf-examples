' edit_text -- VB.NET port of examples\Vb6\edit_text
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modEditText
    Private ErrDel As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    ' UInteger, not Integer: the generated bindings type the flag constants as
    ' UInteger (high bit set, e.g. ifImportAsPage = &H80000000UI), and passing
    ' one to an Integer parameter is BC30439. The value is unchanged, so the
    ' output is unchanged.
    Function UFlag(ByVal v As UInteger) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        ErrDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDel)
        LumasPdf.pdfSetImportFlags(pdf, UFlag(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))

        Dim inFile As String = AppPath() & "\dynapdf_help.pdf"
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        Dim ctx As IntPtr = LumasPdf.psrCreateParserContext(pdf, CUInt(LumasPdfConsts.ofDefault), IntPtr.Zero)
        Dim searchText As String = "PDF"
        Dim replaceText As String = "XDF"

        Dim content As TContent
        Dim sel As TTextSelection
        Dim selBuf As IntPtr = Marshal.AllocHGlobal(Marshal.SizeOf(GetType(TTextSelection)))
        Try
            For i As Integer = 1 To LumasPdf.pdfGetPageCount(pdf)
                If LumasPdf.psrParsePage(pdf, ctx, IntPtr.Zero, IntPtr.Zero, CUInt(i), LumasPdfConsts.cpfEnableTextSelection, IntPtr.Zero, content) Then
                    Dim lastPtr As IntPtr = IntPtr.Zero
                    Do While LumasPdf.psrFindText(pdf, ctx, IntPtr.Zero, CUInt(LumasPdfConsts.stDefault), lastPtr, searchText, CUInt(searchText.Length), sel)
                        LumasPdf.psrReplaceSelText(pdf, ctx, TReplaceTextFlags.rtfDefault, sel, replaceText, CUInt(replaceText.Length))
                        Marshal.StructureToPtr(sel, selBuf, False)
                        lastPtr = selBuf
                    Loop
                    LumasPdf.psrWriteToPage(pdf, ctx, CUInt(LumasPdfConsts.ofDefault), IntPtr.Zero)
                End If
            Next
        Finally
            Marshal.FreeHGlobal(selBuf)
        End Try
        LumasPdf.psrDeleteParserContext(ctx)

        Dim outFile As String = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        If LumasPdf.pdfCloseFile(pdf) <> 0 Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
