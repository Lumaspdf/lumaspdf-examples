/* merge_pdf -- C port of examples\Vb6\merge_pdf\merge_pdf.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

static const char* extract_filename(const char* path)
{
    const char* s = strrchr(path, '\\');
    if (!s) s = strrchr(path, '/');
    return s ? s + 1 : path;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    int i;
    SI32 destPage;
    int first, haveXFA, isCollection;
    char dir[1024], outFile[1100], files[2][1100];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 14.0, 0, cp1252);
        pdfWriteFTextExA(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taJustify,
            "The following pages were imported from different PDF files. LumasPDF adjusts the destinations of link annotations and bookmarks so that "
            "all destinations refer to the new page numbers after import.\r\r"
            "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number "
            "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().");
    pdfEndPage(pdf);

    first = 1;
    destPage = 1;
    haveXFA = 0;
    isCollection = 0;

    sprintf(files[0], "%s\\license.pdf", dir);
    sprintf(files[1], "%s\\sample_multipage.pdf", dir);

    for (i = 0; i < 2; i++) {
        if (pdfOpenImportFileA(pdf, files[i], ptOpen, "") < 0) { pdfDeletePDF(pdf); return 0; }
        if (first) {
            first = 0;
            haveXFA = (pdfGetInIsXFAForm(pdf) != 0);
            isCollection = (pdfGetInIsCollection(pdf) != 0);
            destPage = pdfImportPDFFile(pdf, destPage + 1, 1.0, 1.0);
            if (destPage < 0) break;
        } else {
            if (isCollection) {
                if (pdfGetInIsCollection(pdf) != 0) {
                    pdfSetImportFlags(pdf, ifEmbeddedFiles);
                    if (pdfImportCatalogObjects(pdf) == 0) break;
                } else {
                    pdfCloseImportFile(pdf);
                    pdfAttachFileA(pdf, files[i], extract_filename(files[i]), 1);
                }
            } else {
                if ((pdfGetInIsCollection(pdf) != 0) ||
                    (((pdfGetInIsXFAForm(pdf) != 0) || (pdfGetInFieldCount(pdf) > 0)) &&
                     ((pdfGetFieldCount(pdf) > 0) || haveXFA)))
                    break;
                pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
                pdfSetImportFlags2(pdf, if2UseProxy);
                destPage = pdfImportPDFFile(pdf, destPage + 1, 1.0, 1.0);
                if (destPage < 0) break;
            }
        }
        pdfCloseImportFile(pdf);
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }
    pdfDeletePDF(pdf);
    return 0;
}
