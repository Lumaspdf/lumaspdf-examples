/* 06_pagination_multipage -- C port of examples\delphi\xfa\06_pagination_multipage
   XFA "flavor tour" example 6 of 10 -- MULTI-PAGE PAGINATION:
   pageSet/pageArea/contentArea, forced overflow of a 70-row repeating
   table across several pages, leader/trailer "continued" banner subforms
   via <overflow leader=... trailer=...>.

   Reads the pre-split packet files 06_pagination_multipage.template.xml /
   06_pagination_multipage.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight)
     -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 06_pagination_multipage.dpr's call sequence exactly, including
   the pre-flight pdfXFAFormPageCount check asserted against the
   hand-derived expected page count of 4 (see README.md for the full
   greedy-simulation derivation: first page capacity 19 rows, each
   continuation page 18 rows, 19+18+18+15=70). Does not rebuild
   LumasPdf.dll -- links only against the public wrapper header lumaspdf.h
   and loads whatever LumasPdf.dll sits next to this exe. */
#include <stdio.h>
#include <stdlib.h>
#include "../../_common.h"
#include "lumaspdf.h"

#define EXPECTED_PAGE_COUNT 4

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
    SI32 idx, rc, pre;
    int allPass = 1;

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\06_pagination_multipage.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\06_pagination_multipage.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\06_pagination_multipage.pdf", dir);

    printf("=== 06_pagination_multipage (pre-split packets) -> 06_pagination_multipage.pdf ===\n");

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

    pre = pdfXFAFormPageCount(pdf);
    printf("pdfXFAFormPageCount (pre-flight, before any AppendPage) -> %d\n", pre);
    if (pre != EXPECTED_PAGE_COUNT) {
        printf("PAGECOUNT-MISMATCH: expected %d got %d\n", EXPECTED_PAGE_COUNT, pre);
        allPass = 0;
    }

    rc = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d\n", rc);
    if (rc < 1) { printf("pdfRenderXFAForm FAILED, code %d\n", rc); pdfDeletePDF(pdf); return 1; }
    if (rc != EXPECTED_PAGE_COUNT) {
        printf("RENDER-PAGECOUNT-MISMATCH: pre-flight said %d but render produced %d\n", EXPECTED_PAGE_COUNT, rc);
        allPass = 0;
    }

    if (!pdfCloseFile(pdf)) { printf("pdfCloseFile FAILED\n"); pdfDeletePDF(pdf); return 1; }
    printf("OK: wrote %s (%d page(s))\n", outPath, rc);

    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);

    printf("\nRESULT|06_pagination_multipage=%d|%s\n", rc, allPass ? "PASS" : "FAIL");
    printf("Expected checklist (see README.md):\n");
    printf("  Page 0: header yes, leader no,  trailer yes, 19 rows (1-19)\n");
    printf("  Page 1: header no,  leader yes, trailer yes, 18 rows (20-37)\n");
    printf("  Page 2: header no,  leader yes, trailer yes, 18 rows (38-55)\n");
    printf("  Page 3: header no,  leader yes, trailer no,  15 rows (56-70)\n");
    printf("  Total pages: 4  (19+18+18+15=70, matches the 70 authored <Line> records)\n");
    return allPass ? 0 : 1;
}
