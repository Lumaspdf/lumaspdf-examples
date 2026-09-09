// highlight_annotations -- C++ port of examples\Vb6\annotations\highlight_annotations\highlight_annotations.bas
// Highlight / squiggly / strikeout / underline annotations over text.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString), so every one of
// these calls resolves to the WIDE overload and every annotation string lands
// in the PDF as UTF-16BE-with-BOM. The *A twins used here before wrote
// PDFDocEncoding literals instead -- a real content difference, not a
// formatting one. LWCHAR is wchar_t on Windows and char16_t elsewhere, so the
// literal must be spelled with the header's own LUMAS_TEXT() macro; a bare
// u"..." does not convert to LWCHAR* under MSVC and a bare L"..." is 4 bytes
// wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
//
// ENGINE GAP -- pdfWriteText is DELIBERATELY left on the *A twin here.
// cpp/src/pdf/document.cpp TLumasPdfDoc::WriteTextW applies ResetFrameTextY()
// at the top of the function AND then, on the std-14/Type1 fallback path,
// tail-calls WriteTextA(posX, posY, ...) which applies it a SECOND time. Under
// pcTopDown that adds the font size twice, so pdfWriteTextW puts this 20pt run
// at y=752 where the Delphi reference (and pdfWriteTextA) puts it at y=772.
// Delphi's Lumas.Pdf.Document.pas WriteTextW applies ResetFrameTextY only
// inside each early-exit branch and passes the UNMODIFIED PosY to WriteTextA.
// Switching this to pdfWriteTextW would therefore INTRODUCE a content
// difference, not remove one. Reported, not fixed (shared engine DLL).

static const UI32 clYellow = 65535;
static const UI32 clRed = 255;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    const char*  textA = "Some text on a page...";        // see ENGINE-GAP note above
    LWCHAR*      text  = W_("Some text on a page...");
    pdfSetFontW(pdf, W_("Helvetica"), fsRegular, 20.0, 0, cp1252);

    double d = pdfGetDescent(pdf);
    double w = pdfGetTextWidthW(pdf, text);

    pdfWriteTextA(pdf, 50.0, 50.0, textA);
    pdfHighlightAnnotW(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, W_("Test app"), W_("Highligh Annotations"), W_("This is a highlight annotation"));

    pdfWriteTextA(pdf, 50.0, 80.0, textA);
    pdfHighlightAnnotW(pdf, atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, W_("Test app"), W_("Squiggly Annotations"), W_("This is a squiggly annotation"));

    pdfWriteTextA(pdf, 50.0, 110.0, textA);
    pdfHighlightAnnotW(pdf, atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, W_("Test app"), W_("Strikeout Annotations"), W_("This is a strikeout annotation"));

    pdfWriteTextA(pdf, 50.0, 140.0, textA);
    pdfHighlightAnnotW(pdf, atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, W_("Test app"), W_("Underline Annotations"), W_("This is a underline annotation"));
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
