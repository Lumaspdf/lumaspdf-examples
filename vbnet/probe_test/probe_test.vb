' probe_test -- VB.NET port of examples\Vb6\probe_test
Imports System
Imports LumasPdfSdk

Module modProbeTest
    Private errDel As TErrorProc

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine("ERR " & ErrCode & ": " & ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        Console.WriteLine("Create ok")
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        Console.WriteLine("CreateNewPDF('') = " & LumasPdf.pdfCreateNewPDFW(pdf, ""))
        Console.WriteLine("SetPageCoords = " & LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown))
        Console.WriteLine("Append = " & LumasPdf.pdfAppend(pdf))
        Console.WriteLine("SetFont = " & LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, True, TCodepage.cp1252))
        Console.WriteLine("WriteText = " & LumasPdf.pdfWriteTextW(pdf, 50, 50, "probe"))

        Dim tbl As IntPtr = LumasPdf.tblCreateTable(pdf, 3, 3, 500.0F, 100.0F)
        Console.WriteLine("Table created")
        Dim r As Integer = LumasPdf.tblAddRow(tbl, -1.0F)
        Console.WriteLine("AddRow = " & r)
        Console.WriteLine("SetCellText = " & LumasPdf.tblSetCellTextA(tbl, CUInt(r), 0, U(LumasPdfConsts.taLeft), TCellAlign.coTop, "cell", CUInt("cell".Length)))
        Console.WriteLine("DrawTable = " & LumasPdf.tblDrawTable(tbl, 50.0F, 80.0F, 700.0F))
        Console.WriteLine("HaveMore = " & LumasPdf.tblHaveMore(tbl))
        LumasPdf.tblDeleteTable(tbl)

        Console.WriteLine("EndPage = " & LumasPdf.pdfEndPage(pdf))
        Console.WriteLine("GetPageCount = " & LumasPdf.pdfGetPageCount(pdf))
        Console.WriteLine("HaveOpenDoc = " & LumasPdf.pdfHaveOpenDoc(pdf))
        Dim outFile As String = AppPath() & "\probe_out.pdf"
        Console.WriteLine("OpenOutputFile = " & LumasPdf.pdfOpenOutputFileW(pdf, outFile))
        Console.WriteLine("CloseFile = " & LumasPdf.pdfCloseFile(pdf))
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
