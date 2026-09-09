' edit_page -- VB.NET port of examples\Vb6\edit_page
Imports System
Imports LumasPdfSdk

Module modEditPage
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

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetImportFlags(pdf, UFlag(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))

        Dim inFile As String = AppPath() & "\rotated_270.pdf"
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))
        LumasPdf.pdfSetUseVisibleCoords(pdf, True)

        LumasPdf.pdfEditPage(pdf, 1)
        Dim orientation As Integer = LumasPdf.pdfGetOrientation(pdf)
        If orientation <> 0 Then
            LumasPdf.pdfSetOrientationEx(pdf, orientation)
        End If
        LumasPdf.pdfSetLeading(pdf, 14.0)
        Dim f As Integer = LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, False, TCodepage.cp1252)
        LumasPdf.pdfSetListFont(pdf, CUInt(f))

        ' pdfWriteFTextExW is the Unicode export, so the bullet must be U+2022
        ' (cp1252 char 144 would be U+0090 in Unicode).
        Dim B As String = ChrW(&H2022)
        Dim CR As String = ChrW(13)
        Dim s As String = "It is not difficult to edit an imported page but two things must be considered:" & CR & CR & "\LI[20," & B & "]\LD[16]The page's " _
          & "orientation.\EL#\LI[20," & B & "]\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#" & CR & "\LD[12]" _
          & "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. DynaPDF moves the zero point then automatically " _
          & "into the visible area of the page." & CR & CR _
          & "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present." & CR & CR _
          & "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated " _
          & "into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file." & CR & CR _
          & "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was " _
          & "not rotated. If this produces a wrong result then don't call SetOrientationEx()." & CR & CR _
          & "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() " _
          & "and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents."

        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 200.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, LumasPdfConsts.taJustify, s)
        LumasPdf.pdfEndPage(pdf)

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
