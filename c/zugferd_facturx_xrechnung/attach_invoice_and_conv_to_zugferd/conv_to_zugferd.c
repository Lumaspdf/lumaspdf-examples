/* conv_to_zugferd -- C port of
   examples\Vb6\zugferd_facturx_xrechnung\attach_invoice_and_conv_to_zugferd
   Converts a PDF to PDF/A-3 (FacturX Comfort), attaches factur-x.xml and adds an
   output intent. Uses font-not-found and ICC-profile replacement callbacks. */
#include <stdio.h>
#include "lumaspdf.h"

/* coDefault_PDFA_3 is not exported as a const; its computed value. */
#define coDefault_PDFA_3 0x50EF7F
#define coCheckImages_v 0x00800000
#define coRepairDamagedImages_v 0x02000000

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

/* WeightFromStyle: (Style and $7FF00000) shr 20; +$800 if high bit set. */
static SI32 WeightFromStyle(UI32 Style) {
    SI32 w = (SI32)((Style & 0x7FF00000u) / 0x100000u);
    if (Style & 0x80000000u) w += 0x800;
    return w;
}

static SI32 PDF_CALL FontNotFoundProc(void* Data, void* PDFFont, const char* FontName,
                                      TFStyle Style, SI32 StdFontIndex, LBOOL IsSymbolFont) {
    SI32 s = Style;
    (void)FontName; (void)StdFontIndex; (void)IsSymbolFont;
    if (WeightFromStyle((UI32)s) < 500) s = (s & 0xF) | fsRegular;
    return pdfReplaceFontA((PPDF)Data, PDFFont, "Arial", s, 1);
}

static SI32 PDF_CALL ReplaceICCProfileProc(void* Data, TICCProfileType ProfileType, SI32 ColorSpace) {
    switch (ProfileType) {
        case ictRGB:  return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/sRGB.icc");
        case ictCMYK: return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/ISOcoated_v2_bas.ICC");
        default:      return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/gray.icc");
    }
}

static int ConvertFile(PPDF pdf, SI32 ConvType, const char* InFile, const char* Invoice, const char* OutFile) {
    SI32 ef, retval;
    UI32 convFlags;

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    switch (ConvType) {
        case ctFacturX_Comfort: case ctFacturX_Extended: case ctFacturX_XRechnung:
            convFlags = coDefault_PDFA_3; break;
        default:
            return 0;   /* We create e-invoices in this example and nothing else. */
    }

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    convFlags = coCheckImages_v | coRepairDamagedImages_v;

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage | ifPrepareForPDFA);
    pdfSetImportFlags2(pdf, if2UseProxy);

    pdfOpenImportFileA(pdf, InFile, ptOpen, "");
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    ef = pdfAttachFileA(pdf, Invoice, "EN 16931 compliant invoice", 0);
    if (ConvType != ctFacturX_XRechnung)
        pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);
    else
        pdfAssociateEmbFile(pdf, adCatalog, -1, arSource, ef);

    retval = pdfCheckConformance(pdf, ConvType, convFlags, pdf, FontNotFoundProc, ReplaceICCProfileProc);
    switch (retval) {
        case 1: pdfAddOutputIntentA(pdf, "../../../test_files/sRGB.icc"); break;
        case 2: pdfAddOutputIntentA(pdf, "../../../test_files/ISOcoated_v2_bas.ICC"); break;
        case 3: pdfAddOutputIntentA(pdf, "../../../test_files/gray.icc"); break;
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, OutFile) == 0) { pdfDeletePDF(pdf); return 0; }
        return pdfCloseFile(pdf) != 0;
    }
    return 0;
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    const char* outFile = "out.pdf";

    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfSetCMapDirA(pdf, "../../../Resource/CMap", lcmDelayed | lcmRecursive);

    if (ConvertFile(pdf, ctFacturX_Comfort, "../../../test_files/test_invoice.pdf",
                    "../../../test_files/factur-x.xml", outFile))
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
