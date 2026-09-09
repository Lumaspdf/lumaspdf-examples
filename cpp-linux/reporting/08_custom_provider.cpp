// 08_custom_provider -- C++ port of examples\Vb6\reporting\08_custom_provider.bas
// The VB6 original hand-marshals the provider vtable; in C++ we fill the real
// TRptProviderVTable struct with PDF_CALL callbacks over an in-memory table.
#include "rptcommon.h"
#include <cstdlib>

enum { vkNull = 0, vkBool = 1, vkInt = 2, vkFloat = 3, vkDate = 4, vkStr = 5 };

// 4 rows x 5 typed columns.
static long   gRowId[4]  = { 1, 2, 3, 4 };
static double gPrice[4]  = { 12.5, 9.99, 0.0, 47.75 };
static long   gActive[4] = { 1, 0, 1, 1 };
static bool   gHasNote[4] = { true, true, false, true };
static const char* gName[4] = { "Alpha", "Beta", "Gamma", "Delta" };
static const char* gNote[4] = { "first", "second", "", "fourth" };
static const char* gFieldName[5] = { "Id", "Price", "Name", "Active", "Note" };
static SI32 gFieldKind[5] = { vkInt, vkFloat, vkStr, vkBool, vkStr };

static SI32 PDF_CALL MyOpen(void* U, char* Conn, char* Query, PRptCParam Params, SI32 NParams, void** Cursor) {
    int* p = (int*)malloc(sizeof(int));
    *p = -1;
    *Cursor = p;
    return 0;
}
static SI32 PDF_CALL MyGetSchema(void* Cursor, PRptCFieldDef Fields, SI32 MaxFields) {
    SI32 n = 5;
    if (n > MaxFields) n = MaxFields;
    for (SI32 i = 0; i < n; ++i) {
        memset(&Fields[i], 0, sizeof(TRptCFieldDef));
        strncpy(Fields[i].Name, gFieldName[i], 63);
        Fields[i].Kind = gFieldKind[i];
    }
    return n;
}
static SI32 PDF_CALL MyFetch(void* Cursor) {
    int* r = (int*)Cursor;
    (*r)++;
    return (*r <= 3) ? 1 : 0;
}
static SI32 PDF_CALL MyGetVal(void* Cursor, SI32 Field, PRptCValue V) {
    int r = *(int*)Cursor;
    TRptCValue cv; memset(&cv, 0, sizeof(cv));
    cv.Kind = vkNull;
    switch (Field) {
        case 0: cv.Kind = vkInt;   cv.I = gRowId[r]; break;
        case 1: cv.Kind = vkFloat; cv.F = gPrice[r]; break;
        case 2: cv.Kind = vkStr;   cv.S = (char*)gName[r]; break;
        case 3: cv.Kind = vkBool;  cv.B = gActive[r]; break;
        case 4:
            if (!gHasNote[r]) cv.Kind = vkNull;
            else { cv.Kind = vkStr; cv.S = (char*)gNote[r]; }
            break;
        default: cv.Kind = vkNull; break;
    }
    *V = cv;
    return 0;
}
static void PDF_CALL MyClose(void* Cursor) {
    if (Cursor) free(Cursor);
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    TRptProviderVTable VT; memset(&VT, 0, sizeof(VT));
    VT.Open = MyOpen;
    VT.GetSchema = MyGetSchema;
    VT.Fetch = MyFetch;
    VT.GetVal = MyGetVal;
    VT.CloseC = MyClose;
    if (rptRegisterProvider(mEng, "mydata", &VT, nullptr) == 0) {
        printf("register provider failed\n"); DumpRptError(mEng); goto Cleanup;
    }

    {
    const char* Lrpt = "08_custom.lrpt";
    const char* OutPdf = "08_custom.pdf";
    const char* OutTxt = "08_custom.txt";
    std::string Xml =
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
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s) from the custom provider\n", (int)rptGetPageCount(Job));
    rptExportA(Job, RPT_EXP_PDF, OutPdf);
    rptExportA(Job, RPT_EXP_TEXT, OutTxt);
    printf("wrote %s  +  %s\n", OutPdf, OutTxt);
    rptCloseReport(Job);
    }
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
