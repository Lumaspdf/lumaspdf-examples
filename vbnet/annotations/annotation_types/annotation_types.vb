' annotation_types -- VB.NET port of examples\Vb6\annotations\annotation_types
Imports System
Imports System.IO
Imports LumasPdfSdk

Module AnnotationTypes
    Private Const clYellow As UInteger = 65535UI
    Private Const clRed As UInteger = 255UI
    Private Const clCream As UInteger = 15793151UI
    Private Const clBlack As UInteger = 0UI
    Private Const clGray As UInteger = 8421504UI
    Private errDel As TErrorProc
    Private emfPath As String

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Private Function RGB(ByVal r As Integer, ByVal g As Integer, ByVal b As Integer) As UInteger
        Return CUInt(r Or (g << 8) Or (b << 16))
    End Function

    Private Sub AddHighlightAnnot(ByVal pdf As IntPtr, ByVal AnnotType As TAnnotType, ByVal Color As UInteger, ByVal x As Double, ByVal y As Double, ByVal Text As String, ByVal Subject As String, ByVal Comment As String)
        Dim w As Double = LumasPdf.pdfGetTextWidthW(pdf, Text)
        LumasPdf.pdfWriteTextW(pdf, x, y, Text)
        LumasPdf.pdfHighlightAnnotW(pdf, AnnotType, x, y + LumasPdf.pdfGetDescent(pdf), w, 20.0, Color, "Test app", Subject, Comment)
    End Sub

    Sub Main()
        Dim a As Integer
        Dim y As Double
        Dim cr As String = vbCr
        emfPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "gdi.emf")

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)

        y = 50.0
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, False, TCodepage.cp1252)
        AddHighlightAnnot(pdf, TAnnotType.atHighlight, clYellow, 50.0, y, "Highlight Annotation", "Highlight Annotations", "This is a highlight annotation")
        AddHighlightAnnot(pdf, TAnnotType.atSquiggly, clRed, 300.0, y, "Squiggly Annotation", "Highlight Annotations", "This is a squiggly annotation")
        y = y + 30.0
        AddHighlightAnnot(pdf, TAnnotType.atStrikeOut, clRed, 50.0, y, "Strikeout Annotation", "Highlight Annotations", "This is a strikeout annotation")
        AddHighlightAnnot(pdf, TAnnotType.atUnderline, clRed, 300.0, y, "Underline Annotation", "Highlight Annotations", "This is a underline annotation")

        y = y + 40.0
        LumasPdf.pdfCircleAnnotW(pdf, 50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Circle Annotations", "This is a circle annotation")
        LumasPdf.pdfSquareAnnotW(pdf, 300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Square Annotations", "This is a square annotation")

        y = y + 130.0
        LumasPdf.pdfChangeFontSize(pdf, 12.0)
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, y, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, LumasPdfConsts.taLeft, "The icon color of text and file attachment annotations can be changed if " & _
            "necessary with SetAnnotColor(). The background color must be set." & cr & cr & "Text Annotations:")

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0
        LumasPdf.pdfTextAnnotW(pdf, 50.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiComment, False)
        a = LumasPdf.pdfTextAnnotW(pdf, 100.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiHelp, False)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(200, 20, 30))

        LumasPdf.pdfTextAnnotW(pdf, 150.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiInsert, False)
        a = LumasPdf.pdfTextAnnotW(pdf, 200.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiKey, False)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(50, 200, 30))
        LumasPdf.pdfTextAnnotW(pdf, 250.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiNewParagraph, False)
        a = LumasPdf.pdfTextAnnotW(pdf, 300.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiNote, False)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(70, 120, 210))
        LumasPdf.pdfTextAnnotW(pdf, 350.0, y, 200.0, 100.0, "Test app", "This is a text annotation", TAnnotIcon.aiParagraph, False)

        y = y + 50.0
        LumasPdf.pdfWriteTextW(pdf, 50.0, y, "File Attachment Annotations:")

        y = y + 20.0
        LumasPdf.pdfFileAttachAnnotW(pdf, 50.0, y, TFileAttachIcon.faiGraph, "Test app", "An example attachment", emfPath, True)
        LumasPdf.pdfFileAttachAnnotW(pdf, 100.0, y, TFileAttachIcon.faiPaperClip, "Test app", "An example attachment", emfPath, True)
        a = LumasPdf.pdfFileAttachAnnotW(pdf, 150.0, y, TFileAttachIcon.faiPushPin, "Test app", "An example attachment", emfPath, True)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(70, 120, 210))
        LumasPdf.pdfFileAttachAnnotW(pdf, 200.0, y, TFileAttachIcon.faiTag, "Test app", "An example attachment", emfPath, True)

        y = y + 60.0
        a = LumasPdf.pdfFreeTextAnnotW(pdf, 50.0, y, 200.0, 80.0, "Test app", "This is a FreeText Annotation.", LumasPdfConsts.taCenter)
        LumasPdf.pdfSetAnnotBorderWidth(pdf, a, 3.0)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clGray)

        a = LumasPdf.pdfFreeTextAnnotW(pdf, 400.0, y, 150.0, 45.0, "Test app", "This is a FreeText Callout Annotation with a cloudy border.", LumasPdfConsts.taCenter)
        LumasPdf.pdfSetAnnotBorderWidth(pdf, a, 2.0)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clRed)
        LumasPdf.pdfSetAnnotBorderEffect(pdf, a, TBorderEffect.beCloudy1)
        LumasPdf.pdfConvToFreeTextCallout(pdf, a, 300.0F, CSng(y + 40.0), 30.0F, TLineEndStyle.leOpenArrow)

        y = y + 120.0
        LumasPdf.pdfWriteTextW(pdf, 50.0, y, "Line Annotations:")

        y = y + 30.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leNone, TLineEndStyle.leNone, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leButt, TLineEndStyle.leButt, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leCircle, TLineEndStyle.leCircle, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leRClosedArrow, TLineEndStyle.leRClosedArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leDiamond, TLineEndStyle.leDiamond, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leOpenArrow, TLineEndStyle.leOpenArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leROpenArrow, TLineEndStyle.leROpenArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leSlash, TLineEndStyle.leSlash, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")
        y = y + 20.0 : LumasPdf.pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, TLineEndStyle.leSquare, TLineEndStyle.leSquare, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation")

        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
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
