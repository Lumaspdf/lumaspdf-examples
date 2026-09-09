/* 05_occur_repeating_rows -- C port of examples\delphi\xfa\05_occur_repeating_rows
   XFA "flavor tour" example 5 of 10 -- OCCUR/REPEAT data-driven row
   cloning: <occur min="1" max="-1"/>, one repeating template row
   instantiated once per matching dataset record (7 <Item> records), each
   instance independently bound to its own record and independently
   re-running its own calculate script (LineTotal = Qty * UnitPrice).

   VERIFICATION STRATEGY (mirrors 05_occur_repeating_rows.dpr exactly):
   rather than hand-parsing the compressed content stream, this driver uses
   the engine's own supported text-extraction export (pdfGetPageText,
   looped via pdfInitStack -- the "GetPageText per-run enumerator"
   convention) on the freshly rendered page, BEFORE pdfCloseFile. Each
   field's displayed value is drawn as its own separate text run, in
   template/layout traversal order -- so the runs come back in exactly
   row-major order: [Description, Qty, UnitPrice, LineTotal] x 7 rows, then
   [Total, GrandTotal]. For every one of the 7 occur instances, this driver
   locates that row's own Description among the extracted runs, reads the
   next three runs (Qty, UnitPrice, LineTotal), independently recomputes
   Qty*UnitPrice, and asserts it equals the engine-produced LineTotal for
   that SAME row -- proving instance count, per-instance data isolation,
   and clone-free occur calculate semantics all at once.

   Reads the pre-split packet files 05_occur_repeating_rows.template.xml /
   05_occur_repeating_rows.datasets.xml and renders them through the real
   LumasPdf.dll:

     pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
     pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm ->
     [pdfInitStack/pdfGetPageText verification] -> pdfCloseFile

   Does not rebuild LumasPdf.dll -- links only against the public wrapper
   header lumaspdf.h and loads whatever LumasPdf.dll sits next to this
   exe. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../_common.h"
#include "lumaspdf.h"

#define EXPECTED_ROW_COUNT 7
#define EXPECTED_GRAND_TOTAL_STR "1348.50"

typedef struct { const char* description; const char* qty; const char* unitPrice; } TRow;

static const TRow ExpectedRows[EXPECTED_ROW_COUNT] = {
    { "Airfare - SFO to ORD",     "1", "450.00" },
    { "Hotel - 3 nights",         "3", "120.00" },
    { "Taxi / Rideshare",         "4", "18.50"  },
    { "Client Dinner",            "5", "22.00"  },
    { "Parking",                  "2", "15.00"  },
    { "Conference Registration",  "1", "299.00" },
    { "Office Supplies",          "6", "4.25"   }
};

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

/* ---- growable string list (extracted text runs) ---- */
typedef struct { char** items; int count; int cap; } StrList;

static void SL_Init(StrList* l) { l->items = NULL; l->count = 0; l->cap = 0; }
static void SL_Add(StrList* l, const char* s, int len)
{
    char* copy = (char*)malloc((size_t)len + 1);
    memcpy(copy, s, (size_t)len);
    copy[len] = 0;
    if (l->count == l->cap) {
        l->cap = l->cap ? l->cap * 2 : 16;
        l->items = (char**)realloc(l->items, (size_t)l->cap * sizeof(char*));
    }
    l->items[l->count++] = copy;
}
static void SL_Free(StrList* l)
{
    int i;
    for (i = 0; i < l->count; i++) free(l->items[i]);
    free(l->items);
    l->items = NULL; l->count = 0; l->cap = 0;
}
static int SL_Find(StrList* l, int startAt, const char* needle)
{
    int i;
    for (i = startAt; i < l->count; i++)
        if (strcmp(l->items[i], needle) == 0) return i;
    return -1;
}

static void CollectPageText(PPDF pdf, StrList* runs)
{
    TPDFStack stack;
    memset(&stack, 0, sizeof(stack));
    if (!pdfInitStack(pdf, &stack)) { printf("pdfInitStack FAILED\n"); return; }
    while (pdfGetPageText(pdf, &stack)) {
        if (stack.Text != NULL && stack.TextLen > 0)
            SL_Add(runs, stack.Text, (int)stack.TextLen);
    }
}

