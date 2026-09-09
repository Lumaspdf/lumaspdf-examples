// annotation_types -- C++ port of examples\Vb6\annotations\annotation_types\annotation_types.bas
// A tour of annotation types: highlight family, circle/square, text (note),
// file attachment, free text (+callout) and line annotations with every
// line-end style.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

#define RGB_(r,g,b) ((UI32)((UI8)(r) | ((UI8)(g) << 8) | ((UI8)(b) << 16)))

// The Delphi original passes Delphi `string` (UnicodeString), so every call
// resolves to the WIDE overload; the *A twins used here before wrote
// PDFDocEncoding where the reference writes a UTF-16BE PDF text string. LWCHAR
// is wchar_t on Windows and char16_t elsewhere, so the literal must go through
// the header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to
// LWCHAR* under MSVC, and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
//
// ENGINE GAP -- pdfWriteText is DELIBERATELY left on the *A twin here.
// cpp/src/pdf/document.cpp TLumasPdfDoc::WriteTextW applies ResetFrameTextY()
// at the top of the function AND then, on the std-14/Type1 fallback path,
// tail-calls WriteTextA(posX, posY, ...) which applies it a SECOND time. Under
// pcTopDown that adds the font size twice, so pdfWriteTextW lands each run one
// full font size below where the Delphi reference puts it. Delphi's
// Lumas.Pdf.Document.pas WriteTextW applies ResetFrameTextY only inside its
// early-exit branches and passes the UNMODIFIED PosY down to WriteTextA.
// Switching to pdfWriteTextW would INTRODUCE a content difference, not remove
// one. Reported, not fixed (the engine DLL is shared).

static const UI32 clYellow = 65535;
static const UI32 clRed = 255;
static const UI32 clCream = 15793151;
static const UI32 clBlack = 0;
static const UI32 clGray = 8421504;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

// Delphi AddHighlightAnnot helper.
static void AddHighlightAnnot(PPDF pdf, TAnnotType AnnotType, UI32 Color, double x, double y,
                              const char* TextA, LWCHAR* Text, LWCHAR* Subject, LWCHAR* Comment){
    double w = pdfGetTextWidthW(pdf, Text);
    pdfWriteTextA(pdf, x, y, TextA);            // *A on purpose -- see ENGINE GAP note above
    pdfHighlightAnnotW(pdf, AnnotType, x, y + pdfGetDescent(pdf), w, 20.0, Color, W_("Test app"), Subject, Comment);
}

int main(int argc, char** argv){
    SI32 a;
    double y;

    const LWCHAR cr[2] = { (LWCHAR)'\r', 0 };

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    y = 50.0;
    pdfSetFontW(pdf, W_("Helvetica"), fsRegular, 20.0, 0, cp1252);
    AddHighlightAnnot(pdf, atHighlight, clYellow, 50.0, y, "Highlight Annotation", W_("Highlight Annotation"), W_("Highlight Annotations"), W_("This is a highlight annotation"));
    AddHighlightAnnot(pdf, atSquiggly, clRed, 300.0, y, "Squiggly Annotation", W_("Squiggly Annotation"), W_("Highlight Annotations"), W_("This is a squiggly annotation"));
    y = y + 30.0;
    AddHighlightAnnot(pdf, atStrikeOut, clRed, 50.0, y, "Strikeout Annotation", W_("Strikeout Annotation"), W_("Highlight Annotations"), W_("This is a strikeout annotation"));
    AddHighlightAnnot(pdf, atUnderline, clRed, 300.0, y, "Underline Annotation", W_("Underline Annotation"), W_("Highlight Annotations"), W_("This is a underline annotation"));

    y = y + 40.0;
    pdfCircleAnnotW(pdf, 50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, W_("Test app"), W_("Circle Annotations"), W_("This is a circle annotation"));
    pdfSquareAnnotW(pdf, 300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, W_("Test app"), W_("Square Annotations"), W_("This is a square annotation"));

    y = y + 130.0;
    pdfChangeFontSize(pdf, 12.0);
    {
        std::basic_string<LWCHAR> ftext =
              std::basic_string<LWCHAR>(W_("The icon color of text and file attachment annotations can be changed if "))
            + W_("necessary with SetAnnotColor(). The background color must be set.") + cr + cr + W_("Text Annotations:");
        pdfWriteFTextExW(pdf, 50.0, y, pdfGetPageWidth(pdf) - 100.0, -1.0, taLeft, &ftext[0]);
    }

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;
    // The default icon color can be changed if necessary
    pdfTextAnnotW(pdf, 50.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiComment, 0);
    a = pdfTextAnnotW(pdf, 100.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiHelp, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(200, 20, 30));

    pdfTextAnnotW(pdf, 150.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiInsert, 0);
    a = pdfTextAnnotW(pdf, 200.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiKey, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(50, 200, 30));
    pdfTextAnnotW(pdf, 250.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiNewParagraph, 0);
    a = pdfTextAnnotW(pdf, 300.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiNote, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(70, 120, 210));
    pdfTextAnnotW(pdf, 350.0, y, 200.0, 100.0, W_("Test app"), W_("This is a text annotation"), aiParagraph, 0);

    y = y + 50.0;
    pdfWriteTextA(pdf, 50.0, y, "File Attachment Annotations:");

    y = y + 20.0;
    pdfFileAttachAnnotW(pdf, 50.0, y, faiGraph, W_("Test app"), W_("An example attachment"), W_("../../../test_files/gdi.emf"), 1);
    pdfFileAttachAnnotW(pdf, 100.0, y, faiPaperClip, W_("Test app"), W_("An example attachment"), W_("../../../test_files/gdi.emf"), 1);
    a = pdfFileAttachAnnotW(pdf, 150.0, y, faiPushPin, W_("Test app"), W_("An example attachment"), W_("../../../test_files/gdi.emf"), 1);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(70, 120, 210));
    pdfFileAttachAnnotW(pdf, 200.0, y, faiTag, W_("Test app"), W_("An example attachment"), W_("../../../test_files/gdi.emf"), 1);

    y = y + 60.0;
    a = pdfFreeTextAnnotW(pdf, 50.0, y, 200.0, 80.0, W_("Test app"), W_("This is a FreeText Annotation."), taCenter);
    pdfSetAnnotBorderWidth(pdf, a, 3.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clGray);

    a = pdfFreeTextAnnotW(pdf, 400.0, y, 150.0, 45.0, W_("Test app"), W_("This is a FreeText Callout Annotation with a cloudy border."), taCenter);
    pdfSetAnnotBorderWidth(pdf, a, 2.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clRed);
    pdfSetAnnotBorderEffect(pdf, a, beCloudy1);
    pdfConvToFreeTextCallout(pdf, a, 300.0, y + 40.0, 30.0, leOpenArrow);

    y = y + 120.0;
    pdfWriteTextA(pdf, 50.0, y, "Line Annotations:");

    y = y + 30.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leNone, leNone, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leButt, leButt, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leCircle, leCircle, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leClosedArrow, leClosedArrow, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leRClosedArrow, leRClosedArrow, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leDiamond, leDiamond, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leOpenArrow, leOpenArrow, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leROpenArrow, leROpenArrow, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leSlash, leSlash, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));
    y = y + 20.0; pdfLineAnnotW(pdf, 50.0, y, 350.0, y, 1.0, leSquare, leSquare, clRed, clBlack, csDeviceRGB, W_("Test app"), W_("Line Annotations"), W_("This is a line annotation"));

    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0){
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}
