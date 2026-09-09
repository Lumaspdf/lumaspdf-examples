' collections2 -- VB.NET port of examples\Vb6\collections2\collections2.bas
Imports System
Imports System.IO
Imports LumasPdfSdk

Module Collections2
    Private errDel As TErrorProc

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim ef As Integer, outFile As String = ""
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)

        LumasPdf.pdfSetImportFlags(pdf, &H0FFFFFFEUI Or &H80000000UI)
        If LumasPdf.pdfOpenImportFileW(pdf, "../../test_files/collection_en.pdf", LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Console.WriteLine("Input file ""../../test_files/collection_en.pdf"" not found!")
            Return
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)
        LumasPdf.pdfCreateCollection(pdf, TColView.civTile)

        ' We add a user defined field Index to the list so that we can sort it in every order we want.
        ef = LumasPdf.pdfCreateCollectionFieldW(pdf, TColColumnType.cisCustomNumber, 0, "File index", "Index", False, True)
        LumasPdf.pdfSetColSortField(pdf, CUInt(ef), True)

        LumasPdf.pdfCreateCollectionFieldW(pdf, TColColumnType.cisFileName, 1, "File name", "", True, True)
        LumasPdf.pdfCreateCollectionFieldW(pdf, TColColumnType.cisSize, 2, "File size", "", True, False)
        LumasPdf.pdfCreateCollectionFieldW(pdf, TColColumnType.cisModDate, 3, "Modification date", "", True, False)

        ef = LumasPdf.pdfAttachFileW(pdf, "../../test_files/taxform.pdf", "A PDF file...", True)
        LumasPdf.pdfSetColDefFile(pdf, CUInt(ef))
        LumasPdf.pdfCreateColItemNumber(pdf, CUInt(ef), "Index", 0.0, "")

        ef = LumasPdf.pdfAttachFileW(pdf, "../../test_files/fulltest.emf", "An EMF file...", True)
        LumasPdf.pdfCreateColItemNumber(pdf, CUInt(ef), "Index", 1.0, "")

        ef = LumasPdf.pdfAttachFileW(pdf, "../../test_files/sample.txt", "A text file...", True)
        LumasPdf.pdfCreateColItemNumber(pdf, CUInt(ef), "Index", 2.0, "")

        LumasPdf.pdfCheckCollection(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        LumasPdf.pdfCloseFile(pdf)
        Console.WriteLine("PDF Collection """ & outFile & """ successfully created!")
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
