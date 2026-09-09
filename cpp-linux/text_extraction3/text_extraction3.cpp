// text_extraction3 -- C++ port of examples\Vb6\text_extraction3\text_extraction3.bas
// Imports a PDF and extracts its text page by page with pdfExtractText, then
// writes the result to out.txt as UTF-16LE (with BOM).
#include "apputil.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

static FILE* g_File;

// UTF-16LE out.txt: the stride is sizeof(LWCHAR) (2 bytes everywhere), NOT
// sizeof(wchar_t) (4 off Windows). At the wrong stride the engine's 2-byte
// text was written past the end of its buffer -- half of every record was
// allocator debris -- and the file did not decode as the UTF-16LE its BOM
// declares. ASCII decorations are widened rather than built with swprintf,
// whose wchar_t is UTF-32 off Windows. See the LWCHAR note in lumaspdf.h.
static void WriteAscii(const char* s){
    if(!s) return;
    for(; *s; ++s){ LWCHAR u = (LWCHAR)(unsigned char)*s; fwrite(&u, sizeof(LWCHAR), 1, g_File); }
}
static void WritePageIdentifier(SI32 PageNum){
    char buf[128];
    if(PageNum > 1) WriteAscii("\r\n");
    int n = snprintf(buf, sizeof(buf), "%%----------------------- Page %d -----------------------------\r\n", (int)PageNum);
    if(n > 0) WriteAscii(buf);
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");            // We do not create a PDF file in this example

    pdfSetCMapDirA(pdf, "CMap", lcmRecursive | lcmDelayed);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    const char* inFile = "in.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        return 0;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfFlattenAnnots(pdf, affMarkupAnnots);
    pdfFlattenForm(pdf);

    g_File = fopen("out.txt", "wb");
    if(!g_File){ pdfDeletePDF(pdf); return 0; }
    unsigned char bom[2] = {0xFF, 0xFE};   // UTF-16LE BOM
    fwrite(bom, 1, 2, g_File);

    SI32 cnt = pdfGetPageCount(pdf);
    for(SI32 i = 1; i <= cnt; i++){
        WritePageIdentifier(i);
        LWCHAR* textPtr = nullptr;
        UI32 textLen = 0;
        // Not recommended to sort text on the y-axis; it sometimes causes strange results.
        if(pdfExtractText(pdf, (UI32)i, (TTextExtractionFlags)(tefDeleteOverlappingText | tefSortTextX), nullptr, &textPtr, &textLen) != 0){
            if(textLen > 0 && textPtr) fwrite(textPtr, sizeof(LWCHAR), textLen, g_File);
        }
    }
    fclose(g_File);

    printf("Text successfully extracted to out.txt\n");
    pdfDeletePDF(pdf);
    return 0;
}
