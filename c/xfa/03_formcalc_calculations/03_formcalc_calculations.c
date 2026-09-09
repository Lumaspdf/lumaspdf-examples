/* 03_formcalc_calculations -- C port of examples\delphi\xfa\03_formcalc_calculations
   XFA "flavor tour" example 3 of 10 -- FORMCALC CALCULATIONS: the full
   FormCalc lexer/parser/VM/38-builtin engine. Renders an "Order Calculator"
   order summary (customer/date header, 3-line item table, calculated
   summary block) wired up with <calculate><script
   contentType="application/x-formcalc"> bodies.

   Reads the pre-split packet files 03_formcalc_calculations.template.xml /
   03_formcalc_calculations.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

   Mirrors 03_formcalc_calculations.dpr's call sequence exactly. Does not
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

    printf("LumasPDF XFA flavor tour -- example 3/10: FormCalc Calculations\n");
    printf("(Sum/Avg/Round/Count, If, Concat/Upper/Left, Date2Num/Num2Date/DateFmt)\n\n");

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\03_formcalc_calculations.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\03_formcalc_calculations.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\03_formcalc_calculations.render.pdf", dir);

    printf("=== 03_formcalc_calculations (pre-split packets) -> 03_formcalc_calculations.render.pdf ===\n");

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

    printf("\nRESULT|03_formcalc_calculations=%d\n", rc);
    printf("Expected checklist (see README.md, hand-verified vs. rendered text):\n");
    printf("  Item1Total=37.5  Item2Total=90  Item3Total=40\n");
    printf("  TotalQty=10  Subtotal=167.5  AvgUnitPrice=21.83  ItemCount=3\n");
    printf("  DiscountLabel=\"Bulk Discount\"  DiscountAmount=16.75  GrandTotal=150.75\n");
    printf("  FullName=\"Alex Nguyen\"  CustomerInitial=\"A\"\n");
    printf("  OrderDateNum (rendered as date)=2026-07-15  OrderDateFormatted=7/15/26\n");
    return 0;
}
