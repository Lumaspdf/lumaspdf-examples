/* 02_data_binding -- C port of examples\delphi\xfa\02_data_binding
   XFA "flavor tour" example 2 of 10 -- DATA BINDING: implicit by-name
   binding AND explicit <bind match="dataRef" ref="..."/> SOM path binding,
   plus a <bind match="none"/> literal, all against one realistic, genuinely
   nested <xfa:datasets> packet.

   Reads the pre-split packet files 02_data_binding.template.xml /
   02_data_binding.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 02_data_binding.dpr's call sequence exactly. Does not rebuild
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

    printf("LumasPDF XFA flavor tour -- example 2/10: Data Binding\n");
    printf("(implicit by-name + explicit dataRef SOM path + match=none literal)\n\n");

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\02_data_binding.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\02_data_binding.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\02_data_binding.render.pdf", dir);

    printf("=== 02_data_binding (pre-split packets) -> 02_data_binding.render.pdf ===\n");

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

    printf("\nRESULT|02_data_binding=%d\n", rc);
    printf("Expected checklist (see README.md) -- 8 values, all must resolve exactly:\n");
    printf("  Customer Name  (implicit)              : Acme Robotics LLC\n");
    printf("  Account ID     (implicit)               : ACCT-88213\n");
    printf("  Street         (implicit, nested)       : 500 Innovation Way\n");
    printf("  State          (implicit, nested)       : IL\n");
    printf("  Zip            (implicit, nested)       : 62704\n");
    printf("  Shipping City  (explicit dataRef, 3 deep): Springfield\n");
    printf("  Primary Contact Email (dataRef, 4 deep)  : ap@acmerobotics.example\n");
    printf("  Status (match=\"none\" literal)           : Active - Verified (NOT PENDING_CLOSURE)\n");
    return 0;
}
