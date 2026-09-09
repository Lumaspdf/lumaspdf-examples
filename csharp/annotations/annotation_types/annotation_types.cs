//  annotation_types -- C# port of examples\Vb6\annotations\annotation_types\annotation_types.bas
//  A tour of annotation types: highlight family, circle/square, text (note),
//  file attachment, free text (+callout) and line annotations.
using System;
using System.IO;
using LumasPdfSdk;

class AnnotationTypes
{
    const uint clYellow = 65535;
    const uint clRed = 255;
    const uint clCream = 15793151;
    const uint clBlack = 0;
    const uint clGray = 8421504;

    static uint RGB(int r, int g, int b) { return (uint)(r | (g << 8) | (b << 16)); }

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void AddHighlightAnnot(IntPtr pdf, TAnnotType annotType, uint color, double x, double y, string text, string subject, string comment)
    {
        double w = LumasPdf.pdfGetTextWidthW(pdf, text);
        LumasPdf.pdfWriteTextW(pdf, x, y, text);
        LumasPdf.pdfHighlightAnnotW(pdf, annotType, x, y + LumasPdf.pdfGetDescent(pdf), w, 20, color, "Test app", subject, comment);
    }

    static void Main()
    {
        double y;
        string cr = "\r";
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);

        y = 50.0;
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, false, TCodepage.cp1252);
        AddHighlightAnnot(pdf, TAnnotType.atHighlight, clYellow, 50, y, "Highlight Annotation", "Highlight Annotations", "This is a highlight annotation");
        AddHighlightAnnot(pdf, TAnnotType.atSquiggly, clRed, 300, y, "Squiggly Annotation", "Highlight Annotations", "This is a squiggly annotation");
        y = y + 30.0;
        AddHighlightAnnot(pdf, TAnnotType.atStrikeOut, clRed, 50, y, "Strikeout Annotation", "Highlight Annotations", "This is a strikeout annotation");
        AddHighlightAnnot(pdf, TAnnotType.atUnderline, clRed, 300, y, "Underline Annotation", "Highlight Annotations", "This is a underline annotation");

        y = y + 40.0;
        LumasPdf.pdfCircleAnnotW(pdf, 50, y, 200, 100, 1, clCream, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Circle Annotations", "This is a circle annotation");
        LumasPdf.pdfSquareAnnotW(pdf, 300, y, 200, 100, 1, clCream, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Square Annotations", "This is a square annotation");

        y = y + 130.0;
        LumasPdf.pdfChangeFontSize(pdf, 12.0);
        LumasPdf.pdfWriteFTextExW(pdf, 50, y, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1, (int)LumasPdfConsts.taLeft,
            "The icon color of text and file attachment annotations can be changed if " +
            "necessary with SetAnnotColor(). The background color must be set." + cr + cr + "Text Annotations:");

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;
        LumasPdf.pdfTextAnnotW(pdf, 50, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiComment, false);
        int a = LumasPdf.pdfTextAnnotW(pdf, 100, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiHelp, false);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(200, 20, 30));

        LumasPdf.pdfTextAnnotW(pdf, 150, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiInsert, false);
        a = LumasPdf.pdfTextAnnotW(pdf, 200, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiKey, false);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(50, 200, 30));
        LumasPdf.pdfTextAnnotW(pdf, 250, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiNewParagraph, false);
        a = LumasPdf.pdfTextAnnotW(pdf, 300, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiNote, false);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(70, 120, 210));
        LumasPdf.pdfTextAnnotW(pdf, 350, y, 200, 100, "Test app", "This is a text annotation", TAnnotIcon.aiParagraph, false);

        y = y + 50.0;
        LumasPdf.pdfWriteTextW(pdf, 50, y, "File Attachment Annotations:");

        y = y + 20.0;
        LumasPdf.pdfFileAttachAnnotW(pdf, 50, y, TFileAttachIcon.faiGraph, "Test app", "An example attachment", "../../../test_files/gdi.emf", true);
        LumasPdf.pdfFileAttachAnnotW(pdf, 100, y, TFileAttachIcon.faiPaperClip, "Test app", "An example attachment", "../../../test_files/gdi.emf", true);
        a = LumasPdf.pdfFileAttachAnnotW(pdf, 150, y, TFileAttachIcon.faiPushPin, "Test app", "An example attachment", "../../../test_files/gdi.emf", true);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, RGB(70, 120, 210));
        LumasPdf.pdfFileAttachAnnotW(pdf, 200, y, TFileAttachIcon.faiTag, "Test app", "An example attachment", "../../../test_files/gdi.emf", true);

        y = y + 60.0;
        a = LumasPdf.pdfFreeTextAnnotW(pdf, 50, y, 200, 80, "Test app", "This is a FreeText Annotation.", LumasPdfConsts.taCenter);
        LumasPdf.pdfSetAnnotBorderWidth(pdf, (uint)a, 3);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clGray);

        a = LumasPdf.pdfFreeTextAnnotW(pdf, 400, y, 150, 45, "Test app", "This is a FreeText Callout Annotation with a cloudy border.", LumasPdfConsts.taCenter);
        LumasPdf.pdfSetAnnotBorderWidth(pdf, (uint)a, 2);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clRed);
        LumasPdf.pdfSetAnnotBorderEffect(pdf, (uint)a, TBorderEffect.beCloudy1);
        LumasPdf.pdfConvToFreeTextCallout(pdf, (uint)a, 300f, (float)(y + 40.0), 30f, TLineEndStyle.leOpenArrow);

        y = y + 120.0;
        LumasPdf.pdfWriteTextW(pdf, 50, y, "Line Annotations:");

        y = y + 30.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leNone, TLineEndStyle.leNone, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leButt, TLineEndStyle.leButt, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leCircle, TLineEndStyle.leCircle, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leRClosedArrow, TLineEndStyle.leRClosedArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leDiamond, TLineEndStyle.leDiamond, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leOpenArrow, TLineEndStyle.leOpenArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leROpenArrow, TLineEndStyle.leROpenArrow, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leSlash, TLineEndStyle.leSlash, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
        y = y + 20.0; LumasPdf.pdfLineAnnotW(pdf, 50, y, 350, y, 1, TLineEndStyle.leSquare, TLineEndStyle.leSquare, clRed, clBlack, TPDFColorSpace.csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");

        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile)) { LumasPdf.pdfDeletePDF(pdf); return; }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}
