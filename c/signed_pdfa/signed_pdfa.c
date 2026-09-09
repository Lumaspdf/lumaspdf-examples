/* signed_pdfa -- C port of examples\Vb6\signed_pdfa
   Creates a PDF/A-1b compatible file with a digitally-signed signature field,
   checks conformance, adds the matching output intent, then signs the file. */
#include <stdio.h>
#include "lumaspdf.h"

#define RGB(r,g,b) ((UI32)(((UI8)(r))|((UI16)((UI8)(g))<<8)|((UI32)((UI8)(b))<<16)))

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    SI32 sigField, sh;
    const char* outFile = "out.pdf";
    const char* body =
        "This is a PDF/A 1b compatible PDF file that was digitally signed with "
        "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important "
        "to avoid the usage of the 14 Standard fonts.\r\r"
        "When signing a PDF/A compliant PDF file with the default settings the font Arial must be "
        "available on the system because it is used to print the certificate properties into the "
        "signature field.\r\r"
        "\\FC[255]Notice:\\FC[0]\r"
        "It makes no sense to execute CheckConformance() without an error callback function. "
        "CheckConformance() should be used to find the right settings to create PDF/A compatible files.";

    pdfCreateNewPDFA(pdf, "");            /* The output file is opened later */
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsNone, 10.0, 1, cp1252);
    pdfWriteFTextA(pdf, taLeft, body);

    /* ---------------------- Signature field appearance ---------------------- */
    sigField = pdfCreateSigField(pdf, "Signature", -1, 200.0, 400.0, 200.0, 80.0);
    pdfSetFieldColor(pdf, sigField, fcBorderColor, csDeviceRGB, NO_COLOR);
    pdfPlaceSigFieldValidateIcon(pdf, sigField, 0.0, 15.0, 50.0, 50.0);
    pdfCreateSigFieldAP(pdf, sigField);

    pdfSaveGraphicState(pdf);
    pdfRectangle(pdf, 0.0, 0.0, 200.0, 80.0, fmNoFill);
    pdfClipPath(pdf, cmWinding, fmNoFill);
    sh = pdfCreateAxialShading(pdf, 0.0, 0.0, 200.0, 0.0, 0.5, RGB(120,120,220), RGB(255,255,255), 1, 1);
    pdfApplyShading(pdf, sh);
    pdfRestoreGraphicState(pdf);

    pdfSaveGraphicState(pdf);
    pdfEllipse(pdf, 50.5, 1.0, 148.5, 78.0, fmNoFill);
    pdfClipPath(pdf, cmWinding, fmNoFill);
    sh = pdfCreateAxialShading(pdf, 0.0, 0.0, 0.0, 78.0, 2.0, RGB(255,255,255), RGB(120,120,220), 1, 1);
    pdfApplyShading(pdf, sh);
    pdfRestoreGraphicState(pdf);

    pdfSetFontA(pdf, "Arial", fsBold | fsUnderlined, 11.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(120,120,220));
    pdfWriteFTextExA(pdf, 50.0, 60.0, 150.0, -1.0, taCenter, "Digitally signed by:");
    pdfSetFontA(pdf, "Arial", fsBold | fsItalic, 18.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(100,100,200));
    pdfWriteFTextExA(pdf, 50.0, 45.0, 150.0, -1.0, taCenter, "DynaPDF");

    pdfEndTemplate(pdf);
    /* ------------------------------------------------------------------------ */

    pdfEndPage(pdf);

    switch (pdfCheckConformance(pdf, ctPDFA_1b_2005, 0, 0, 0, 0)) {
        case 1: case 3: pdfAddOutputIntentA(pdf, "sRGB.icc"); break;             /* Gray, RGB */
        case 2:         pdfAddOutputIntentA(pdf, "ISOcoated_v2_bas.ICC"); break; /* CMYK */
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 1; }
    }
    if (pdfCloseAndSignFile(pdf, "test_cert.pfx", "123456", "Test", "") != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
