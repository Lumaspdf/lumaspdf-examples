/* hello_world -- C port of examples\Vb6\hello_world\hello_world.bas
 * Writes out.pdf with a single centred line of text (PDF/A). */
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return -1; /* break processing on error */
}

/* Directory of the running exe (argv[0]) into out; strip the file name. */
static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], outFile[1100], msg[256];
    time_t t = time(NULL);
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    if (pdfCreateNewPDFA(pdf, "") == 0) { pdfDeletePDF(pdf); return 1; }

    pdfSetDocInfoA(pdf, diCreator, "Delphi Example project");
    pdfSetDocInfoA(pdf, diTitle, "My first PDF output");

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsItalic, 30.0, 1, cp1252);
    _snprintf(msg, sizeof(msg), "My first PDF output...\r\r%s", ctime(&t));
    pdfWriteFTextA(pdf, taCenter, msg);
    pdfEndPage(pdf);

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);

    if (pdfHaveOpenDoc(pdf)) {
        pdfSetOnErrorProc(pdf, 0, NULL);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 1; }
        pdfSetOnErrorProc(pdf, 0, ErrProc);
    }
    if (pdfCloseFile(pdf)) printf("OK: %s\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
