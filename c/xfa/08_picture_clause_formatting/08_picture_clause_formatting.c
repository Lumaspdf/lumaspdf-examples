/* 08_picture_clause_formatting -- C port of examples\delphi\xfa\08_picture_clause_formatting
   XFA "flavor tour" example 8 of 10 -- PICTURE-CLAUSE FORMATTING: real
   num{}/date{}/text{} picture patterns applied both to plain bound data
   values and to a value produced by a FormCalc <calculate> script,
   proving the calculate-then-format pipeline order.

   Reads the pre-split packet files 08_picture_clause_formatting.template.xml
   / 08_picture_clause_formatting.datasets.xml and renders them through the
   real LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfSetXFAScriptEnabled(1) ->
     pdfRenderXFAForm -> pdfCloseFile

   Mirrors 08_picture_clause_formatting.dpr's call sequence exactly,
   including the explicit pdfSetXFAScriptEnabled(1) call before rendering
   (belt-and-braces -- the engine defaults this on already, but the driver
   sets it explicitly since GrandTotalField's <calculate> script is the
   whole point of this example). Does not rebuild LumasPdf.dll -- links
   only against the public wrapper header lumaspdf.h and loads whatever
   LumasPdf.dll sits next to this exe. */
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
    SI32 idx, rc, prevEnabled;

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\08_picture_clause_formatting.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\08_picture_clause_formatting.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\08_picture_clause_formatting.pdf", dir);

    printf("=== 08_picture_clause_formatting (pre-split packets) -> 08_picture_clause_formatting.pdf ===\n");

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

    prevEnabled = pdfSetXFAScriptEnabled(pdf, 1);
    printf("pdfSetXFAScriptEnabled(1) -> previous=%d\n", prevEnabled);

    rc = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d\n", rc);
    if (rc < 1) { printf("pdfRenderXFAForm FAILED, code %d\n", rc); pdfDeletePDF(pdf); return 1; }

    if (!pdfCloseFile(pdf)) { printf("pdfCloseFile FAILED\n"); pdfDeletePDF(pdf); return 1; }
    printf("OK: wrote %s (%d page(s))\n", outPath, rc);

    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);

    printf("\nRESULT|08_picture_clause_formatting=%d\n", rc);
    printf("Expected rendered text (see README.md):\n");
    printf("  Purchase Receipt -- Picture-Clause Formatting\n");
    printf("  Customer: Acme Corp\n");
    printf("  Unit Price: 1,875.50\n");
    printf("  Discount: ($125.00)\n");
    printf("  Date: July 24, 2026\n");
    printf("  Phone: 555-123-4567\n");
    printf("  845.25 620.00 410.25\n");
    printf("  Grand Total: 1,875.50   (calculate-then-format: Item1+Item2+Item3, THEN num{zzz,zz9.99})\n");
    return 0;
}
