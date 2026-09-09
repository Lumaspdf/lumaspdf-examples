/* comments -- C port of examples\Vb6\incremental_updates\comments\comments.bas */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

/* Creates the base file in memory and returns a private copy of the PDF buffer. */
static int CreateTestFile(PPDF pdf, unsigned char** buf, UI32* bufSize)
{
    char* p;
    pdfCreateNewPDFA(pdf, "");
    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
        pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just a test...");
    pdfEndPage(pdf);

    if (pdfCloseFile(pdf) == 0) return 0;
    p = pdfGetBuffer(pdf, bufSize);
    if (p == 0 || *bufSize == 0) return 0;
    *buf = (unsigned char*)malloc(*bufSize);
    memcpy(*buf, p, *bufSize);
    pdfFreePDF(pdf);
    return 1;
}

static int LoadTestFile(PPDF pdf, unsigned char* buf, UI32 bufSize)
{
    pdfCreateNewPDFA(pdf, "");
    pdfSetImportFlags2(pdf, if2IncrementalUpd);
    if (pdfOpenImportBuffer(pdf, buf, bufSize, ptOpen, "") < 0) return 0;
    return (pdfImportPDFFile(pdf, 1, 1.0, 1.0) > 0);
}

static int SaveFile(PPDF pdf, unsigned char** buf, UI32* bufSize)
{
    char* p;
    if (pdfCloseFile(pdf) == 0) return 0;
    p = pdfGetBuffer(pdf, bufSize);
    if (p == 0 || *bufSize == 0) return 0;
    free(*buf);
    *buf = (unsigned char*)malloc(*bufSize);
    memcpy(*buf, p, *bufSize);
    pdfFreePDF(pdf);
    return 1;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    SI32 reply;
    UI32 bufSize = 0;
    unsigned char* buf = 0;
    char dir[1024], filePath[1100];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    if (!CreateTestFile(pdf, &buf, &bufSize)) { pdfDeletePDF(pdf); free(buf); return 0; }

    if (LoadTestFile(pdf, buf, bufSize)) {
        reply = pdfSetAnnotMigrationStateA(pdf, 0, asCreateReply, "Harry");
        pdfSetAnnotStringA(pdf, reply, asContent, "Hi Jim, your test annotation looks fine!");
        if (SaveFile(pdf, &buf, &bufSize)) {
            if (LoadTestFile(pdf, buf, bufSize)) {
                reply = pdfSetAnnotMigrationStateA(pdf, reply, asCreateReply, "Tommy");
                pdfSetAnnotStringA(pdf, reply, asContent, "Just a test whether I can reply to a reply...");
                if (SaveFile(pdf, &buf, &bufSize)) {
                    if (LoadTestFile(pdf, buf, bufSize)) {
                        reply = pdfSetAnnotMigrationStateA(pdf, reply, asCreateReply, "Jim");
                        pdfSetAnnotStringA(pdf, reply, asContent, "Seems to work very well!");
                        if (pdfHaveOpenDoc(pdf) != 0) {
                            sprintf(filePath, "%s\\out.pdf", dir);
                            if (pdfOpenOutputFileA(pdf, filePath) != 0) {
                                if (pdfCloseFile(pdf) != 0)
                                    printf("PDF file \"%s\" successfully created!\n", filePath);
                            }
                        }
                    }
                }
            }
        }
    }

    pdfDeletePDF(pdf);
    free(buf);
    return 0;
}
