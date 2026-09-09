/* attach_invoice -- C port of examples\Vb6\zugferd_facturx_xrechnung\attach_invoice
   Imports an existing PDF/A-3 invoice, attaches factur-x.xml, associates it with
   the catalog and sets the FacturX Comfort PDF version. */
#include <stdio.h>
#include "lumaspdf.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    SI32 ef;
    const char* outFile = "out.pdf";

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAsPage | ifImportAll);
    pdfOpenImportFileA(pdf, "../../../test_files/test_invoice.pdf", ptOpen, "");
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    ef = pdfAttachFileA(pdf, "../../../test_files/factur-x.xml", "EN 16931 compliant invoice", 0);
    pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);

    pdfSetPDFVersion(pdf, pvFacturX_Comfort);

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 1; }
        if (pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile);
    }
    pdfDeletePDF(pdf);
    return 0;
}
