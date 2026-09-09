' table_templates -- VB.NET port of examples\Vb6\tables\templates\table_templates.bas
' Imports every page of sample_multipage.pdf as a template and lays them out two
' per row in a table (tfScaleToRect), then draws the table across as many
' output pages as needed.
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modTableTemplates
    Private ErrDelegate As TErrorProc

    ' Table flag missing from the shared wrapper (from LumasPdf.pas):
    Private Const tfScaleToRect As Integer = &H8

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
        Dim pdf As IntPtr, tbl As IntPtr
        Dim outFile As String
        Dim timeStart As Long
        Dim i As Integer, pageCount As Integer, tmpl As Integer, rowNum As Integer
        Dim err As TPDFError

        timeStart = Environment.TickCount

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))

        LumasPdf.pdfSetImportFlags2(pdf, Fl(LumasPdfConsts.if2UseProxy))    ' Reduce the memory usage

        LumasPdf.pdfOpenImportFileW(pdf, AppPath() & "\..\..\..\..\sample_multipage.pdf", LumasPdfConsts.ptOpen, "")

        pageCount = LumasPdf.pdfGetInPageCount(pdf)
        If pageCount < 1 Then
            Console.WriteLine("Help file not found!")
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        tbl = LumasPdf.tblCreateTable(pdf, CUInt(pageCount \ 4 + 1), 2, 512.12, 0.0)
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpCellPadding, 5.0, 5.0, 5.0, 5.0)
        LumasPdf.tblSetGridWidth(tbl, 1.0, 1.0)
        LumasPdf.tblSetFlags(tbl, -1, -1, Fl(tfScaleToRect))

        LumasPdf.pdfSetPageFormat(pdf, CInt(TPageFormat.pfUS_Letter))

        rowNum = 0
        For i = 1 To pageCount
            tmpl = LumasPdf.pdfImportPage(pdf, CUInt(i))
            If (i And 1) <> 0 Then rowNum = LumasPdf.tblAddRow(tbl, 335.0)
            LumasPdf.tblSetCellTemplate(tbl, rowNum, (i - 1) And 1, True, TCellAlign.coCenter, TCellAlign.coCenter, CUInt(tmpl), 0.0, 0.0)
        Next i

        ' Draw the table now
        LumasPdf.pdfAppend(pdf)
        LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Do While LumasPdf.tblHaveMore(tbl)
            LumasPdf.pdfEndPage(pdf)
            LumasPdf.pdfAppend(pdf)
            LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Loop
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.tblDeleteTable(tbl)

        ' A table stores errors and warnings in the error log
        err = New TPDFError()
        err.StructSize = CUInt(Marshal.SizeOf(GetType(TPDFError)))
        For i = 0 To LumasPdf.pdfGetErrLogMessageCount(pdf) - 1
            LumasPdf.pdfGetErrLogMessage(pdf, CUInt(i), err)
            Console.WriteLine(Marshal.PtrToStringAnsi(err.Msg))
        Next i

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
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
