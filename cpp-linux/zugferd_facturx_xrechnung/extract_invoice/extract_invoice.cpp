// extract_invoice -- C++ mirror of
// examples\Vb6\zugferd_facturx_xrechnung\extract_invoice\extract_invoice.bas
// Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
// buffer via AttachFileEx) and then verifies the embedded e-invoice can be found
// and extracted again.
#include "apputil.h"
#include <vector>
#include <fstream>

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

static bool HaveEInvoice(PPDF pdf, const char* inFileName) {
    bool ok = false;
    TPDFVersionInfo info; memset(&info, 0, sizeof(info));
    info.StructSize = sizeof(info);

    pdfCreateNewPDFA(pdf, "");
    pdfSetImportFlags(pdf, ifDocInfo | ifEmbeddedFiles);
    pdfSetImportFlags2(pdf, if2UseProxy);

    if (pdfOpenImportFileA(pdf, inFileName, ptOpen, "") < 0) { pdfFreePDF(pdf); return false; }
    pdfImportCatalogObjects(pdf);

    if (pdfGetPDFVersionEx(pdf, &info) == 0) { pdfFreePDF(pdf); return false; }
    if (info.PDFAVersion != 3 || info.FXDocName == 0) { pdfFreePDF(pdf); return false; }

    int ef = pdfFindEmbeddedFileA(pdf, info.FXDocName);
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
    // ef + 1: pdfFindEmbeddedFile returns a 0-BASED INDEX while every other
    // embedded-file call takes the 1-BASED handle. That asymmetry is deliberate
    // and documented -- docs\Manual\V17_ExportAPIs\E03_EmbeddedFiles.md says it
    // in as many words ("Unlike every other embedded-file call, this is not the
    // 1-based handle -- add 1 before passing the result to pdfGetEmbeddedFile")
    // and an earlier session already "fixed" the engine to return I+1 and then
    // REVERTED it after reading that page.
    //
    // This example passed the raw index straight through, so it always asked for
    // the wrong file and printed "XML Invoice not found!" even once the
    // attachment really was there. The warning just above already treats the
    // value as 0-based (0 == the first attachment) -- only the +1 was missed.
    TPDFFileSpec fs; memset(&fs, 0, sizeof(fs));
    if (pdfGetEmbeddedFile(pdf, ef + 1, &fs, 1) != 0)
        ok = (fs.BufSize > 0);
    pdfFreePDF(pdf);
    return ok;
}

static bool CreateInvoice(PPDF pdf, bool FacturX, const char* InvoiceName, const char* OutFile) {
    bool result = false;
    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    if (pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_invoice.pdf", ptOpen, "") < 0) { pdfFreePDF(pdf); return false; }
    pdfImportPDFFile(pdf, 1, 1, 1);

    std::vector<char> buffer;
    int ef;
    if (GetFileBuffer(LUMAS_REPO_ROOT "/factur-x.xml", buffer))
        ef = pdfAttachFileExA(pdf, buffer.data(), (UI32)buffer.size(), InvoiceName, "EN 19631 compliant invoice", 0);
    else
        ef = pdfAttachFileExA(pdf, 0, 0, InvoiceName, "EN 19631 compliant invoice", 0);

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
    pdfFreePDF(pdf);
    return result;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);

    const char* outFile = "out.pdf";

    if (!CreateInvoice(pdf, true, "factur-x.xml", outFile) || !HaveEInvoice(pdf, outFile) ||
        !CreateInvoice(pdf, false, "xrechnung.xml", outFile) || !HaveEInvoice(pdf, outFile)) {
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
