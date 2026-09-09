// highlight_annotations -- C++ port of examples\Vb6\annotations\highlight_annotations\highlight_annotations.bas
// Highlight / squiggly / strikeout / underline annotations over text.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

static const UI32 clYellow = 65535;
static const UI32 clRed = 255;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    const char* text = "Some text on a page...";
    pdfSetFontA(pdf, "Helvetica", fsRegular, 20.0, 0, cp1252);

    double d = pdfGetDescent(pdf);
    double w = pdfGetTextWidthA(pdf, text);

    pdfWriteTextA(pdf, 50.0, 50.0, text);
    pdfHighlightAnnotA(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");

    pdfWriteTextA(pdf, 50.0, 80.0, text);
    pdfHighlightAnnotA(pdf, atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");

    pdfWriteTextA(pdf, 50.0, 110.0, text);
    pdfHighlightAnnotA(pdf, atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");

    pdfWriteTextA(pdf, 50.0, 140.0, text);
    pdfHighlightAnnotA(pdf, atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
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
