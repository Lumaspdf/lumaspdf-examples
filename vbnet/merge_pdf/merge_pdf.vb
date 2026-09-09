' merge_pdf -- VB.NET port of examples\Vb6\merge_pdf
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modMergePdf
    Private errDel As TErrorProc

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 14.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, LumasPdfConsts.taJustify, _
            "The following pages were imported from different PDF files. LumasPDF adjusts the destinations of link annotations and bookmarks so that " & _
            "all destinations refer to the new page numbers after import." & ChrW(13) & ChrW(13) & _
            "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number " & _
            "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().")
        LumasPdf.pdfEndPage(pdf)

        Dim first As Boolean = True
        Dim destPage As Integer = 1
        Dim haveXFA As Boolean = False
        Dim isCollection As Boolean = False

        Dim files(1) As String
        files(0) = AppPath() & "\license.pdf"
        files(1) = AppPath() & "\sample_multipage.pdf"

        For i As Integer = 0 To 1
            If LumasPdf.pdfOpenImportFileW(pdf, files(i), LumasPdfConsts.ptOpen, "") < 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If first Then
                first = False
                haveXFA = (LumasPdf.pdfGetInIsXFAForm(pdf) <> 0)
                isCollection = (LumasPdf.pdfGetInIsCollection(pdf) <> 0)
                destPage = LumasPdf.pdfImportPDFFile(pdf, CUInt(destPage + 1), 1.0, 1.0)
                If destPage < 0 Then Exit For
            Else
                If isCollection Then
                    If LumasPdf.pdfGetInIsCollection(pdf) <> 0 Then
                        LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifEmbeddedFiles))
                        If Not LumasPdf.pdfImportCatalogObjects(pdf) Then Exit For
                    Else
                        LumasPdf.pdfCloseImportFile(pdf)
                        LumasPdf.pdfAttachFileW(pdf, files(i), Path.GetFileName(files(i)), True)
                    End If
                Else
                    If (LumasPdf.pdfGetInIsCollection(pdf) <> 0) OrElse _
                       (((LumasPdf.pdfGetInIsXFAForm(pdf) <> 0) OrElse (LumasPdf.pdfGetInFieldCount(pdf) > 0)) AndAlso _
                        ((LumasPdf.pdfGetFieldCount(pdf) > 0) OrElse haveXFA)) Then Exit For
                    LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))
                    LumasPdf.pdfSetImportFlags2(pdf, U(LumasPdfConsts.if2UseProxy))
                    destPage = LumasPdf.pdfImportPDFFile(pdf, CUInt(destPage + 1), 1.0, 1.0)
                    If destPage < 0 Then Exit For
                End If
            End If
            LumasPdf.pdfCloseImportFile(pdf)
        Next

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = AppPath() & "\out.pdf"
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
