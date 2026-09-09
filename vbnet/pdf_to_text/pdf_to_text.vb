' pdf_to_text -- VB.NET port of examples\Vb6\pdf_to_text
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modPdfToText
    Private errDel As TErrorProc
    Private Const emNoFuncNames As Integer = &H10000000

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        LumasPdf.pdfSetErrorMode(pdf, emNoFuncNames)
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfSetCMapDirW(pdf, AppPath() & "\CMap", U(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))

        If LumasPdf.pdfCreateNewPDFW(pdf, "") = 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifContentOnly Or LumasPdfConsts.ifImportAsPage))
        Dim inFile As String = AppPath() & "\in.pdf"
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfFreePDF(pdf)
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        If LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0 Then
            LumasPdf.pdfFreePDF(pdf)
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfCloseImportFile(pdf)

        Dim outFile As String = AppPath() & "\out.txt"
        Using sw As New StreamWriter(outFile, False)
            Dim count As Integer = LumasPdf.pdfGetPageCount(pdf)
            For i As Integer = 1 To count
                sw.WriteLine("----- Page " & i & " -----")
                LumasPdf.pdfEditPage(pdf, i)
                sw.WriteLine(Marshal.PtrToStringAnsi(LumasPdf.pdfSplitPageTextW(pdf, CUInt(i))))
                LumasPdf.pdfEndPage(pdf)
            Next
        End Using

        LumasPdf.pdfFreePDF(pdf)
        Console.WriteLine("Text written to: " & outFile)
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
