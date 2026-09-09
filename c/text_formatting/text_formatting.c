/* text_formatting -- C port of examples\Vb6\text_formatting
   Lays out sample.txt into N columns using a page-break callback and writes
   out.pdf. The VB6 combo (column count) is replaced by a constant (3). */
#include <stdio.h>
#include <stdlib.h>
#include "lumaspdf.h"

typedef struct {
    double PosX, PosY, Width_, Height_, Distance;
    SI32 Column, ColCount;
} TOutRect;

static TOutRect gRect;
static PPDF gPDF;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return -1;   /* break processing if an error occurred */
}

static SI32 PDF_CALL OnPageBreakProc(void* Data, double LastPosX, double LastPosY, LBOOL PageBreak) {
    double x;
    (void)Data; (void)LastPosX; (void)LastPosY;
    pdfSetPageCoords(gPDF, pcTopDown);
    gRect.Column++;
    if ((PageBreak == 0) && (gRect.Column < gRect.ColCount)) {
        x = gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance);
        pdfSetTextRect(gPDF, x, gRect.PosY, gRect.Width_, gRect.Height_);
        return 0;
    } else {
        pdfEndPage(gPDF);
        pdfAppend(gPDF);
        pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
        gRect.Column = 0;
        return 0;
    }
}

static char* LoadTextFile(const char* fileName) {
    FILE* f = fopen(fileName, "rb");
    long sz; char* buf;
    if (!f) return NULL;
    fseek(f, 0, SEEK_END); sz = ftell(f); fseek(f, 0, SEEK_SET);
    buf = (char*)malloc(sz + 1);
    if (buf) { size_t n = fread(buf, 1, sz, f); buf[n] = '\0'; }
    fclose(f);
    return buf;
}

int main(void) {
    const char* outFile = "out.pdf";
    char* fText = LoadTextFile("sample.txt");

    gPDF = pdfNewPDF();
    pdfSetOnErrorProc(gPDF, 0, ErrProc);
    pdfSetDocInfoA(gPDF, diCreator, "C test app");
    pdfSetDocInfoA(gPDF, diSubject, "Multi-column text");
    pdfSetDocInfoA(gPDF, diTitle, "Multi-column text");
    pdfSetPageCoords(gPDF, pcTopDown);

    if (pdfCreateNewPDFA(gPDF, "") == 0) { pdfDeletePDF(gPDF); free(fText); return 1; }

    gRect.ColCount = 3;
    gRect.Column = 0;
    gRect.Distance = 10.0;
    gRect.PosX = 50.0;
    gRect.PosY = 50.0;
    gRect.Height_ = pdfGetPageHeight(gPDF) - 100.0;
    gRect.Width_ = (pdfGetPageWidth(gPDF) - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount;

    pdfSetOnPageBreakProc(gPDF, &gRect, OnPageBreakProc);
    pdfAppend(gPDF);
    pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
    pdfSetFontA(gPDF, "Arial", fsNone, 9.0, 1, cp1252);
    pdfWriteFTextA(gPDF, taJustify, fText ? fText : "");

    pdfEndPage(gPDF);
    if (pdfHaveOpenDoc(gPDF) != 0) {
        pdfSetOnErrorProc(gPDF, 0, 0);
        if (pdfOpenOutputFileA(gPDF, outFile) == 0) { pdfDeletePDF(gPDF); free(fText); return 1; }
        pdfSetOnErrorProc(gPDF, 0, ErrProc);
    }
    if (pdfCloseFile(gPDF) != 0)
        printf("OK: %s\n", outFile);

    pdfDeletePDF(gPDF);
    free(fText);
    return 0;
}
