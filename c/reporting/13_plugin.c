/* LumasReport example 13 -- Register a custom function + custom exporter
 * DIRECTLY (native function pointers) instead of loading an external plugin
 * DLL. The engine now exports rptRegisterFunctionA / rptRegisterExporter, so
 * no rpt_testplugin.dll (nor rptLoadPlugin) is needed -- everything lives in
 * this single process against the single LumasPdf.dll.
 *
 *   PlugDouble(x)  ->  x * 2     (accepts an int or a float)   [expr function]
 *   exporter target 100  ->  writes a marker string to a file  [custom target]
 *
 * The report calls {{expr: PlugDouble(21)}} (-> 42) and PlugDouble(2.5) (-> 5).
 * After exporting PDF/TXT we invoke the custom exporter via rptExport(job,100,..).
 */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

/* ---- Custom expression function: PlugDouble(x) = x * 2 (stdcall ABI) ------- */
static int __stdcall PlugDouble(void* User, TRptCValue* Args, int NArgs, TRptCValue* ResultV) {
    (void)User;
    if (NArgs != 1) return -1;
    switch (Args[0].Kind) {
        case 2: /* vkInt   */ ResultV->Kind = 2; ResultV->I = Args[0].I * 2;     break;
        case 3: /* vkFloat */ ResultV->Kind = 3; ResultV->F = Args[0].F * 2.0;   break;
        default: return -2;
    }
    return 0;
}

/* ---- Custom exporter for target id 100 (stdcall ABI) ---------------------- */
static int __stdcall PlugExport(void* User, void* Job, const char* Path) {
    FILE* f;
    (void)User; (void)Job;
    if (!Path) return -1;
    f = fopen(Path, "wb");
    if (!f) return -1;
    fputs("PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)", f);
    fclose(f);
    return 0;
}

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

static int BootEngine(PPDF* pdf, TRPT* eng) {
    *pdf = pdfNewPDF();
    if (!*pdf) { printf("pdfNewPDF failed\n"); return 0; }
    pdfSetLicenseKey(*pdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(*pdf, RPT_DEMO_KEY);
    *eng = rptCreateEngineA(*pdf, NULL);
    if (!*eng) { printf("rptCreateEngine failed\n"); return 0; }
    return 1;
}

static const char* BuildXml(void) {
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

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* lrpt = "13_plugin.lrpt";
    const char* outPdf = "13_plugin.pdf";
    const char* outTxt = "13_plugin.txt";
    const char* outCustom = "13_custom.out";
    if (!BootEngine(&pdf, &eng)) return 1;

    /* Register the custom function + exporter DIRECTLY -- BEFORE opening. */
    if (rptRegisterFunctionA(eng, "PlugDouble", 1, 1, (void*)&PlugDouble, NULL) == 0) {
        printf("rptRegisterFunction failed\n"); DumpRptError(eng); goto cleanup;
    }
    if (rptRegisterExporter(eng, 100, (void*)&PlugExport, NULL) == 0) {
        printf("rptRegisterExporter failed\n"); DumpRptError(eng); goto cleanup;
    }
    printf("registered function PlugDouble(x)=x*2 and exporter target 100 (no plugin DLL)\n");

    WriteText(lrpt, BuildXml());
    job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(eng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("export PDF failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("export TEXT failed\n"); DumpRptError(eng); goto closejob; }
    /* Invoke the custom exporter (target 100). */
    if (rptExportA(job, 100, outCustom) == 0) { printf("custom export failed\n"); DumpRptError(eng); goto closejob; }
    printf("wrote %s\n", outPdf);
    printf("wrote %s (via custom exporter)\n", outCustom);
    printf("OK\n");
closejob:
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}
