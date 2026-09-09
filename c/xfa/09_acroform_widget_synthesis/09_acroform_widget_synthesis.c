/* 09_acroform_widget_synthesis -- C port of examples\delphi\xfa\09_acroform_widget_synthesis
   XFA "flavor tour" example 9 of 10 -- ACROFORM-WIDGET SYNTHESIS.
   Demonstrates pdfSetXFARenderMode(doc, 1): turning an XFA form into a REAL
   fillable AcroForm PDF (textEdit/numericEdit/dateTimeEdit -> /FT Tx;
   checkButton exclGroup -> one /FT Btn radio group; choiceList -> /FT Ch;
   button -> /FT Btn pushbutton with a real bevel /AP).

   Renders the SAME 09_acroform_widget_synthesis.xdp packets TWICE through
   the exact real-DLL public export sequence every other example in this
   tour uses:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(doc,1) only
     for the second pass] -> pdfRenderXFAForm -> pdfCloseFile

       mode0.pdf -- Mode 0 (default): flattened ink only, no /AcroForm
       mode1.pdf -- Mode 1: flattened ink PLUS real synthesized AcroForm
                    fillable widgets (/AcroForm/Fields)

   Mirrors 09_acroform_widget_synthesis.dpr's call sequence exactly,
   including calling pdfSetXFARenderMode ONLY on the second (mode=1) pass so
   the first pass genuinely exercises the untouched default path. Does not
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

/* Mode: 0 = flatten-to-ink only (default, no pdfSetXFARenderMode call at
   all -- exercises the untouched default path); 1 = also synthesize real
   AcroForm fillable widgets. Re-reads the packet files fresh for each pass
   (a fresh PPDF needs its own XFA streams). */
static SI32 RenderExample(const char* dir, const char* outPath, SI32 mode)
{
    char templatePath[1100], datasetsPath[1100];
    void *templateBuf, *datasetsBuf;
    long templateLen = 0, datasetsLen = 0;
    PPDF pdf;
    SI32 idx, rc, prev;

    printf("=== 09_acroform_widget_synthesis (mode=%d) -> %s ===\n", mode, outPath);

    _snprintf(templatePath, sizeof(templatePath), "%s\\09_acroform_widget_synthesis.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\09_acroform_widget_synthesis.datasets.xml", dir);

    templateBuf = ReadWholeFile(templatePath, &templateLen);
    if (!templateBuf) { printf("FILE-NOT-FOUND: %s\n", templatePath); return -1; }
    datasetsBuf = ReadWholeFile(datasetsPath, &datasetsLen);
    if (!datasetsBuf) { printf("FILE-NOT-FOUND: %s\n", datasetsPath); free(templateBuf); return -1; }

    printf("template packet bytes: %ld\n", templateLen);
    printf("datasets packet bytes: %ld\n", datasetsLen);

    pdf = pdfNewPDF();
    if (!pdf) { printf("pdfNewPDF FAILED\n"); free(templateBuf); free(datasetsBuf); return -1; }
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    if (!pdfCreateNewPDFA(pdf, outPath)) {
        printf("pdfCreateNewPDFA FAILED\n");
        pdfDeletePDF(pdf); free(templateBuf); free(datasetsBuf); return -1;
    }

    idx = pdfCreateXFAStreamA(pdf, "template", templateBuf, (UI32)templateLen);
    printf("pdfCreateXFAStreamA(template) -> index %d\n", idx);
    if (idx < 0) { pdfDeletePDF(pdf); free(templateBuf); free(datasetsBuf); return -1; }

    idx = pdfCreateXFAStreamA(pdf, "datasets", datasetsBuf, (UI32)datasetsLen);
    printf("pdfCreateXFAStreamA(datasets) -> index %d\n", idx);
    if (idx < 0) { pdfDeletePDF(pdf); free(templateBuf); free(datasetsBuf); return -1; }

    if (mode != 0) {
        prev = pdfSetXFARenderMode(pdf, mode);
        printf("pdfSetXFARenderMode(PDF, %d) -> previous=%d (expect 0, the default)\n", mode, prev);
    }

    rc = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d (expected: page count >= 1)\n", rc);
    if (rc < 1) {
        printf("RENDER-FAILED, code %d\n", rc);
        pdfDeletePDF(pdf); free(templateBuf); free(datasetsBuf); return rc;
    }

    if (!pdfCloseFile(pdf)) {
        printf("pdfCloseFile FAILED\n");
        pdfDeletePDF(pdf); free(templateBuf); free(datasetsBuf); return -1;
    }
    printf("OK: wrote %s (%d page(s))\n", outPath, rc);

    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);
    return rc;
}

int main(int argc, char** argv)
{
    char dir[1024], mode0Path[1100], mode1Path[1100];
    SI32 r0, r1;

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(mode0Path, sizeof(mode0Path), "%s\\mode0.pdf", dir);
    _snprintf(mode1Path, sizeof(mode1Path), "%s\\mode1.pdf", dir);

    r0 = RenderExample(dir, mode0Path, 0);
    printf("\n");
    r1 = RenderExample(dir, mode1Path, 1);

    printf("\nRESULT|mode0=%d|mode1=%d\n", r0, r1);
    if (r0 >= 1 && r1 >= 1) {
        printf("OK: both renders succeeded.\n");
        printf("  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.\n");
        printf("  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm:\n");
        printf("    ApplicantName (Tx), YearsExperience (Tx), ApplicationDate (Tx),\n");
        printf("    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract),\n");
        printf("    Department (Ch combo, 6 options), SubmitButton (Btn pushbutton, real bevel /AP),\n");
        printf("    Employer[0].EmployerName / Employer[1].EmployerName / Employer[2].EmployerName (Tx x3).\n");
        printf("  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --\n");
        printf("  it is a genuinely fillable form: click into the fields and type.\n");
        return 0;
    }
    printf("FAILED, see errors above.\n");
    return 1;
}
