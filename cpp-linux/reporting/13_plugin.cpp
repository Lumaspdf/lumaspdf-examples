// 13_plugin -- register a custom function + custom exporter DIRECTLY via
// native function pointers (rptRegisterFunctionA / rptRegisterExporter) instead
// of loading an external plugin DLL (rptLoadPlugin + rpt_testplugin.dll).
// Everything lives in this single process against the single LumasPdf.dll.
//
//   PlugDouble(x)  ->  x * 2     (accepts an int or a float)   [expr function]
//   exporter target 100  ->  writes a marker string to a file  [custom target]
#include "rptcommon.h"

// ---- Custom expression function: PlugDouble(x) = x * 2 (stdcall ABI) --------
static int PDF_CALL PlugDouble(void* User, TRptCValue* Args, int NArgs, TRptCValue* ResultV) {
    (void)User;
    if (NArgs != 1) return -1;
    switch (Args[0].Kind) {
        case 2: /* vkInt   */ ResultV->Kind = 2; ResultV->I = Args[0].I * 2;   break;
        case 3: /* vkFloat */ ResultV->Kind = 3; ResultV->F = Args[0].F * 2.0; break;
        default: return -2;
    }
    return 0;
}

// ---- Custom exporter for target id 100 (stdcall ABI) -----------------------
static int PDF_CALL PlugExport(void* User, void* Job, const char* Path) {
    (void)User; (void)Job;
    if (!Path) return -1;
    FILE* f = fopen(Path, "wb");
    if (!f) return -1;
    fputs("PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)", f);
    fclose(f);
    return 0;
}

static std::string BuildXml() {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Plugin\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"24\">\n"
        "   <text name=\"p1\" x=\"0\" y=\"0\"  w=\"180\" h=\"8\" fontSize=\"16\">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>\n"
        "   <text name=\"p2\" x=\"0\" y=\"10\" w=\"180\" h=\"8\" fontSize=\"12\">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    // Register the custom function + exporter DIRECTLY -- BEFORE opening.
    if (rptRegisterFunctionA(mEng, "PlugDouble", 1, 1, (void*)&PlugDouble, nullptr) == 0) {
        printf("rptRegisterFunction failed\n"); DumpRptError(mEng); goto Cleanup;
    }
    if (rptRegisterExporter(mEng, 100, (void*)&PlugExport, nullptr) == 0) {
        printf("rptRegisterExporter failed\n"); DumpRptError(mEng); goto Cleanup;
    }
    printf("registered function PlugDouble(x)=x*2 and exporter target 100 (no plugin DLL)\n");

    {
    const char* Lrpt = "13_plugin.lrpt";
    const char* OutPdf = "13_plugin.pdf";
    const char* OutTxt = "13_plugin.txt";
    const char* OutCustom = "13_custom.out";
    WriteText(Lrpt, BuildXml());

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("export PDF failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("export TEXT failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    // Invoke the custom exporter (target 100).
    if (rptExportA(Job, 100, OutCustom) == 0) { printf("custom export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    printf("wrote %s (via custom exporter)\n", OutCustom);
    printf("OK\n");
    rptCloseReport(Job);
    }
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
