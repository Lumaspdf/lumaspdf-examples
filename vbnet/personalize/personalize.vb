' personalize -- VB.NET port of examples\Vb6\personalize
Imports System
Imports LumasPdfSdk

Module modPersonalize
    Private errDel As TErrorProc

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return -1
    End Function

    Sub Main()
        errDel = New TErrorProc(AddressOf ErrProc)
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetViewerPreferences(pdf, LumasPdfConsts.vpDisplayDocTitle, LumasPdfConsts.avNone)
        LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))
        If LumasPdf.pdfOpenImportFileW(pdf, AppPath() & "\taxform.pdf", LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

        LumasPdf.pdfEditPage(pdf, 1)
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 14.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 72.5, 748.5, "X")
        LumasPdf.pdfWriteTextW(pdf, 74.0, 701.0, "Musterstadt")
        LumasPdf.pdfWriteTextW(pdf, 74.0, 677.0, "252/1062/3323")
        LumasPdf.pdfBeginContinueText(pdf, 74.0, 628.0)
        LumasPdf.pdfSetLeading(pdf, 24.0)
        LumasPdf.pdfSetCharacterSpacing(pdf, 5.8)
        LumasPdf.pdfAddContinueTextW(pdf, "Mustermann")
        LumasPdf.pdfAddContinueTextW(pdf, "Hermann")
        LumasPdf.pdfAddContinueTextW(pdf, "22021963keineKaufmann")
        ' ChrW, not Chr. Chr resolves its argument through the CURRENT
        ' ANSI codepage, and .NET 8 ships no CP1252 provider by default, so
        ' it throws "No data is available for encoding 1252" the moment this
        ' example is built against the NuGet package instead of .NET
        ' Framework 4.8. ChrW takes a Unicode code point directly. For every
        ' Chr(n) in this tree the two agree exactly: none used 128..159, the
        ' only range where CP1252 and Unicode differ (223 = U+00DF, "ss").
        LumasPdf.pdfAddContinueTextW(pdf, "Musterstra" & ChrW(223) & "e 145")
        LumasPdf.pdfAddContinueTextW(pdf, "12345Musterstadt")
        LumasPdf.pdfSetCharacterSpacing(pdf, 0.0)
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 10.0, False, TCodepage.cp1252)
        LumasPdf.pdfSetLeading(pdf, 48.0)
        LumasPdf.pdfAddContinueTextW(pdf, "04.05.1994")
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 14.0, False, TCodepage.cp1252)
        LumasPdf.pdfSetCharacterSpacing(pdf, 5.8)
        LumasPdf.pdfAddContinueTextW(pdf, "Sabine")
        LumasPdf.pdfSetLeading(pdf, 47.5)
        LumasPdf.pdfAddContinueTextW(pdf, "18121966 ev  Hausfrau")
        LumasPdf.pdfEndContinueText(pdf)
        LumasPdf.pdfWriteTextW(pdf, 72.5, 365.0, "X")
        LumasPdf.pdfWriteTextW(pdf, 396.0, 365.0, "X")
        LumasPdf.pdfBeginContinueText(pdf, 74.0, 316.0)
        LumasPdf.pdfSetLeading(pdf, 24.0)
        LumasPdf.pdfAddContinueTextW(pdf, "2346256780     76834560")
        LumasPdf.pdfAddContinueTextW(pdf, "Sparkasse Musterstadt")
        LumasPdf.pdfEndContinueText(pdf)
        LumasPdf.pdfWriteTextW(pdf, 72.5, 269.0, "X")
        LumasPdf.pdfSetCharacterSpacing(pdf, 0.0)
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsNone, 10.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 53.0, 48.0, Now().ToString())
        LumasPdf.pdfSetFillColor(pdf, U(&HFF Or (&H66 << 8) Or (&H66 << 16)))
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsBold, 22.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 340.0, 70.0, "www.lumaspdf.com")
        LumasPdf.pdfSetLineWidth(pdf, 0.0)
        LumasPdf.pdfSetLinkHighlightMode(pdf, CInt(THighlightMode.hmPush))
        LumasPdf.pdfSetAnnotFlags(pdf, U(LumasPdfConsts.afReadOnly))
        LumasPdf.pdfWebLinkW(pdf, 340.0, 64.0, 204.0, 22.0, "https://www.lumaspdf.com")
        LumasPdf.pdfEndPage(pdf)

        Dim outFile As String = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, Nothing)
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        End If
        If LumasPdf.pdfCloseFile(pdf) <> 0 Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
