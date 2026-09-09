/* multiple_signatures -- C port of examples\Vb6\incremental_updates\multiple_signatures\multiple_signatures.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

/* minimal WinAPI decls (cannot include <windows.h> due to lumaspdf.h typedef clashes) */
__declspec(dllimport) unsigned long __stdcall GetTempFileNameA(const char*, const char*, unsigned long, char*);
__declspec(dllimport) int __stdcall MoveFileExA(const char*, const char*, unsigned long);
__declspec(dllimport) int __stdcall DeleteFileA(const char*);

#define MOVEFILE_COPY_ALLOWED  0x2
#define MOVEFILE_WRITE_THROUGH 0x8

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

static int SignFile(PPDF pdf, const char* InFileName, const char* OutFileName,
                    const char* FieldName, const char* Reason, double PosX, int VisibleSignature)
{
    char outName[1100], tmp[300];
    SI32 sig;
    int usedTemp = 0;
    int ok;

    strcpy(outName, OutFileName);
    if (strcmp(InFileName, OutFileName) == 0) {
        if (GetTempFileNameA(".", "sig", 0, tmp) == 0) return 0;
        strcpy(outName, tmp);
        usedTemp = 1;
    }

    pdfCreateNewPDFA(pdf, outName);
    pdfSetLicenseKey(pdf, "SigDemo");

    pdfSetImportFlags2(pdf, if2IncrementalUpd);
    if (pdfOpenImportFileA(pdf, InFileName, ptOpen, "") < 0) return 0;
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    if (VisibleSignature) {
        pdfSetPageCoords(pdf, pcTopDown);
        pdfEditPage(pdf, 1);
            sig = pdfCreateSigField(pdf, FieldName, -1, PosX, 30.0, 180.0, 40.0);
            pdfSetFieldBorderWidth(pdf, sig, 0.0);
        pdfEndPage(pdf);
    }

    ok = (pdfCloseAndSignFile(pdf, "../../../test_files/test_cert.pfx", "123456", Reason, "") != 0);
    if (ok && usedTemp) {
        DeleteFileA(OutFileName);
        ok = (MoveFileExA(outName, OutFileName, MOVEFILE_COPY_ALLOWED | MOVEFILE_WRITE_THROUGH) != 0);
    }
    return ok;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], filePath[1100];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    sprintf(filePath, "%s\\out.pdf", dir);

    if (SignFile(pdf, "../../../../license.PDF", filePath, "Signature1", "Test signature 1", 50.0, 1)) {
        if (SignFile(pdf, filePath, filePath, "Signature2", "Test signature 2", 430.0, 1)) {
            if (SignFile(pdf, filePath, filePath, "", "Test signature 3", 0.0, 0)) {
                if (SignFile(pdf, filePath, filePath, "", "Test signature 4", 0.0, 0)) {
                    printf("PDF file \"%s\" successfully created!\n", filePath);
                }
            }
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}
