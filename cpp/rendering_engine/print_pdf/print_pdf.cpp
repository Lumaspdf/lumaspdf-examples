// print_pdf -- C++ port of examples\Vb6\rendering_engine\print_pdf\print_pdf.bas
// Loads a PDF, imports the first page and prints it via the standard Print dialog.
// COMPILE-ONLY smoke target: running it opens the interactive Print dialog.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>

// Minimal Win32 print-dialog declarations. We cannot include <windows.h> because
// lumaspdf.h rolls its own HDC/HWND typedefs that would collide.
#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "gdi32.lib")

extern "C" {
    struct PRINTDLGA_ {
        unsigned int lStructSize;
        void* hwndOwner;
        void* hDevMode;
        void* hDevNames;
        void* hDC;
        unsigned int Flags;
        unsigned short nFromPage, nToPage, nMinPage, nMaxPage, nCopies;
        void* hInstance;
        void* lCustData;
        void* lpfnPrintHook;
        void* lpfnSetupHook;
        const char* lpPrintTemplateName;
        const char* lpSetupTemplateName;
        void* hPrintTemplate;
        void* hSetupTemplate;
    };
    __declspec(dllimport) int  PDF_CALL PrintDlgA(PRINTDLGA_* p);
    __declspec(dllimport) int  PDF_CALL DeleteDC(void* hdc);
}

static const unsigned int PD_RETURNDC = 0x100;
static const unsigned int PD_HIDEPRINTTOFILE = 0x100000;
static const unsigned int PD_DISABLEPRINTTOFILE = 0x80000;
static const unsigned int PD_NOSELECTION = 0x4;

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void* GetPrinterDC(){
    PRINTDLGA_ pd{};
    pd.lStructSize = sizeof(pd);
    pd.Flags = PD_RETURNDC | PD_HIDEPRINTTOFILE | PD_DISABLEPRINTTOFILE | PD_NOSELECTION;
    if(PrintDlgA(&pd) != 0) return pd.hDC;
    printf("Cancelled!\n");
    return nullptr;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if(pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_multipage.pdf", ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }

    pdfAppend(pdf);
        pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    pdfApplyAppEvent(pdf, aePrint, 0);

    void* dc = GetPrinterDC();
    if(dc){
        if(pdfPrintPDFFileA(pdf, "", "Test Print", (HDC)(size_t)dc,
               pffDefault | pffAutoRotateAndCenter | pffShrinkToPrintArea, nullptr, nullptr) != 0)
            printf("Page 1 successfully printed\n");
        DeleteDC(dc);
    }
    pdfDeletePDF(pdf);
    return 0;
}
