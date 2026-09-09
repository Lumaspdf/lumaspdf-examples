/* 07_table_layout -- C port of examples\delphi\xfa\07_table_layout
   XFA "flavor tour" example 7 of 10 -- TABLE LAYOUT: layout="table", a
   4-column "Product Comparison Table" (columnWidths="216pt 108pt 108pt
   108pt") with a header row + 5 data rows, each column authoring a
   different <para hAlign> (left/right/center/right) rendered through the
   real TLumasPdfDoc.DrawTable primitive via RenderTableBox/RenderTableCell.

   Reads the pre-split packet files 07_table_layout.template.xml /
   07_table_layout.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 07_table_layout.dpr's call sequence exactly. Does not rebuild
   LumasPdf.dll -- links only against the public wrapper header lumaspdf.h
   and loads whatever LumasPdf.dll sits next to this exe. */
#include <stdio.h>
#include <stdlib.h>
#include "../../_common.h"
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return -1;
}

static void* ReadWholeFile(const char* path, long* len)
{
    FILE* f; void* buf; long sz;
    f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    buf = malloc(sz > 0 ? (size_t)sz : 1);
    if (!buf) { fclose(f); return NULL; }
    if (sz > 0 && fread(buf, 1, (size_t)sz, f) != (size_t)sz) { fclose(f); free(buf); return NULL; }
    fclose(f);
    *len = sz;
    return buf;
}

int main(int argc, char** argv)
{
    char dir[1024], templatePath[1100], datasetsPath[1100], outPath[1100];
    void *templateBuf, *datasetsBuf;
    long templateLen = 0, datasetsLen = 0;
    PPDF pdf;
    SI32 idx, rc;

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\07_table_layout.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\07_table_layout.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\07_table_layout.pdf", dir);

    printf("=== 07_table_layout (pre-split packets) -> 07_table_layout.pdf ===\n");

    templateBuf = ReadWholeFile(templatePath, &templateLen);
    if (!templateBuf) { printf("FILE-NOT-FOUND: %s\n", templatePath); return 1; }
    datasetsBuf = ReadWholeFile(datasetsPath, &datasetsLen);
    if (!datasetsBuf) { printf("FILE-NOT-FOUND: %s\n", datasetsPath); free(templateBuf); return 1; }

    printf("template packet bytes: %ld\n", templateLen);
    printf("datasets packet bytes: %ld\n", datasetsLen);

    pdf = pdfNewPDF();
    if (!pdf) { printf("pdfNewPDF FAILED\n"); return 1; }
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    if (!pdfCreateNewPDFA(pdf, outPath)) {
        printf("pdfCreateNewPDFA FAILED\n");
        pdfDeletePDF(pdf); return 1;
    }

    idx = pdfCreateXFAStreamA(pdf, "template", templateBuf, (UI32)templateLen);
    printf("pdfCreateXFAStreamA(template) -> index %d\n", idx);
    if (idx < 0) { printf("pdfCreateXFAStreamA(template) FAILED\n"); pdfDeletePDF(pdf); return 1; }

    idx = pdfCreateXFAStreamA(pdf, "datasets", datasetsBuf, (UI32)datasetsLen);
    printf("pdfCreateXFAStreamA(datasets) -> index %d\n", idx);
    if (idx < 0) { printf("pdfCreateXFAStreamA(datasets) FAILED\n"); pdfDeletePDF(pdf); return 1; }

    rc = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d\n", rc);
    if (rc < 1) { printf("pdfRenderXFAForm FAILED, code %d\n", rc); pdfDeletePDF(pdf); return 1; }

    if (!pdfCloseFile(pdf)) { printf("pdfCloseFile FAILED\n"); pdfDeletePDF(pdf); return 1; }
    printf("OK: wrote %s (%d page(s))\n", outPath, rc);

    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);

    printf("\nRESULT|07_table_layout=%d\n", rc);
    printf("Expected checklist (see README.md, hand-verified vs. pypdf-extracted x-offsets):\n");
    printf("  6 rows stack tb-style at y=688,668,648,628,608,588 (20pt steps)\n");
    printf("  Product column: hAlign=left   -> every row starts flush at x=39\n");
    printf("  Price column:   hAlign=right  -> every row ends at the same right edge (~357)\n");
    printf("  Stock column:   hAlign=center -> centered on x=414\n");
    printf("  Rating column:  hAlign=right  -> every row ends at the same right edge (~573)\n");
    printf("  Page count: 1\n");
    return 0;
}
