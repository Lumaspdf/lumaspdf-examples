/* LumasReport example 08 -- Custom in-memory data provider (C port). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

/* value kinds */
#define vkNull  0
#define vkBool  1
#define vkInt   2
#define vkFloat 3
#define vkDate  4
#define vkStr   5

static PPDF mPdf;
static TRPT mEng;

/* --- the in-memory table: 4 rows x 5 typed columns --- */
static int    mRowId[4]   = { 1, 2, 3, 4 };
static double mPrice[4]   = { 12.5, 9.99, 0.0, 47.75 };
static int    mActive[4]  = { 1, 0, 1, 1 };
static int    mHasNote[4] = { 1, 1, 0, 1 };
static char   mName[4][16] = { "Alpha", "Beta", "Gamma", "Delta" };
static char   mNote[4][16] = { "first", "second", "", "fourth" };

static const char* mFieldName[5] = { "Id", "Price", "Name", "Active", "Note" };
static int         mFieldKind[5] = { vkInt, vkFloat, vkStr, vkBool, vkStr };

static void WriteText(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (f) { fputs(content, f); fclose(f); }
}

static void DumpRptError(TRPT eng) {
    TRptErrorInfoC info;
    memset(&info, 0, sizeof(info));
    if (rptGetLastError(eng, &info) != 0 && info.Code != 0)
        printf("  ! rpt error %d [%.16s] at %.64s: %.256s\n", info.Code, info.Module_, info.Location, info.Msg);
}

static int BootEngine(void) {
    mPdf = pdfNewPDF();
    if (!mPdf) { printf("pdfNewPDF failed\n"); return 0; }
    pdfSetLicenseKey(mPdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY);
    mEng = rptCreateEngineA(mPdf, NULL);
    if (!mEng) { printf("rptCreateEngine failed:\n"); DumpRptError(0); return 0; }
    return 1;
}

/* --- provider callbacks (stdcall via PDF_CALL) --- */
static SI32 PDF_CALL MyOpen(void* U, char* Conn, char* Query, PRptCParam Params, SI32 NParams, void** Cursor) {
    int* p = (int*)malloc(sizeof(int));
    (void)U; (void)Conn; (void)Query; (void)Params; (void)NParams;
    if (!p) return -1;
    *p = -1;                 /* row index before first Fetch */
    *Cursor = p;
    return 0;
}

static SI32 PDF_CALL MyGetSchema(void* Cursor, PRptCFieldDef Fields, SI32 MaxFields) {
    int i, n = 5;
    (void)Cursor;
    if (n > MaxFields) n = MaxFields;
    for (i = 0; i < n; i++) {
        memset(&Fields[i], 0, sizeof(Fields[i]));
        strncpy(Fields[i].Name, mFieldName[i], sizeof(Fields[i].Name) - 1);
        Fields[i].Kind = mFieldKind[i];
    }
    return n;
}

static SI32 PDF_CALL MyFetch(void* Cursor) {
    int* p = (int*)Cursor;
    (*p)++;
    return (*p <= 3) ? 1 : 0;
}

static SI32 PDF_CALL MyGetVal(void* Cursor, SI32 Field, PRptCValue V) {
    int r = *(int*)Cursor;
    memset(V, 0, sizeof(*V));
    V->Kind = vkNull;
    switch (Field) {
        case 0: V->Kind = vkInt;   V->I = mRowId[r];  break;
        case 1: V->Kind = vkFloat; V->F = mPrice[r];  break;
        case 2: V->Kind = vkStr;   V->S = mName[r];   break;
        case 3: V->Kind = vkBool;  V->B = mActive[r]; break;
        case 4:
            if (!mHasNote[r]) V->Kind = vkNull;
            else { V->Kind = vkStr; V->S = mNote[r]; }
            break;
        default: V->Kind = vkNull; break;
    }
    return 0;
}

static void PDF_CALL MyClose(void* Cursor) {
    if (Cursor) free(Cursor);
}

int main(void) {
    TRPTJOB job;
    TRptProviderVTable vt;
    const char* lrpt = "08_custom.lrpt";
    const char* outPdf = "08_custom.pdf";
    const char* outTxt = "08_custom.txt";
    const char* xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"CustomProvider\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"mydata\" conn=\"\" query=\"\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"12\">\n"
        "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\" wordWrap=\"0\">Custom Provider - typed rows</text>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"7\">\n"
        "   <text name=\"h1\" x=\"0\"   y=\"0\" w=\"20\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Id</text>\n"
        "   <text name=\"h2\" x=\"22\"  y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Name</text>\n"
        "   <text name=\"h3\" x=\"64\"  y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Price</text>\n"
        "   <text name=\"h4\" x=\"98\"  y=\"0\" w=\"24\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Active</text>\n"
        "   <text name=\"h5\" x=\"126\" y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Note</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"20\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Id}}</text>\n"
        "   <text name=\"c2\" x=\"22\"  y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Name}}</text>\n"
        "   <text name=\"c3\" x=\"64\"  y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price) }}</text>\n"
        "   <text name=\"c4\" x=\"98\"  y=\"0\" w=\"24\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{expr: CSTR(Active) }}</text>\n"
        "   <text name=\"c5\" x=\"126\" y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{expr: IFNULL(Note, '(none)') }}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";

    if (!BootEngine()) return 1;

    memset(&vt, 0, sizeof(vt));
    vt.Open = MyOpen;
    vt.GetSchema = MyGetSchema;
    vt.Fetch = MyFetch;
    vt.GetVal = MyGetVal;
    vt.CloseC = MyClose;
    if (rptRegisterProvider(mEng, "mydata", &vt, 0) == 0) {
        printf("register provider failed\n"); DumpRptError(mEng); goto cleanup;
    }

    WriteText(lrpt, xml);
    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s) from the custom provider\n", rptGetPageCount(job));
    rptExportA(job, RPT_EXP_PDF, outPdf);
    rptExportA(job, RPT_EXP_TEXT, outTxt);
    printf("wrote %s  +  %s\n", outPdf, outTxt);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
