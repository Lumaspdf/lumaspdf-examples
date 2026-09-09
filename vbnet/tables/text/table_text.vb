' table_text -- VB.NET port of examples\Vb6\tables\text\table_text.bas
' Builds a 3x3 table demonstrating cell text alignment (left/center/right x
' top/center/bottom), draws it, then redraws it with a 90-degree cell
' orientation.
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modTableText
    Private ErrDelegate As TErrorProc
    ' NOTE: the VB6 original passes Len = -1 (the DynaPDF "null-terminated" sentinel).
    ' The LumasPdf engine's flat tblSetCellTextA (Lumas.Pdf.Api.pas) does NOT honour that
    ' sentinel: "if Len > 0 then SetLength(R, Len); Move(Text^, R[1], Len)" treats
    ' &HFFFFFFFF as a ~4GB length and faults with an AccessViolation. Only Len = 0 selects
    ' null-terminated. We therefore pass the real byte length here (equivalent output).
    Private TxtLen As UInteger

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr, tbl As IntPtr
        Dim outFile As String, txt As String
        Dim timeStart As Long
        Dim i As Integer, rowNum As Integer
        Dim err As TPDFError

        timeStart = Environment.TickCount

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))

        tbl = LumasPdf.tblCreateTable(pdf, 3, 3, 500.0, 100.0)
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
        LumasPdf.tblSetFontA(tbl, -1, -1, "Arial", LumasPdfConsts.fsRegular, True, TCodepage.cp1252)
        LumasPdf.tblSetFontA(tbl, -1, 1, "Arial", LumasPdfConsts.fsBold, True, TCodepage.cp1252)
        LumasPdf.tblSetGridWidth(tbl, 1.0, 1.0)

        txt = "The cell alignment can be set for text, images, and templates..."
        TxtLen = CUInt(System.Text.Encoding.ASCII.GetByteCount(txt))

        ' -1.0 means use the default row height as specified in the CreateTable() call.
        rowNum = LumasPdf.tblAddRow(tbl, -1.0)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 0, LumasPdfConsts.taLeft, TCellAlign.coTop, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 1, LumasPdfConsts.taCenter, TCellAlign.coTop, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 2, LumasPdfConsts.taRight, TCellAlign.coTop, txt, TxtLen)

        rowNum = LumasPdf.tblAddRow(tbl, -1.0)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 0, LumasPdfConsts.taLeft, TCellAlign.coCenter, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 1, LumasPdfConsts.taCenter, TCellAlign.coCenter, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 2, LumasPdfConsts.taRight, TCellAlign.coCenter, txt, TxtLen)

        rowNum = LumasPdf.tblAddRow(tbl, -1.0)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 0, LumasPdfConsts.taLeft, TCellAlign.coBottom, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 1, LumasPdfConsts.taCenter, TCellAlign.coBottom, txt, TxtLen)
        LumasPdf.tblSetCellTextA(tbl, CUInt(rowNum), 2, LumasPdfConsts.taRight, TCellAlign.coBottom, txt, TxtLen)

        ' Draw the table now
        LumasPdf.pdfAppend(pdf)
        LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Do While LumasPdf.tblHaveMore(tbl)
            LumasPdf.pdfEndPage(pdf)
            LumasPdf.pdfAppend(pdf)
            LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Loop
        LumasPdf.pdfEndPage(pdf)

        ' Let's change the cell orientation to see what happens...
        LumasPdf.tblSetCellOrientation(tbl, -1, -1, 90)
        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, 1, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "The same table but the cell orientation was changed to 90 degrees.")

        LumasPdf.tblDrawTable(tbl, 50.0, 65.0, 742.0)
        Do While LumasPdf.tblHaveMore(tbl)
            LumasPdf.pdfEndPage(pdf)
            LumasPdf.pdfAppend(pdf)
            LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 737.0)
        Loop
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.tblDeleteTable(tbl)                  ' frees the table and sets tbl to 0

        ' A table stores errors and warnings in the error log
        err = New TPDFError()
        err.StructSize = CUInt(Marshal.SizeOf(GetType(TPDFError)))
        For i = 0 To LumasPdf.pdfGetErrLogMessageCount(pdf) - 1
            LumasPdf.pdfGetErrLogMessage(pdf, CUInt(i), err)
            Console.WriteLine(Marshal.PtrToStringAnsi(err.Msg))
        Next i

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            ' We write the file into the application directory.
            outFile = AppPath() & "\out.pdf"
            If Not LumasPdf.pdfOpenOutputFileW(pdf, outFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("Processing time: " & (Environment.TickCount - timeStart) & " ms")
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
