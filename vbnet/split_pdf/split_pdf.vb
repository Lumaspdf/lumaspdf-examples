' split_pdf -- VB.NET port of examples\Vb6\split_pdf\split_pdf.bas
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modSplitPdf
    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    ' ParamArray is UInteger, not Integer: the generated bindings type the
    ' flag constants as UInteger (they have the high bit set, e.g.
    ' ifImportAsPage = &H80000000UI), and passing one to an Integer
    ' parameter is BC30439 "Constant expression not representable in
    ' type 'Integer'". The arithmetic below is unchanged, so the value
    ' handed to the engine -- and therefore the output -- is identical.
    Function Fl(ParamArray vals() As UInteger) As UInteger
        Dim r As Long = 0
        For Each v In vals : r = r Or (CLng(v) And &HFFFFFFFFL) : Next
        Return CUInt(r And &HFFFFFFFFL)
    End Function

    Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfSetImportFlags(pdf, Fl(LumasPdfConsts.ifImportAll, LumasPdfConsts.ifImportAsPage))
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy)

        Dim inFile As String = AppPath() & "\license.pdf"
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfSetUseGlobalImpFiles(pdf, 1)

        Dim outDir As String = AppPath() & "\out"
        If Not Directory.Exists(outDir) Then Directory.CreateDirectory(outDir)

        Dim count As Integer = LumasPdf.pdfGetInPageCount(pdf)
        For i As Integer = 1 To count
            Dim outPath As String = outDir & "\page" & i.ToString("0000") & ".pdf"
            LumasPdf.pdfCreateNewPDFW(pdf, outPath)
            LumasPdf.pdfAppend(pdf)
            LumasPdf.pdfImportPageEx(pdf, CUInt(i), 1.0, 1.0)
            LumasPdf.pdfEndPage(pdf)
            LumasPdf.pdfCloseFile(pdf)
        Next

        LumasPdf.pdfSetUseGlobalImpFiles(pdf, 0)
        Console.WriteLine("Pages written to: " & outDir)
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
