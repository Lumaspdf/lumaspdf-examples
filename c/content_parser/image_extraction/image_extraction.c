/* ============================================================================
 *  image_extraction -- C (x64) port of the VB6 mirror
 *  examples\Vb6\content_parser\image_extraction\image_extraction.bas
 *  Imports sample_multipage.pdf and extracts every image into a multi-page TIFF by
 *  parsing each page's content stream. Templates and image objects are
 *  de-duplicated so each is handled once. The pdf handle is passed as the
 *  parser Data pointer.
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define IN_FILE "E:\\LUMASPDFSDK\\sample_multipage.pdf"

/* De-dup lists */
static void** g_Images = NULL;   static int g_ImgCount = 0, g_ImgCap = 0;
static SI32*  g_Templ  = NULL;   static int g_TemplCount = 0, g_TemplCap = 0;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage ? ErrMessage : "");
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

static int FindImg(void* v)
{
    int i;
    for (i = 0; i < g_ImgCount; i++) if (g_Images[i] == v) return i;
    return -1;
}
static void AddImg(void* v)
{
    if (g_ImgCount >= g_ImgCap) {
        g_ImgCap = g_ImgCap ? g_ImgCap * 2 : 1024;
        g_Images = (void**)realloc(g_Images, g_ImgCap * sizeof(void*));
    }
    g_Images[g_ImgCount++] = v;
}
static int FindTempl(SI32 v)
{
    int i;
    for (i = 0; i < g_TemplCount; i++) if (g_Templ[i] == v) return i;
    return -1;
}
static void AddTempl(SI32 v)
{
    if (g_TemplCount >= g_TemplCap) {
        g_TemplCap = g_TemplCap ? g_TemplCap * 2 : 1024;
        g_Templ = (SI32*)realloc(g_Templ, g_TemplCap * sizeof(SI32));
    }
    g_Templ[g_TemplCount++] = v;
}

/* ------------------------- parse callbacks ------------------------- */
static SI32 PDF_CALL parseBeginTemplate(void* Data, void* PDFObject, SI32 Handle,
                                        TPDFRect* BBox, PCTM Matrix)
{
    (void)Data; (void)PDFObject; (void)BBox; (void)Matrix;
    if (FindTempl(Handle) > -1)
        return 1;                /* Skip the template */
    AddTempl(Handle);
    return 0;
}

static SI32 PDF_CALL parseInsertImage(void* Data, TPDFImage* Image)
{
    if (Image->InlineImage == 0) {
        if (FindImg(Image->ObjectPtr) > -1) return 0;   /* Already handled */
        AddImg(Image->ObjectPtr);
    }
    /* If an image cannot be decompressed we can get a compressed image here. */
    if (Image->Filter != dfNone) return 0;
    if (Image->BitsPerPixel == 1)
        pdfAddImage((PPDF)Data, cfCCITT4, icNone, Image);
    else
        pdfAddImage((PPDF)Data, cfLZW, icNone, Image);
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    TPDFParseInterface stack;
    char dir[1024], outFile[1200];
    int i, pc;

    exedir(argv[0], dir, sizeof(dir));

    memset(&stack, 0, sizeof(stack));
    stack.BeginTemplate = parseBeginTemplate;
    stack.InsertImage   = parseInsertImage;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    /* We avoid the conversion of pages to templates */
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, IN_FILE, ptOpen, "") < 0) {
        printf("Input file \"sample_multipage.pdf\" not found!\n");
        pdfDeletePDF(pdf);
        return 0;
    }
    if (pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0) {
        pdfDeletePDF(pdf);
        return 0;
    }
    /* Flatten form fields so we can extract images of these objects too. */
    pdfFlattenForm(pdf);

    sprintf(outFile, "%s\\out.tif", dir);

    /* We create a multi-page TIFF in this example */
    if (pdfCreateImageA(pdf, outFile, ifmTIFF) == 0) {
        pdfDeletePDF(pdf);
        return 0;
    }
    pc = pdfGetPageCount(pdf);
    for (i = 1; i <= pc; i++) {
        pdfEditPage(pdf, i);
        /* The pdf handle is passed as the parser Data. */
        pdfParseContent(pdf, pdf, &stack, pfDecomprAllImages);
        pdfEndPage(pdf);
    }
    if (pdfCloseImage(pdf) != 0)
        printf("TIFF image \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}
