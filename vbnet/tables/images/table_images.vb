' table_images -- VB.NET port of examples\Vb6\tables\images\table_images.bas
' Lays out every JPEG in test_files\images into a 4-column table (one image per
' cell, native image color space), draws it, then redraws with tfScaleToRect.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modTableImages
    Private ErrDelegate As TErrorProc

    ' Table flags missing from the shared wrapper (from LumasPdf.pas):
    Private Const tfScaleToRect As Integer = &H8
    Private Const tfUseImageCS As Integer = &H10

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
        Dim outFile As String, imgDir As String
        Dim timeStart As Long, fullSize As Long
        Dim i As Integer, rowNum As Integer
        Dim err As TPDFError

        timeStart = Environment.TickCount

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))
        LumasPdf.pdfSetResolution(pdf, 300)

        tbl = LumasPdf.tblCreateTable(pdf, 100, 4, 500.0, 125.0)
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpCellPadding, 5.0, 5.0, 5.0, 5.0)
        LumasPdf.tblSetGridWidth(tbl, 1.0, 1.0)
        LumasPdf.tblSetFlags(tbl, -1, -1, Fl(tfUseImageCS))

        ' Three levels up, not four. The VB6 original's "\..\..\..\..\" was
        ' right for ITS tree depth; from examples\vbnet\tables\images\ four
        ' levels lands on E:\LUMASPDFSDK\test_files\images, which does not
        ' exist, so Directory.Exists was false, the file list came back empty
        ' and the example silently produced a 2-page 18 KB PDF instead of the
        ' 4-page 1.3 MB one (it prints "Test images not found!" and carries on).
        imgDir = AppPath() & "\..\..\..\test_files\images\"
        Dim files() As String
        If Directory.Exists(imgDir) Then
            files = Directory.GetFiles(imgDir, "*.jpg")
        Else
            files = New String() {}
        End If
        If files.Length = 0 Then
            Console.WriteLine("Test images not found!")
            LumasPdf.tblDeleteTable(tbl)
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        i = 1
        fullSize = New FileInfo(files(0)).Length
        rowNum = LumasPdf.tblAddRow(tbl, 125.0)
        LumasPdf.tblSetCellImageA(tbl, rowNum, 0, True, TCellAlign.coCenter, TCellAlign.coCenter, 0.0, 0.0, files(0), 1)

        Dim idx As Integer = 1
        Do While idx < files.Length
            Dim fn As String = files(idx)
            If i = 4 Then
                rowNum = LumasPdf.tblAddRow(tbl, 100.0)
                i = 0
            End If
            fullSize = fullSize + New FileInfo(fn).Length
            LumasPdf.tblSetCellImageA(tbl, rowNum, i, True, TCellAlign.coCenter, TCellAlign.coCenter, 0.0, 0.0, fn, 1)
            i = i + 1
            idx = idx + 1
        Loop

        LumasPdf.pdfAppend(pdf)

        LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Do While LumasPdf.tblHaveMore(tbl)
            LumasPdf.pdfEndPage(pdf)
            If fullSize > 104857600 Then LumasPdf.pdfFlushPages(pdf, Fl(LumasPdfConsts.fpfDefault))
            LumasPdf.pdfAppend(pdf)
            LumasPdf.tblDrawTable(tbl, 50.0, 50.0, 742.0)
        Loop
        LumasPdf.pdfEndPage(pdf)

        ' We draw the same table again but this time with the flag tfScaleToRect
        LumasPdf.tblSetFlags(tbl, -1, -1, Fl(tfScaleToRect, tfUseImageCS))
        LumasPdf.pdfAppend(pdf)

        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, 1, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "The same table but the flag tfScaleToRect was set.")

        LumasPdf.tblDrawTable(tbl, 50.0, 65.0, 742.0)
        Do While LumasPdf.tblHaveMore(tbl)
            LumasPdf.pdfEndPage(pdf)
            If fullSize > 104857600 Then LumasPdf.pdfFlushPages(pdf, Fl(LumasPdfConsts.fpfDefault))
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
