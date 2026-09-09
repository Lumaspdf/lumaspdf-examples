// signature_ap -- C++ port of examples\Vb6\signature_ap\signature_ap.bas
// Builds a page with a digitally-signed signature field whose appearance
// template is drawn with normal PDF functions, then signs the file with a
// self-signed certificate.
#include "apputil.h"
#include <string>

// The Delphi original passes `string` (UnicodeString), which binds to the
// WideString overload of CreateNewPDF/SetFont/WriteFText/WriteFTextEx/
// OpenOutputFile. CreateSigField and CloseAndSignFile have ONLY AnsiString
// overloads in LumasPdf.pas, so those two correctly stay on the A entry points.
static std::basic_string<LWCHAR> W(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));   // The output file is opened later
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    pdfAppend(pdf);
    pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Arial"), fsNone, 14.0, 1, cp1252);
    LWCHAR* body = (LWCHAR*)LUMAS_TEXT(
        "This file is digitally signed with a self sign certificate. "
        "The appearance of the signature field is created with normal classic-API functions. However, it "
        "would also be possible to import a PDF page, an EMF file, or an image into the "
        "appearance template.\n\n"
        "When creating an individual signature appearance make sure to place the validation icon "
        "properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon "
        "depends on the Acrobat version with which the file is opened. However, the unscaled size "
        "of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want "
        "but it is usually best to preserve the aspect ratio and the icon must be placed fully "
        "inside the appearance template.");
    pdfWriteFTextW(pdf, taLeft, body);

    // ---------------------- Signature field appearance ----------------------
    SI32 sigField = pdfCreateSigField(pdf, "Signature", -1, 200.0, 500.0, 200.0, 80.0);
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

    pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Arial"), (TFStyle)(fsBold | fsUnderlined), 11.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(120,120,220));
    pdfWriteFTextExW(pdf, 50.0, 60.0, 150.0, -1.0, taCenter, (LWCHAR*)LUMAS_TEXT("Digitally signed by:"));
    pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Arial"), (TFStyle)(fsBold | fsItalic), 18.0, 1, cp1252);
    pdfSetFillColor(pdf, RGB(100,100,200));
    pdfWriteFTextExW(pdf, 50.0, 45.0, 150.0, -1.0, taCenter, (LWCHAR*)LUMAS_TEXT("LumasPDF"));

    pdfEndTemplate(pdf);                 // Close the appearance template.
    // ------------------------------------------------------------------------

    pdfEndPage(pdf);

    const char* outFile = "out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileW(pdf, (LWCHAR*)W(outFile).c_str()) == 0){ pdfDeletePDF(pdf); return 0; }
    }
    if(pdfCloseAndSignFile(pdf, "test_cert.pfx", "123456", "Test", "") != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
