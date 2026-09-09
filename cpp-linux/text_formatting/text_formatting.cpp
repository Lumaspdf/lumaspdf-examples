// text_formatting -- C++ port of examples\Vb6\text_formatting\text_formatting.bas
// Lays out sample.txt into N columns using a page-break callback and writes
// out.pdf. The column count is a constant (the VB6 combo default was 3).
#include "apputil.h"
#include <string>

// Holds the formatting options - passed to the callback via its Data pointer.
struct TOutRect {
    double PosX;      // Original x-coordinate of first output rectangle
    double PosY;      // Original y-coordinate of first output rectangle
    double Width_;    // Original width of first output rectangle
    double Height_;   // Original height of first output rectangle
    double Distance;  // Space between columns
    SI32   Column;    // Current column
    SI32   ColCount;  // Number of columns
};

static TOutRect gRect;
static PPDF     gPDF;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return -1;   // we break processing if an error occurred.
}

// Page-break callback. Places the next column or starts a new page.
static SI32 PDF_CALL OnPageBreakProc(void* Data, double LastPosX, double LastPosY, LBOOL PageBreak){
    pdfSetPageCoords(gPDF, pcTopDown);   // we use top down coordinates
    gRect.Column = gRect.Column + 1;
    if((PageBreak == 0) && (gRect.Column < gRect.ColCount)){
        double x = gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance);
        pdfSetTextRect(gPDF, x, gRect.PosY, gRect.Width_, gRect.Height_);
        return 0;   // we do not change the alignment
    } else {
        pdfEndPage(gPDF);
        pdfAppend(gPDF);
        pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
        gRect.Column = 0;
        return 0;
    }
}

static std::string LoadTextFile(const char* fileName){
    std::string s;
    FILE* f = fopen(fileName, "rb");
    if(!f) return s;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if(sz > 0){
        s.resize((size_t)sz);
        size_t rd = fread(&s[0], 1, (size_t)sz, f);
        s.resize(rd);
    }
    fclose(f);
    return s;
}

int main(){
    ChdirToExe();

    // The text is stored in a file (guarded: still runs if missing).
    std::string fText = LoadTextFile("sample.txt");

    gPDF = pdfNewPDF();
    pdfSetOnErrorProc(gPDF, 0, ErrProc);
    pdfSetDocInfoA(gPDF, diCreator, "C++ test app");
    pdfSetDocInfoA(gPDF, diSubject, "Multi-column text");
    pdfSetDocInfoA(gPDF, diTitle, "Multi-column text");
    pdfSetPageCoords(gPDF, pcTopDown);

    if(pdfCreateNewPDFA(gPDF, "") == 0){   // The output file is opened later
        pdfDeletePDF(gPDF);
        return 0;
    }

    gRect.ColCount = 3;                 // VB6 combo default was 3 columns
    gRect.Column   = 0;
    gRect.Distance = 10.0;
    gRect.PosX     = 50.0;
    gRect.PosY     = 50.0;
    gRect.Height_  = pdfGetPageHeight(gPDF) - 100.0;
    gRect.Width_   = (pdfGetPageWidth(gPDF) - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount;

    pdfSetOnPageBreakProc(gPDF, &gRect, OnPageBreakProc);
    pdfAppend(gPDF);                    // Append a new page
    pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
    pdfSetFontA(gPDF, "Arial", fsNone, 9.0, 1, cp1252);   // A font is always required
    pdfWriteFTextA(gPDF, taJustify, fText.c_str());       // Now print the text

    pdfEndPage(gPDF);                  // Close the last page
    const char* outFile = "out.pdf";
    if(pdfHaveOpenDoc(gPDF) != 0){
        pdfSetOnErrorProc(gPDF, 0, 0);
        if(pdfOpenOutputFileA(gPDF, outFile) == 0){ pdfDeletePDF(gPDF); return 0; }
        pdfSetOnErrorProc(gPDF, 0, ErrProc);
    }
    if(pdfCloseFile(gPDF) != 0)
        printf("OK: %s\n", outFile);

    pdfDeletePDF(gPDF);
    return 0;
}
