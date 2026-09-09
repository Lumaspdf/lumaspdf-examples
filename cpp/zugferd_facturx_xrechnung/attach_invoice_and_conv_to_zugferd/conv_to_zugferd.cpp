// conv_to_zugferd -- C++ mirror of examples\Vb6\zugferd_facturx_xrechnung\
//   attach_invoice_and_conv_to_zugferd\conv_to_zugferd.bas
// Converts a PDF to PDF/A-3 (FacturX Comfort), attaches factur-x.xml and adds an
// output intent, using font-not-found and ICC-profile replacement callbacks.
#include "apputil.h"

// coDefault_PDFA_3 is not exported as a const; this is its computed value.
static const unsigned int coDefault_PDFA_3 = 0x50EF7F;

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

// WeightFromStyle: (Style and $7FF00000) shr 20, +$800 if sign bit set.
static long WeightFromStyle(long Style) {
    long w = (long)((Style & 0x7FF00000) >> 20);
    if (Style & 0x80000000) w += 0x800;
    return w;
}

static SI32 PDF_CALL FontNotFoundProc(void* Data, void* PDFFont, const char* FontName,
                                       TFStyle Style, SI32 StdFontIndex, LBOOL IsSymbolFont) {
    long s = Style;
    if (WeightFromStyle(s) < 500) s = (s & 0xF) | (long)fsRegular;
    return pdfReplaceFontA((PPDF)Data, PDFFont, "Arial", (SI32)s, 1);
}

static SI32 PDF_CALL ReplaceICCProfileProc(void* Data, TICCProfileType ProfileType, SI32 ColorSpace) {
    switch (ProfileType) {
        case ictRGB:  return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/sRGB.icc");
        case ictCMYK: return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/ISOcoated_v2_bas.ICC");
        default:      return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/gray.icc");
    }
}

static bool ConvertFile(PPDF pdf, int ConvType, const char* InFile, const char* Invoice, const char* OutFile) {
    unsigned int convFlags;
    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    switch (ConvType) {
        case ctFacturX_Comfort:
        case ctFacturX_Extended:
        case ctFacturX_XRechnung:
            convFlags = coDefault_PDFA_3;
            break;
        default:
            return false; // We only create e-invoices here.
    }

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    // These flags require some processing time but are very useful.
    convFlags = coCheckImages | coRepairDamagedImages;

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage | ifPrepareForPDFA);
    pdfSetImportFlags2(pdf, if2UseProxy);

    pdfOpenImportFileA(pdf, InFile, ptOpen, "");
    pdfImportPDFFile(pdf, 1, 1, 1);
    pdfCloseImportFile(pdf);

    int ef = pdfAttachFileA(pdf, Invoice, "EN 16931 compliant invoice", 0);
    if (ConvType != ctFacturX_XRechnung)
        pdfAssociateEmbFile(pdf, adCatalog, -1, arAlternative, ef);
    else
        pdfAssociateEmbFile(pdf, adCatalog, -1, arSource, ef);

    int retval = pdfCheckConformance(pdf, ConvType, convFlags, pdf, FontNotFoundProc, ReplaceICCProfileProc);
    switch (retval) {
        case 1: pdfAddOutputIntentA(pdf, "../../../test_files/sRGB.icc"); break;
        case 2: pdfAddOutputIntentA(pdf, "../../../test_files/ISOcoated_v2_bas.ICC"); break;
        case 3: pdfAddOutputIntentA(pdf, "../../../test_files/gray.icc"); break;
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, OutFile) == 0) { pdfDeletePDF(pdf); return false; }
        return pdfCloseFile(pdf) != 0;
    }
    return false;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);

    // Non-embedded CID fonts usually depend on external cmaps.
    pdfSetCMapDirA(pdf, "../../../Resource/CMap", lcmDelayed | lcmRecursive);

    const char* outFile = "out.pdf";
    if (ConvertFile(pdf, ctFacturX_Comfort, "../../../test_files/test_invoice.pdf",
                    "../../../test_files/factur-x.xml", outFile))
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
