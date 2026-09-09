// attach_invoice -- C++ mirror of
// examples\Vb6\zugferd_facturx_xrechnung\attach_invoice\attach_invoice.bas
// Imports an existing PDF/A-3 invoice, attaches factur-x.xml, associates it with
// the catalog and sets the FacturX Comfort PDF version.
#include "apputil.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    // We assume the invoice is already a valid PDF/A-3 file.
    pdfSetImportFlags(pdf, ifImportAsPage | ifImportAll);
    pdfOpenImportFileA(pdf, "../../../test_files/test_invoice.pdf", ptOpen, "");
    pdfImportPDFFile(pdf, 1, 1, 1);

    int ef = pdfAttachFileA(pdf, "../../../test_files/factur-x.xml", "EN 16931 compliant invoice", 0);
    pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);

    // ZUGFeRD 2.1+ and FacturX share the same PDF version constants.
    pdfSetPDFVersion(pdf, pvFacturX_Comfort);

    if (pdfHaveOpenDoc(pdf) != 0) {
        const char* outFile = "out.pdf";
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }

    pdfDeletePDF(pdf);
    return 0;
}
