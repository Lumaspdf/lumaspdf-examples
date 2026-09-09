/* 10_javascript_scripting -- C port of examples\delphi\xfa\10_javascript_scripting
   XFA "flavor tour" example 10 of 10 -- JS-AS-XFA-SCRIPT. Demonstrates
   <script contentType="application/x-javascript"> calculate scripts (the
   this.rawValue getter/setter + xfa.resolveNode(path).rawValue bridge, via
   BESEN embedded in the engine) plugging into the SAME pdfRenderXFAForm
   pipeline FormCalc already uses -- no new export was needed for JS.

   Reads the pre-split packet files 10_javascript_scripting.template.xml /
   10_javascript_scripting.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 10_javascript_scripting.dpr's call sequence exactly. Does not
   rebuild LumasPdf.dll -- links only against the public wrapper header
   lumaspdf.h and loads whatever LumasPdf.dll sits next to this exe. */
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
    _snprintf(templatePath, sizeof(templatePath), "%s\\10_javascript_scripting.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\10_javascript_scripting.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\output.pdf", dir);

    printf("=== 10_javascript_scripting (pre-split packets) -> output.pdf ===\n");

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
    printf("pdfRenderXFAForm -> %d (expected: page count >= 1)\n", rc);
    if (rc < 1) { printf("RENDER-FAILED, code %d\n", rc); pdfDeletePDF(pdf); return 1; }

    if (!pdfCloseFile(pdf)) { printf("pdfCloseFile FAILED\n"); pdfDeletePDF(pdf); return 1; }
    printf("Wrote %s (%d page(s))\n", outPath, rc);

    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);

    if (rc >= 1)
        printf("OK: JavaScript-scripted form rendered, %d page(s). Open output.pdf and confirm:\n", rc);
    else
        printf("FAILED, see errors above.\n");
    printf("  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)\n");
    printf("  - OrderSummary      = \"Purchase Order PO-1042 for Acme Robotics\"\n");
    printf("  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)\n");
    printf("  If any of these are wrong or missing, the JS bridge contract in the .xdp\n");
    printf("  needs adjusting to match the FINAL implementation -- see the .xdp header comment.\n");

    printf("\nRESULT|10_javascript_scripting=%d\n", rc);
    return (rc >= 1) ? 0 : 1;
}
