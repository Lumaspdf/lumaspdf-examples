// checkconformance -- C++ port of examples\Vb6\pdfa_extension\checkconformance\checkconformance.bas
// Imports a PDF and converts it to PDF/A-3b via CheckConformance, using callbacks to
// replace missing fonts and ICC profiles, then writes the result.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const char* ICC_RGB  = LUMAS_REPO_ROOT "/sample_rgb.icc";
static const char* ICC_CMYK = LUMAS_REPO_ROOT "/sample_rgb.icc";
static const char* ICC_GRAY = LUMAS_REPO_ROOT "/sample_gray.icc";
static const char* INPUT    = LUMAS_REPO_ROOT "/sample_multipage.pdf";

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

// Data is the PDF handle passed as UserData to CheckConformance.
static SI32 PDF_CALL FontNotFoundProc(void* Data, void* PDFFont, const char* FontName, TFStyle Style, SI32 StdFontIndex, LBOOL IsSymbolFont){
    return pdfReplaceFontA((PPDF)Data, PDFFont, "Arial", (SI32)Style, 1);
}

static SI32 PDF_CALL ReplaceICCProfileProc(void* Data, TICCProfileType ProfileType, SI32 ColorSpace){
    switch(ProfileType){
        case ictRGB:  return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, ICC_RGB);
        case ictCMYK: return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, ICC_CMYK);
        default:      return pdfReplaceICCProfileA((PPDF)Data, ColorSpace, ICC_GRAY);
    }
}

static bool ConvertFile(PPDF pdf, SI32 convType, const char* inFile, const char* outFile){
    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");

    UI32 convFlags;
    switch(convType){
        case ctNormalize:      convFlags = coAllowDeviceSpaces; break;
        case ctPDFA_1b_2005:   convFlags = coDefault | coFlattenLayers; break;
        case ctPDFA_2b:
        case ctPDFA_2u:        convFlags = coDefault | coDeletePresentation; break;
        default:               convFlags = (coDefault | coDeletePresentation) & ~coDeleteEmbeddedFiles; break;
    }
    convFlags |= coCheckImages;
    convFlags |= coRepairDamagedImages;

    if(convType != ctNormalize){
        pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage | ifPrepareForPDFA);
        pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck);
    } else {
        pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
        pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck | if2Normalize);
    }

    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){
        printf("Could not open the import file (it may be encrypted)!\n");
        pdfFreePDF(pdf);
        return false;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    SI32 retval = pdfCheckConformance(pdf, convType, convFlags, pdf, FontNotFoundProc, ReplaceICCProfileProc);
    switch(retval){
        case 1: pdfAddOutputIntentA(pdf, ICC_RGB);  break;
        case 2: pdfAddOutputIntentA(pdf, ICC_CMYK); break;
        case 3: pdfAddOutputIntentA(pdf, ICC_GRAY); break;
    }

    TPDFError e{};
    e.StructSize = sizeof(e);
    for(SI32 i = 0; i < pdfGetErrLogMessageCount(pdf); ++i){
        pdfGetErrLogMessage(pdf, i, &e);
        if(e.Msg) printf("%s\n", e.Msg);
    }

    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile) == 0) return false;
        return pdfCloseFile(pdf) != 0;
    }
    return false;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(pdf, cmapDir.c_str(), lcmDelayed | lcmRecursive);
    std::string filePath = exeDir(argv[0]) + "/out.pdf";

    if(ConvertFile(pdf, ctPDFA_3b, INPUT, filePath.c_str()))
        printf("PDF file \"%s\" successfully created!\n", filePath.c_str());

    pdfDeletePDF(pdf);
    return 0;
}
