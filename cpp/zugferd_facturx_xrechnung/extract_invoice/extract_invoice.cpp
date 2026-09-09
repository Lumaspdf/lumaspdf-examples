// extract_invoice -- C++ mirror of
// examples\Vb6\zugferd_facturx_xrechnung\extract_invoice\extract_invoice.bas
// Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
// buffer via AttachFileEx) and then verifies the embedded e-invoice can be found
// and extracted again.
#include "apputil.h"
#include <vector>
#include <fstream>
#include <string>

static const unsigned long STD_OUTPUT = 0xFFFFFFF5; // STD_OUTPUT_HANDLE (-11)

static void SetColor(unsigned short attr) {
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT), attr);
}
enum { COL_RED = 12, COL_GREEN = 10, COL_YELLOW = 14, COL_WHITE = 15 };

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool GetFileBuffer(const char* fileName, std::vector<char>& buf) {
    std::ifstream f(fileName, std::ios::binary);
    if (!f) return false;
    f.seekg(0, std::ios::end);
    std::streamoff sz = f.tellg();
    f.seekg(0, std::ios::beg);
    if (sz <= 0) return false;
    buf.resize((size_t)sz);
    f.read(buf.data(), sz);
    return true;
}

// ASCII-only widener -- extract_invoice.dpr passes Delphi `string`/`WideString`
// everywhere, so every one of these calls binds to the WIDE overload in the
// reference. Using the ANSI twins here was observable in the output: the /F,
// /UF and /Desc strings of the attachment came out as PDFDocEncoding literals
// where the reference writes UTF-16BE (BOM-prefixed) text strings.
static std::basic_string<LWCHAR> widen(const char* s) {
    std::basic_string<LWCHAR> w;
    for (const unsigned char* p = (const unsigned char*)s; *p; ++p) w.push_back((LWCHAR)*p);
    return w;
}

static bool HaveEInvoice(PPDF pdf, LWCHAR* inFileName) {
    bool ok = false;
    TPDFVersionInfo info; memset(&info, 0, sizeof(info));
    info.StructSize = sizeof(info);

    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetImportFlags(pdf, ifDocInfo | ifEmbeddedFiles);
    pdfSetImportFlags2(pdf, if2UseProxy);

    if (pdfOpenImportFileW(pdf, inFileName, ptOpen, "") < 0) { pdfFreePDF(pdf); return false; }
    pdfImportCatalogObjects(pdf);

    if (pdfGetPDFVersionEx(pdf, &info) == 0) { pdfFreePDF(pdf); return false; }
    if (info.PDFAVersion != 3 || info.FXDocName == 0) { pdfFreePDF(pdf); return false; }

    // extract_invoice.dpr:76 PDF.FindEmbeddedFile(WideString(AnsiString(info.FXDocName)))
    std::basic_string<LWCHAR> wDocName = widen(info.FXDocName);
    int ef = pdfFindEmbeddedFileW(pdf, &wDocName[0]);
    if (ef < 0) {
        SetColor(COL_RED);
        printf("Invoice %s not found!\n", info.FXDocName);
        pdfFreePDF(pdf);
        return false;
    }
    if (ef != 0) {
        SetColor(COL_YELLOW);
        printf("Warning: The invoice should be the first file attachment. This might cause unnecessary problems.\n");
    }
    TPDFFileSpec fs; memset(&fs, 0, sizeof(fs));
    if (pdfGetEmbeddedFile(pdf, ef, &fs, 1) != 0)
        ok = (fs.BufSize > 0);
    pdfFreePDF(pdf);
    return ok;
}

static bool CreateInvoice(PPDF pdf, bool FacturX, LWCHAR* InvoiceName, LWCHAR* OutFile) {
    bool result = false;
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetDocInfoW(pdf, diProducer, (LWCHAR*)LUMAS_TEXT(""));

    if (pdfOpenImportFileW(pdf, (LWCHAR*)LUMAS_TEXT("../../../test_files/test_invoice.pdf"), ptOpen, "") < 0) { pdfFreePDF(pdf); return false; }
    pdfImportPDFFile(pdf, 1, 1, 1);

    std::vector<char> buffer;
    int ef;
    if (GetFileBuffer("../../../test_files/factur-x.xml", buffer))
        ef = pdfAttachFileExW(pdf, buffer.data(), (UI32)buffer.size(), InvoiceName, (LWCHAR*)LUMAS_TEXT("EN 19631 compliant invoice"), 0);
    else
        ef = pdfAttachFileExW(pdf, 0, 0, InvoiceName, (LWCHAR*)LUMAS_TEXT("EN 19631 compliant invoice"), 0);

    if (FacturX) {
        pdfSetPDFVersion(pdf, pvFacturX_Comfort);
        pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);
    } else {
        pdfSetPDFVersion(pdf, pvFacturX_XRechnung);
        pdfAssociateEmbFile(pdf, adCatalog, -1, arSource, ef);
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileW(pdf, OutFile) != 0)
            result = (pdfCloseFile(pdf) != 0);
    }
    pdfFreePDF(pdf);
    return result;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);

    LWCHAR* outFile = (LWCHAR*)LUMAS_TEXT("out.pdf");

    if (!CreateInvoice(pdf, true, (LWCHAR*)LUMAS_TEXT("factur-x.xml"), outFile) || !HaveEInvoice(pdf, outFile) ||
        !CreateInvoice(pdf, false, (LWCHAR*)LUMAS_TEXT("xrechnung.xml"), outFile) || !HaveEInvoice(pdf, outFile)) {
        SetColor(COL_RED);
        printf("XML Invoice not found!\n");
    } else {
        SetColor(COL_GREEN);
        printf("All tests passed!\n");
    }
    SetColor(COL_WHITE);

    pdfDeletePDF(pdf);
    return 0;
}
