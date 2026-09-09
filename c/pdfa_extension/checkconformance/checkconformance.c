/* checkconformance -- C port of
 * examples\Vb6\pdfa_extension\checkconformance\checkconformance.bas
 * Imports a PDF, converts it to PDF/A-3b via CheckConformance with
 * font-not-found and ICC-replacement callbacks, then writes the result. */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"
#include "../../_common.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

/* Data is the PDF handle passed as UserData to CheckConformance. */
static SI32 PDF_CALL FontNotFoundProc(void* Data, void* PDFFont, const char* FontName,
                                      TFStyle Style, SI32 StdFontIndex, LBOOL IsSymbolFont)
{
    (void)FontName; (void)StdFontIndex; (void)IsSymbolFont;
    /* WeightFromStyle is not exposed by the flat wrapper -> replace with Arial preserving Style. */
    return pdfReplaceFontA((PPDF)Data, PDFFont, "Arial", (SI32)Style, 1);
}

static SI32 PDF_CALL ReplaceICCProfileProc(void* Data, TICCProfileType ProfileType, SI32 ColorSpace)
{
    switch (ProfileType) {
        case ictRGB:  return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/sRGB.icc");
        case ictCMYK: return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/ISOcoated_v2_bas.ICC");
        default:      return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, "../../../test_files/gray.icc");
    }
}

static int ConvertFile(PPDF pdf, SI32 ConvType, const char* InFile, const char* OutFile)
{
    SI32 i, n, retval;
    UI32 convFlags;
    TPDFError e;

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    switch (ConvType) {
        case ctNormalize:      convFlags = coAllowDeviceSpaces; break;
        case ctPDFA_1b_2005:   convFlags = coDefault | coFlattenLayers; break;
        case ctPDFA_2b:
        case ctPDFA_2u:        convFlags = coDefault | coDeletePresentation; break;
        default:               convFlags = (coDefault | coDeletePresentation) & ~coDeleteEmbeddedFiles; break;
    }
    convFlags |= coCheckImages;
    convFlags |= coRepairDamagedImages;

    if (ConvType != ctNormalize) {
        pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage | ifPrepareForPDFA);
        pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck);
    } else {
        pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    }

    retval = pdfCheckConformance(pdf, ConvType, convFlags, pdf, FontNotFoundProc, ReplaceICCProfileProc);
    switch (retval) {
        case 1: pdfAddOutputIntentA(pdf, "../../../test_files/sRGB.icc"); break;
        case 2: pdfAddOutputIntentA(pdf, "../../../test_files/ISOcoated_v2_bas.ICC"); break;
        case 3: pdfAddOutputIntentA(pdf, "../../../test_files/gray.icc"); break;
    }

    memset(&e, 0, sizeof(e));
    e.StructSize = sizeof(e);
    n = pdfGetErrLogMessageCount(pdf);
    for (i = 0; i < n; i++) {
        pdfGetErrLogMessage(pdf, i, &e);
        if (e.Msg) printf("%s\n", e.Msg);
    }

    if (pdfHaveOpenDoc(pdf)) {
        if (pdfOpenOutputFileA(pdf, OutFile) == 0) return 0;
        return pdfCloseFile(pdf) != 0;
    }
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], outFile[1100], cmap[1100];
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    exedir(argv[0], dir, sizeof(dir));
    _snprintf(cmap, sizeof(cmap), "%s\\..\\..\\..\\Resource\\CMap", dir);
    pdfSetCMapDirA(pdf, cmap, lcmDelayed | lcmRecursive);
    _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);

    if (ConvertFile(pdf, ctPDFA_3b, "../../../../sample_multipage.pdf", outFile))
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