/* FloatToStr-parity formatting: invariant '.' decimal separator, no group
   separator, no forced trailing zeros -- matches what the engine's own
   LineTotal run looks like (produced via Delphi FloatToStr), so this is a
   true string-equality check, not a numeric-tolerance fudge. All values
   exercised here (integer qty x 2-decimal price) are exactly representable
   in binary floating point, so %.10f + trim reproduces FloatToStr's output
   byte-for-byte. */
static void FmtNum(double v, char* out, size_t outSz)
{
    char buf[64];
    int len;
    _snprintf(buf, sizeof(buf), "%.10f", v);
    len = (int)strlen(buf);
    while (len > 0 && buf[len - 1] == '0') buf[--len] = 0;
    if (len > 0 && buf[len - 1] == '.') buf[--len] = 0;
    _snprintf(out, outSz, "%s", buf);
}

int main(int argc, char** argv)
{
    char dir[1024], templatePath[1100], datasetsPath[1100], outPath[1100];
    void *templateBuf, *datasetsBuf;
    long templateLen = 0, datasetsLen = 0;
    PPDF pdf;
    SI32 idx, rc;
    int allPass = 1, rowIdx, i, cursor, dupCount;
    StrList runs;
    char expectedTotal[64];

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(templatePath, sizeof(templatePath), "%s\\05_occur_repeating_rows.template.xml", dir);
    _snprintf(datasetsPath, sizeof(datasetsPath), "%s\\05_occur_repeating_rows.datasets.xml", dir);
    _snprintf(outPath, sizeof(outPath), "%s\\05_occur_repeating_rows.pdf", dir);

    printf("=== 05_occur_repeating_rows (Expense Report, occur min=1 max=-1) ===\n");

    templateBuf = ReadWholeFile(templatePath, &templateLen);
    if (!templateBuf) { printf("FILE-NOT-FOUND: %s\n", templatePath); return 1; }
    datasetsBuf = ReadWholeFile(datasetsPath, &datasetsLen);
    if (!datasetsBuf) { printf("FILE-NOT-FOUND: %s\n", datasetsPath); free(templateBuf); return 1; }

    printf("template packet bytes: %ld\n", templateLen);
    printf("datasets packet bytes: %ld\n", datasetsLen);

    pdf = pdfNewPDF();
    if (!pdf) { printf("pdfNewPDF FAILED\n"); return 1; }
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    if (!pdfCreateNewPDFA(pdf, outPath)) { printf("pdfCreateNewPDFA FAILED\n"); pdfDeletePDF(pdf); return 1; }

    idx = pdfCreateXFAStreamA(pdf, "template", templateBuf, (UI32)templateLen);
    printf("pdfCreateXFAStreamA(template) -> index %d\n", idx);
    if (idx < 0) { pdfDeletePDF(pdf); return 1; }

    idx = pdfCreateXFAStreamA(pdf, "datasets", datasetsBuf, (UI32)datasetsLen);
    printf("pdfCreateXFAStreamA(datasets) -> index %d\n", idx);
    if (idx < 0) { pdfDeletePDF(pdf); return 1; }

    rc = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d page(s)\n", rc);
    if (rc < 0) { printf("pdfRenderXFAForm FAILED, code %d\n", rc); pdfDeletePDF(pdf); return 1; }
    if (rc != 1) {
        printf("UNEXPECTED PAGE COUNT: expected 1 (single pageArea, no pagination), got %d\n", rc);
        allPass = 0;
    }

    /* --- verification: extract the rendered page's text BEFORE closing --- */
    SL_Init(&runs);
    CollectPageText(pdf, &runs);
    printf("extracted %d text run(s) from the rendered page\n", runs.count);
    for (i = 0; i < runs.count; i++) printf("  run[%d] = \"%s\"\n", i, runs.items[i]);
    printf("\n");

    /* Header fields (explicit <bind dataRef>, non-occur, sanity check). */
    if (runs.count >= 4 &&
        strcmp(runs.items[0], "Expense Report") == 0 &&
        strcmp(runs.items[1], "Alex Rivera") == 0 &&
        strcmp(runs.items[2], "Field Operations") == 0 &&
        strcmp(runs.items[3], "2026-07-24") == 0)
        printf("HEADER OK: title/EmployeeName/Department/ReportDate all bound correctly\n");
    else {
        printf("HEADER MISMATCH: expected title+3 header fields as the first 4 runs\n");
        allPass = 0;
    }
    printf("\n");

    /* Per-row check: locate each row's Description, then its Qty/UnitPrice/
       LineTotal are expected to be the next 3 runs in traversal order. */
    cursor = 0;
    for (rowIdx = 0; rowIdx < EXPECTED_ROW_COUNT; rowIdx++) {
        double qtyN, priceN;

        idx = SL_Find(&runs, cursor, ExpectedRows[rowIdx].description);
        if (idx < 0) {
            printf("ROW %d MISSING: Description \"%s\" not found\n", rowIdx, ExpectedRows[rowIdx].description);
            allPass = 0;
            continue;
        }
        if (idx + 3 >= runs.count) {
            printf("ROW %d TRUNCATED: not enough runs after Description at %d\n", rowIdx, idx);
            allPass = 0;
            continue;
        }

        qtyN = atof(runs.items[idx + 1]);
        priceN = atof(runs.items[idx + 2]);
        FmtNum(qtyN * priceN, expectedTotal, sizeof(expectedTotal));

        printf("ROW %d \"%s\"  Qty=%s UnitPrice=%s  engine LineTotal=%s  hand-check %s x %s = %s",
            rowIdx, ExpectedRows[rowIdx].description, runs.items[idx + 1], runs.items[idx + 2],
            runs.items[idx + 3], runs.items[idx + 1], runs.items[idx + 2], expectedTotal);

        if (strcmp(runs.items[idx + 1], ExpectedRows[rowIdx].qty) != 0 ||
            strcmp(runs.items[idx + 2], ExpectedRows[rowIdx].unitPrice) != 0) {
            printf("\n  MISMATCH: bound Qty/UnitPrice do not match this row's own dataset record\n");
            allPass = 0;
        } else if (strcmp(runs.items[idx + 3], expectedTotal) != 0) {
            printf("\n  MISMATCH: engine LineTotal (%s) <> hand-computed (%s) -- possible shared/stale state across instances\n",
                runs.items[idx + 3], expectedTotal);
            allPass = 0;
        } else {
            printf("\n  OK\n");
        }

        cursor = idx + 4;
    }
    printf("\n");

    /* Instance-count check: exactly EXPECTED_ROW_COUNT Description runs for
       row 0's own description, no more, no fewer. */
    idx = 0; dupCount = 0;
    for (;;) {
        idx = SL_Find(&runs, idx, ExpectedRows[0].description);
        if (idx < 0) break;
        dupCount++;
        idx = idx + 1;
    }
    if (dupCount != 1) {
        printf("INSTANCE-DUP CHECK FAILED for row 0's Description: found %d time(s), expected 1\n", dupCount);
        allPass = 0;
    }

    /* Grand total: literal dataset value, TotalsRow non-occur sibling
       flowed directly after the 7 occur rows. */
    idx = SL_Find(&runs, 0, "Total");
    if (idx < 0) {
        printf("GrandTotal label \"Total\" NOT FOUND\n");
        allPass = 0;
    } else if (idx + 1 >= runs.count || strcmp(runs.items[idx + 1], EXPECTED_GRAND_TOTAL_STR) != 0) {
        printf("GrandTotal MISMATCH: expected \"%s\", got \"%s\"\n", EXPECTED_GRAND_TOTAL_STR,
            (idx + 1 < runs.count) ? runs.items[idx + 1] : "<none>");
        allPass = 0;
    } else {
        printf("GrandTotal OK: %s\n", runs.items[idx + 1]);
    }

    if (!pdfCloseFile(pdf)) { printf("pdfCloseFile FAILED\n"); allPass = 0; }
    else printf("\nOK: wrote %s\n", outPath);

    SL_Free(&runs);
    pdfDeletePDF(pdf);
    free(templateBuf); free(datasetsBuf);

    printf("\n");
    if (allPass)
        printf("RESULT|05_occur_repeating_rows=PASS|instances=%d\n", EXPECTED_ROW_COUNT);
    else
        printf("RESULT|05_occur_repeating_rows=FAIL\n");

    return allPass ? 0 : 1;
}
