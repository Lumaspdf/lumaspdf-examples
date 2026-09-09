' text_formatting -- VB.NET port of examples\Vb6\text_formatting\text_formatting.bas
' Lays out sample.txt into N columns using a page-break callback and writes out.pdf.
Imports System
Imports System.IO
Imports System.Text
Imports LumasPdfSdk

Module modTextFormatting
    ' Holds the formatting options.
    Private Structure TOutRect
        Public PosX As Double      ' Original x-coordinate of first output rectangle
        Public PosY As Double      ' Original y-coordinate of first output rectangle
        Public Width_ As Double    ' Original width of first output rectangle
        Public Height_ As Double   ' Original height of first output rectangle
        Public Distance As Double  ' Space between columns
        Public Column As Integer   ' Current column
        Public ColCount As Integer ' Number of columns
    End Structure

    Private gRect As TOutRect
    Private gPDF As IntPtr
    Private ErrDelegate As TErrorProc
    Private BreakDelegate As TOnPageBreakProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return -1                       ' we break processing if an error occurred.
    End Function

    ' Page-break callback. Places the next column or starts a new page.
    Public Function OnPageBreakProc(ByVal Data As IntPtr, ByVal LastPosX As Double, ByVal LastPosY As Double, ByVal PageBreak As Boolean) As Integer
        Dim x As Double
        LumasPdf.pdfSetPageCoords(gPDF, TPageCoord.pcTopDown)   ' we use top down coordinates
        gRect.Column += 1
        ' PageBreak is nonzero if the string contains a page break tag.
        If (Not PageBreak) AndAlso (gRect.Column < gRect.ColCount) Then
            ' Calculate the x-coordinate of the column
            x = gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance)
            ' change the output rectangle, do not close the page!
            LumasPdf.pdfSetTextRect(gPDF, x, gRect.PosY, gRect.Width_, gRect.Height_)
            Return 0            ' we do not change the alignment
        Else
            ' the page is full, close the current one and append a new page
            LumasPdf.pdfEndPage(gPDF)
            LumasPdf.pdfAppend(gPDF)
            LumasPdf.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_)
            gRect.Column = 0
            Return 0
        End If
    End Function

    Private Function LoadTextFile(ByVal fileName As String) As String
        Try
            Dim b() As Byte = File.ReadAllBytes(fileName)
            ' sample.txt is an ANSI text file
            Return Encoding.Default.GetString(b)
        Catch
            Return ""
        End Try
    End Function

    Sub Main()
        Dim outFile As String, fText As String

        ' The text is stored in a file. Original: ..\..\test_files\sample.txt
        fText = LoadTextFile(AppPath() & "\sample.txt")

        gPDF = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diCreator, "C++ test app")
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diSubject, "Multi-column text")
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diTitle, "Multi-column text")
        LumasPdf.pdfSetPageCoords(gPDF, TPageCoord.pcTopDown)

        If Not LumasPdf.pdfCreateNewPDFW(gPDF, "") Then     ' The output file is opened later
            LumasPdf.pdfDeletePDF(gPDF)
            Return
        End If

        ' Initialize the output rectangle, number of columns and so on.
        gRect.ColCount = 3                 ' Form combo default was 3 columns
        gRect.Column = 0
        gRect.Distance = 10.0
        gRect.PosX = 50.0
        gRect.PosY = 50.0
        gRect.Height_ = LumasPdf.pdfGetPageHeight(gPDF) - 100.0
        gRect.Width_ = (LumasPdf.pdfGetPageWidth(gPDF) - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount

        ' Pass the callback function.
        BreakDelegate = New TOnPageBreakProc(AddressOf OnPageBreakProc)
        LumasPdf.pdfSetOnPageBreakProc(gPDF, IntPtr.Zero, BreakDelegate)
        LumasPdf.pdfAppend(gPDF)                     ' Append a new page
        LumasPdf.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_)
        LumasPdf.pdfSetFontW(gPDF, "Arial", LumasPdfConsts.fsNone, 9.0, 1, TCodepage.cp1252)   ' A font is always required
        ' NOTE: this call must stay on the *Ansi* entry point. The Delphi original declares
        ' `fText: AnsiString` (Unit1.pas), so `WriteFText(taJustify, fText)` binds to the
        ' AnsiString overload -> pdfWriteFTextA. sample.txt is a cp1252 file and the font was
        ' created with cp1252, so the Ansi path is the faithful one; pdfWriteFTextW takes a
        ' different line-breaking/justification path in the engine and repaginates the document.
        LumasPdf.pdfWriteFTextA(gPDF, CUInt(LumasPdfConsts.taJustify), fText)              ' Now print the text

        LumasPdf.pdfEndPage(gPDF)                    ' Close the last page
        ' No fatal error occurred?
        outFile = ""
        If LumasPdf.pdfHaveOpenDoc(gPDF) Then
            LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, Nothing)
            outFile = AppPath() & "\out.pdf"
            If Not LumasPdf.pdfOpenOutputFileW(gPDF, outFile) Then
                LumasPdf.pdfDeletePDF(gPDF)
                Return
            End If
            LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, ErrDelegate)
        End If
        If LumasPdf.pdfCloseFile(gPDF) Then
            Console.WriteLine("OK: " & outFile)
        End If

        LumasPdf.pdfDeletePDF(gPDF)
    End Sub
End Module
