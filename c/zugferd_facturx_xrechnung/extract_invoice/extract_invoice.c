/* extract_invoice -- C port of examples\Vb6\zugferd_facturx_xrechnung\extract_invoice
   Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
   buffer via AttachFileEx) and verifies the embedded e-invoice can be found and
   extracted again. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lumaspdf.h"

/* Minimal console-color decls (cannot include windows.h: header typedefs HDC/HWND). */
extern void* __stdcall GetStdHandle(unsigned long nStdHandle);
extern int __stdcall SetConsoleTextAttribute(void* hConsoleOutput, unsigned short wAttributes);
#define STD_OUTPUT_HANDLE ((unsigned long)-11)

/* VCL TColor values used as case labels */
#define clRed    0xFF
#define clGreen  0x8000
#define clYellow 0xFFFF
#define clWhite  0xFFFFFF

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void SetColorConsole(long AColor) {
    void* h = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(h, 7);
    switch (AColor) {
        case clRed:    SetConsoleTextAttribute(h, 12); break;
        case clGreen:  SetConsoleTextAttribute(h, 10); break;
        case clYellow: SetConsoleTextAttribute(h, 14); break;
        case clWhite:  SetConsoleTextAttribute(h, 15); break;
    }
}

static char* GetFileBuffer(const char* FileName, UI32* BufSize) {
    FILE* f = fopen(FileName, "rb");
    long sz; char* buf;
    *BufSize = 0;
    if (!f) return NULL;
    fseek(f, 0, SEEK_END); sz = ftell(f); fseek(f, 0, SEEK_SET);
    if (sz <= 0) { fclose(f); return NULL; }
    buf = (char*)malloc(sz);
    if (buf) { *BufSize = (UI32)fread(buf, 1, sz, f); }
    fclose(f);
    return buf;
}

static int HaveEInvoice(PPDF pdf, const char* InFileName) {
    SI32 ef;
    TPDFVersionInfo info;
    TPDFFileSpec fs;
    int result = 0;

    memset(&info, 0, sizeof(info));
    info.StructSize = sizeof(info);

    pdfCreateNewPDFA(pdf, "");
    pdfSetImportFlags(pdf, ifDocInfo | ifEmbeddedFiles);
    pdfSetImportFlags2(pdf, if2UseProxy);

    if (pdfOpenImportFileA(pdf, InFileName, ptOpen, "") < 0) goto cleanup;
    pdfImportCatalogObjects(pdf);

    if (pdfGetPDFVersionEx(pdf, &info) == 0) goto cleanup;
    if ((info.PDFAVersion != 3) || (info.FXDocName == 0)) goto cleanup;

    ef = pdfFindEmbeddedFileA(pdf, info.FXDocName);
    if (ef < 0) {
        SetColorConsole(clRed);
        printf("Invoice %s not found!\n", info.FXDocName);
        goto cleanup;
    }
    if (ef != 0) {
        SetColorConsole(clYellow);
        printf("Warning: The invoice should be the first file attachment.\n");
    }
    memset(&fs, 0, sizeof(fs));
    if (pdfGetEmbeddedFile(pdf, ef, &fs, 1) != 0)
        result = (fs.BufSize > 0);
cleanup:
    pdfFreePDF(pdf);
    return result;
}

static int CreateInvoice(PPDF pdf, int FacturX, const char* InvoiceName, const char* OutFile) {
    SI32 ef;
    UI32 bufSize;
    char* buffer;
    int result = 0;

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    if (pdfOpenImportFileA(pdf, "../../../test_files/test_invoice.pdf", ptOpen, "") < 0) goto done;
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    buffer = GetFileBuffer("../../../test_files/factur-x.xml", &bufSize);
    if (buffer && bufSize > 0)
        ef = pdfAttachFileExA(pdf, buffer, bufSize, InvoiceName, "EN 19631 compliant invoice", 0);
    else
        ef = pdfAttachFileExA(pdf, 0, 0, InvoiceName, "EN 19631 compliant invoice", 0);
    if (buffer) free(buffer);

    if (FacturX) {
        pdfSetPDFVersion(pdf, pvFacturX_Comfort);
        pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);
    } else {
        pdfSetPDFVersion(pdf, pvFacturX_XRechnung);
        pdfAssociateEmbFile(pdf, adCatalog, -1, arSource, ef);
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, OutFile) != 0)
            result = (pdfCloseFile(pdf) != 0);
    }
done:
    pdfFreePDF(pdf);
    return result;
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    const char* outFile = "out.pdf";

    pdfSetOnErrorProc(pdf, 0, PDFError);

    if ((!CreateInvoice(pdf, 1, "factur-x.xml", outFile)) || (!HaveEInvoice(pdf, outFile)) ||
        (!CreateInvoice(pdf, 0, "xrechnung.xml", outFile)) || (!HaveEInvoice(pdf, outFile))) {
        SetColorConsole(clRed);
        printf("XML Invoice not found!\n");
    } else {
        SetColorConsole(clGreen);
        printf("All tests passed!\n");
    }

    pdfDeletePDF(pdf);
    return 0;
}
