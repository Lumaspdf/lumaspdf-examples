/* print_pdf -- C port of examples\Vb6\rendering_engine\print_pdf\print_pdf.bas
 * Loads a PDF, imports the first page and prints it. A printer is chosen via
 * the standard Print dialog (PrintDlg), as the Delphi/VB6 original does.
 *
 * NOTE: this opens the Windows print dialog (needs a printer/UI) -> compile-only
 * in automated runs. lumaspdf.h typedefs HDC/HWND itself, so we do NOT include
 * <windows.h>; the few Win32 calls are declared locally (stdcall).
 */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"
#include "../../_common.h"

/* --- minimal local Win32 declarations (no windows.h; avoids HDC/HWND clash) --- */
typedef unsigned long  DWORD_;
typedef unsigned short WORD_;

typedef struct {
    DWORD_ lStructSize;
    void*  hwndOwner;
    void*  hDevMode;
    void*  hDevNames;
    void*  hDC;              /* returned printer DC */
    DWORD_ Flags;
    WORD_  nFromPage, nToPage, nMinPage, nMaxPage, nCopies;
    void*  hInstance;
    void*  lCustData;
    void*  lpfnPrintHook;
    void*  lpfnSetupHook;
    const char* lpPrintTemplateName;
    const char* lpSetupTemplateName;
    void*  hPrintTemplate;
    void*  hSetupTemplate;
} PRINTDLG_;

__declspec(dllimport) int   __stdcall PrintDlgA(PRINTDLG_* pPD);
__declspec(dllimport) int   __stdcall DeleteDC(void* hdc);

#define PD_RETURNDC          0x00000100u
#define PD_HIDEPRINTTOFILE   0x00100000u
#define PD_DISABLEPRINTTOFILE 0x00080000u
#define PD_NOSELECTION       0x00000004u

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void* GetPrinterDC(void)
{
    PRINTDLG_ pd;
    memset(&pd, 0, sizeof(pd));
    pd.lStructSize = sizeof(pd);
    pd.Flags = PD_RETURNDC | PD_HIDEPRINTTOFILE | PD_DISABLEPRINTTOFILE | PD_NOSELECTION;
    if (PrintDlgA(&pd)) return pd.hDC;
    printf("Cancelled!\n");
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    void* dc;
    (void)argc; (void)argv;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, "../../../../dynapdf_help.pdf", ptOpen, "") < 0) { pdfDeletePDF(pdf); return 1; }

    pdfAppend(pdf);
    pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    pdfApplyAppEvent(pdf, aePrint, 0);

    dc = GetPrinterDC();
    if (dc) {
        if (pdfPrintPDFFileA(pdf, "", "Test Print", (HDC)(size_t)dc,
                             pffDefault | pffAutoRotateAndCenter | pffShrinkToPrintArea, 0, 0))
            printf("Page 1 successfully printed\n");
        DeleteDC(dc);
    }
    pdfDeletePDF(pdf);
    return 0;
}
