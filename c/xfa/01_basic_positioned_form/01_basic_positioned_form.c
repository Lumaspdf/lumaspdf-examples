/* 01_basic_positioned_form -- C port of examples\delphi\xfa\01_basic_positioned_form
   XFA "flavor tour" example 1 of 10: POSITIONED LAYOUT -- every subform/
   draw/field carries layout="position" and an explicit x/y/w/h, with no
   flow, <occur> repetition, or pagination involved. Renders a single-page
   "Employee Information" HR form (masthead, five statically placed fields
   bound to an <xfa:datasets> packet, a photo-placeholder box).

   Reads the pre-split packet files 01_basic_positioned_form.template.xml /
   01_basic_positioned_form.datasets.xml (raw <template>/<xfa:datasets>
   subtree bytes, already extracted from the .xdp -- no XML parsing needed
   here) and renders them through the real LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 01_basic_positioned_form.dpr's call sequence exactly. Does not
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

/* Reads an entire file into a malloc'd buffer; *len receives its size.
   Returns NULL on failure. */
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
    _snprintf(templatePath, sizeof(templatePath), "%s\\01_basic_positioned_form.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\01_basic_positioned_form.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\output.pdf", dir);

    printf("=== 01_basic_positioned_form.xdp (pre-split packets) -> output.pdf ===\n");

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

    printf("\nRESULT|01_basic_positioned_form=%d\n", rc);
    printf("Expected checklist (see README.md / dataset):\n");
    printf("  Full Name:   Sarah J. Connor\n");
    printf("  Employee ID: EMP-10457\n");
    printf("  Department:  Engineering\n");
    printf("  Hire Date:   2021-03-15\n");
    printf("  Full-time:   checked (FullTime=1)\n");
    printf("  Page count:  1 (purely positioned layout, no flow/occur/pagination)\n");
    return 0;
}
