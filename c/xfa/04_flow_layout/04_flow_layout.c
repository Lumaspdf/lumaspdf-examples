/* 04_flow_layout -- C port of examples\delphi\xfa\04_flow_layout
   XFA "flavor tour" example 4 of 10 -- FLOW LAYOUT: layout="tb" vertical
   stacking (TermsPanel, 6 clauses) and layout="lr-tb" left-to-right
   wrapping (SkillsPanel, 9 tags wrapping across 3 lines), both flowed
   automatically by the layout engine with no fixed child positions.

   Reads the pre-split packet files 04_flow_layout.template.xml /
   04_flow_layout.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 04_flow_layout.dpr's call sequence exactly. Does not rebuild
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
    _snprintf(templatePath, sizeof(templatePath), "%s\\04_flow_layout.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\04_flow_layout.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\04_flow_layout.pdf", dir);

    printf("=== 04_flow_layout (pre-split packets) -> 04_flow_layout.pdf ===\n");

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

    printf("\nRESULT|04_flow_layout=%d\n", rc);
    printf("Expected checklist (see README.md, hand-computed vs. engine geometry dump):\n");
    printf("  TermsPanel (tb): 6 clauses stacked at y=92,116,140,164,188,212 (x=36, +24/step)\n");
    printf("  SkillsPanel (lr-tb): 9 tags wrap 4/4/1 across 3 lines\n");
    printf("    line1 y=270 x=36,146,256,366  line2 y=290 x=36,146,256,366  line3 y=310 x=36\n");
    printf("  Page count: 1\n");
    return 0;
}
