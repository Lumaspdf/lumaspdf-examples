// checkconformance -- C++ port of examples\Vb6\pdfa_extension\checkconformance\checkconformance.bas
// Imports a PDF and converts it to PDF/A-3b via CheckConformance, using callbacks to
// replace missing fonts and ICC profiles, then writes the result.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString) everywhere, which
// binds to the WIDE overloads (pdfReplaceFontW, pdfReplaceICCProfileW, ...).
// This port used to call the ANSI twins, a different engine code path. Spelled
// with the header's own LUMAS_TEXT so it stays correct where LWCHAR is char16_t
// (Linux/macOS) as well as where it is wchar_t (Windows).
#define WROOT LUMAS_TEXT(LUMAS_REPO_ROOT)
static LWCHAR* const ICC_RGB  = (LWCHAR*)(WROOT LUMAS_TEXT("/examples/test_files/sRGB.icc"));
static LWCHAR* const ICC_CMYK = (LWCHAR*)(WROOT LUMAS_TEXT("/examples/test_files/ISOcoated_v2_bas.ICC"));
static LWCHAR* const ICC_GRAY = (LWCHAR*)(WROOT LUMAS_TEXT("/examples/test_files/gray.icc"));
static LWCHAR* const INPUT    = (LWCHAR*)(WROOT LUMAS_TEXT("/sample_multipage.pdf"));
// checkconformance.dpr: pdf.SetCMapDir(ExpandFileName('../../../../Resource/CMap'), ...)
// -- the repo-root Resource/CMap, NOT a CMap folder beside the exe (which does
// not exist, so this call was a silent no-op here and the reference's was not).
static LWCHAR* const CMAP_DIR = (LWCHAR*)(WROOT LUMAS_TEXT("/Resource/CMap"));

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }
// ASCII-only widener for the one path built at run time (the exe's own folder).
static std::basic_string<LWCHAR> widen(const std::string& s){
    std::basic_string<LWCHAR> w; w.reserve(s.size());
    for(unsigned char c : s) w.push_back((LWCHAR)c);
    return w;
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

// Data is the PDF handle passed as UserData to CheckConformance.
static SI32 PDF_CALL FontNotFoundProc(void* Data, void* PDFFont, const char* FontName, TFStyle Style, SI32 StdFontIndex, LBOOL IsSymbolFont){
    // checkconformance.dpr:31-34 -- weights below 500 are collapsed to Regular
    // before the substitute is chosen, so a Light/Thin source face is not
    // replaced by a bold-ish Arial. WeightFromStyle is pure bit extraction
    // (LumasPdf.pas:17249: (Style and $FFF00000) shr 20), no export needed.
    SI32 st = (SI32)Style;
    if((((UI32)st & 0xFFF00000u) >> 20) < 500) st = (st & 0x0F) | (SI32)fsRegular;
    return pdfReplaceFontW((PPDF)Data, PDFFont, (LWCHAR*)LUMAS_TEXT("Arial"), st, 1);
}

static SI32 PDF_CALL ReplaceICCProfileProc(void* Data, TICCProfileType ProfileType, SI32 ColorSpace){
    switch(ProfileType){
        case ictRGB:  return pdfReplaceICCProfileW((PPDF)Data, ColorSpace, ICC_RGB);
        case ictCMYK: return pdfReplaceICCProfileW((PPDF)Data, ColorSpace, ICC_CMYK);
        default:      return pdfReplaceICCProfileW((PPDF)Data, ColorSpace, ICC_GRAY);
    }
}

static bool ConvertFile(PPDF pdf, SI32 convType, LWCHAR* inFile, LWCHAR* outFile){
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetDocInfoW(pdf, diProducer, (LWCHAR*)LUMAS_TEXT(""));

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

    if(pdfOpenImportFileW(pdf, inFile, ptOpen, "") < 0){
        printf("Could not open the import file (it may be encrypted)!\n");
        pdfFreePDF(pdf);
        return false;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    SI32 retval = pdfCheckConformance(pdf, convType, convFlags, pdf, FontNotFoundProc, ReplaceICCProfileProc);
    switch(retval){
        case 1: pdfAddOutputIntentW(pdf, ICC_RGB);  break;
        case 2: pdfAddOutputIntentW(pdf, ICC_CMYK); break;
        case 3: pdfAddOutputIntentW(pdf, ICC_GRAY); break;
    }

    TPDFError e{};
    e.StructSize = sizeof(e);
    for(SI32 i = 0; i < pdfGetErrLogMessageCount(pdf); ++i){
        pdfGetErrLogMessage(pdf, i, &e);
        if(e.Msg) printf("%s\n", e.Msg);
    }

    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileW(pdf, outFile) == 0) return false;
        return pdfCloseFile(pdf) != 0;
    }
    return false;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    pdfSetCMapDirW(pdf, CMAP_DIR, lcmDelayed | lcmRecursive);
    std::string filePath = exeDir(argv[0]) + "/out.pdf";
    std::basic_string<LWCHAR> wFilePath = widen(filePath);

    if(ConvertFile(pdf, ctPDFA_3b, INPUT, &wFilePath[0]))
        printf("PDF file \"%s\" successfully created!\n", filePath.c_str());

    pdfDeletePDF(pdf);
    return 0;
}
