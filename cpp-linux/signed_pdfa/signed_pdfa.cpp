// signed_pdfa -- C++ port of examples\Vb6\signed_pdfa\signed_pdfa.bas
// Creates a PDF/A-1b compatible file with a digitally-signed signature field,
// checks conformance, adds the matching output intent, then signs the file
// with a self-signed certificate.
#include "apputil.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");            // The output file is opened later
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsNone, 10.0, 1, cp1252);
    const char* body =
        "This is a PDF/A 1b compatible PDF file that was digitally signed with "
        "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important "
        "to avoid the usage of the 14 Standard fonts.\r\r"
        "When signing a PDF/A compliant PDF file with the default settings (without creation of a user "
        "defined appearance) the font Arial must be available on the system because it is used to print "
        "the certificate properties into the signature field.\r\r"
        "The font Arial must also be available if an empty signature field was added to the file "
        "without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A "
        "compliant PDF file later with Adobe's Acrobat. The signed PDF file is still compatible "
        "to PDF/A. If you use a third party solution to digitally sign the PDF file then test "
        "whether the signed file is still valid with the PDF/A 1b preflight tool included in Acrobat 8 "
        "Professional.\r\r"
        "Signature fields must be visible and the print flag must be set (default). CheckConformance() "
        "adjusts these flags if necessary and produces a warning if changes were applied. If no changes "
        "should be allowed, just return -1 in the error callback function. If the error callback function "
        "returns 0, LumasPDF assumes that the prior changes were accepted and processing continues.\r\r"
        "\\FC[255]Notice:\\FC[0]\r"
        "It makes no sense to execute CheckConformance() without an error callback function or error event "
        "in VB. If you cannot see what happens during the execution of CheckConformance(), it is "
        "completely useless to use this function!\r\r"
        "CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. "
        "Once the the settings were found it is usually not longer recommended to execute this function. "
        "However, it is of course possible to use CheckConformance() as a general approach to make sure "
        "that files created with the classic API are PDF/A compatible.";
    pdfWriteFTextA(pdf, taLeft, body);

    // ---------------------- Signature field appearance ----------------------
    SI32 sigField = pdfCreateSigField(pdf, "Signature", -1, 200.0, 400.0, 200.0, 80.0);
    pdfSetFieldColor(pdf, sigField, fcBorderColor, csDeviceRGB, NO_COLOR);
    pdfPlaceSigFieldValidateIcon(pdf, sigField, 0.0, 15.0, 50.0, 50.0);
    pdfCreateSigFieldAP(pdf, sigField);

    SI32 sh;
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

    pdfSetFontA(pdf, "Arial", (TFStyle)(fsBold | fsUnderlined), 11.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(120,120,220));
    pdfWriteFTextExA(pdf, 50.0, 60.0, 150.0, -1.0, taCenter, "Digitally signed by:");
    pdfSetFontA(pdf, "Arial", (TFStyle)(fsBold | fsItalic), 18.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(100,100,200));
    pdfWriteFTextExA(pdf, 50.0, 45.0, 150.0, -1.0, taCenter, "LumasPDF");

    pdfEndTemplate(pdf);                 // Close the appearance template.
    // ------------------------------------------------------------------------

    pdfEndPage(pdf);

    // Check whether the file is compatible to PDF/A 1b.
    switch(pdfCheckConformance(pdf, ctPDFA_1b_2005, 0, 0, 0, 0)){
        case 1:
        case 3: pdfAddOutputIntentA(pdf, LUMAS_REPO_ROOT "/sample_rgb.icc"); break;             // Gray, RGB
        case 2: pdfAddOutputIntentA(pdf, LUMAS_REPO_ROOT "/sample_rgb.icc"); /* production: real CMYK press profile */ break; // CMYK
    }

    const char* outFile = "out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile) == 0){ pdfDeletePDF(pdf); return 0; }
    }
    if(pdfCloseAndSignFile(pdf, "test_cert.pfx", "123456", "Test", "") != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
