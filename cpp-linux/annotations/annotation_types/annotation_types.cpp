// annotation_types -- C++ port of examples\Vb6\annotations\annotation_types\annotation_types.bas
// A tour of annotation types: highlight family, circle/square, text (note),
// file attachment, free text (+callout) and line annotations with every
// line-end style.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

#define RGB_(r,g,b) ((UI32)((UI8)(r) | ((UI8)(g) << 8) | ((UI8)(b) << 16)))

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
static void AddHighlightAnnot(PPDF pdf, TAnnotType AnnotType, UI32 Color, double x, double y, const char* Text, const char* Subject, const char* Comment){
    double w = pdfGetTextWidthA(pdf, Text);
    pdfWriteTextA(pdf, x, y, Text);
    pdfHighlightAnnotA(pdf, AnnotType, x, y + pdfGetDescent(pdf), w, 20.0, Color, "Test app", Subject, Comment);
}

int main(int argc, char** argv){
    SI32 a;
    double y;

    const char* cr = "\r";

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    y = 50.0;
    pdfSetFontA(pdf, "Helvetica", fsRegular, 20.0, 0, cp1252);
    AddHighlightAnnot(pdf, atHighlight, clYellow, 50.0, y, "Highlight Annotation", "Highlight Annotations", "This is a highlight annotation");
    AddHighlightAnnot(pdf, atSquiggly, clRed, 300.0, y, "Squiggly Annotation", "Highlight Annotations", "This is a squiggly annotation");
    y = y + 30.0;
    AddHighlightAnnot(pdf, atStrikeOut, clRed, 50.0, y, "Strikeout Annotation", "Highlight Annotations", "This is a strikeout annotation");
    AddHighlightAnnot(pdf, atUnderline, clRed, 300.0, y, "Underline Annotation", "Highlight Annotations", "This is a underline annotation");

    y = y + 40.0;
    pdfCircleAnnotA(pdf, 50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, "Test app", "Circle Annotations", "This is a circle annotation");
    pdfSquareAnnotA(pdf, 300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, csDeviceRGB, "Test app", "Square Annotations", "This is a square annotation");

    y = y + 130.0;
    pdfChangeFontSize(pdf, 12.0);
    {
        std::string ftext = std::string("The icon color of text and file attachment annotations can be changed if ")
            + "necessary with SetAnnotColor(). The background color must be set." + cr + cr + "Text Annotations:";
        pdfWriteFTextExA(pdf, 50.0, y, pdfGetPageWidth(pdf) - 100.0, -1.0, taLeft, ftext.c_str());
    }

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;
    // The default icon color can be changed if necessary
    pdfTextAnnotA(pdf, 50.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiComment, 0);
    a = pdfTextAnnotA(pdf, 100.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiHelp, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(200, 20, 30));

    pdfTextAnnotA(pdf, 150.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiInsert, 0);
    a = pdfTextAnnotA(pdf, 200.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiKey, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(50, 200, 30));
    pdfTextAnnotA(pdf, 250.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiNewParagraph, 0);
    a = pdfTextAnnotA(pdf, 300.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiNote, 0);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(70, 120, 210));
    pdfTextAnnotA(pdf, 350.0, y, 200.0, 100.0, "Test app", "This is a text annotation", aiParagraph, 0);

    y = y + 50.0;
    pdfWriteTextA(pdf, 50.0, y, "File Attachment Annotations:");

    y = y + 20.0;
    pdfFileAttachAnnotA(pdf, 50.0, y, faiGraph, "Test app", "An example attachment", LUMAS_REPO_ROOT "/sample_vector.emf", 1);
    pdfFileAttachAnnotA(pdf, 100.0, y, faiPaperClip, "Test app", "An example attachment", LUMAS_REPO_ROOT "/sample_vector.emf", 1);
    a = pdfFileAttachAnnotA(pdf, 150.0, y, faiPushPin, "Test app", "An example attachment", LUMAS_REPO_ROOT "/sample_vector.emf", 1);
    pdfSetAnnotColor(pdf, a, fcBackColor, csDeviceRGB, RGB_(70, 120, 210));
    pdfFileAttachAnnotA(pdf, 200.0, y, faiTag, "Test app", "An example attachment", LUMAS_REPO_ROOT "/sample_vector.emf", 1);

    y = y + 60.0;
    a = pdfFreeTextAnnotA(pdf, 50.0, y, 200.0, 80.0, "Test app", "This is a FreeText Annotation.", taCenter);
    pdfSetAnnotBorderWidth(pdf, a, 3.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clGray);

    a = pdfFreeTextAnnotA(pdf, 400.0, y, 150.0, 45.0, "Test app", "This is a FreeText Callout Annotation with a cloudy border.", taCenter);
    pdfSetAnnotBorderWidth(pdf, a, 2.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clRed);
    pdfSetAnnotBorderEffect(pdf, a, beCloudy1);
    pdfConvToFreeTextCallout(pdf, a, 300.0, y + 40.0, 30.0, leOpenArrow);

    y = y + 120.0;
    pdfWriteTextA(pdf, 50.0, y, "Line Annotations:");

    y = y + 30.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leNone, leNone, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leButt, leButt, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leCircle, leCircle, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leClosedArrow, leClosedArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leRClosedArrow, leRClosedArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leDiamond, leDiamond, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leOpenArrow, leOpenArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leROpenArrow, leROpenArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leSlash, leSlash, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");
    y = y + 20.0; pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, leSquare, leSquare, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation");

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
