/* LumasReport example 12 -- Custom expression function GREET (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

#define VK_INT 2
#define VK_STR 5

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

/* Backing store for the string handed back to the engine (must outlive return). */
static char gResult[256];

/* GREET(name) -> 'Hello, <name>!'  Matches the C user-function ABI (stdcall). */
static SI32 PDF_CALL GreetFn(void* User, PRptCValue Args, SI32 NArgs, PRptCValue Result) {
    char argStr[128];
    (void)User;
    if (NArgs != 1 || Args == 0 || Result == 0) return -1;
    if (Args[0].Kind == VK_STR) {
        if (Args[0].S) { strncpy(argStr, Args[0].S, sizeof(argStr) - 1); argStr[sizeof(argStr) - 1] = 0; }
        else argStr[0] = 0;
    } else if (Args[0].Kind == VK_INT) {
        snprintf(argStr, sizeof(argStr), "%lld", (long long)Args[0].I);
    } else {
        return -2;
    }
    snprintf(gResult, sizeof(gResult), "Hello, %s!", argStr);
    memset(Result, 0, sizeof(*Result));
    Result->Kind = VK_STR;
    Result->S = gResult;
    return 0;
}

static const char* BuildXml(void) {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"CustomFn\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"24\">\n"
        "   <text name=\"g1\" x=\"0\" y=\"0\"  w=\"180\" h=\"8\" fontSize=\"16\">{{expr: GREET('World') }}</text>\n"
        "   <text name=\"g2\" x=\"0\" y=\"10\" w=\"180\" h=\"8\" fontSize=\"12\">{{expr: GREET('LumasReport') }}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* lrpt = "12_custom_function.lrpt";
    const char* outPdf = "12_custom_function.pdf";
    const char* outTxt = "12_custom_function.txt";
    if (!BootEngine(&pdf, &eng)) return 1;

    if (rptRegisterFunction(eng, "GREET", 1, 1, (void*)GreetFn, 0) == 0) {
        printf("rptRegisterFunction failed\n"); DumpRptError(eng); goto cleanup;
    }
    printf("registered custom function GREET/1\n");

    WriteText(lrpt, BuildXml());
    job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(eng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("export PDF failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("export TEXT failed\n"); DumpRptError(eng); goto closejob; }
    printf("wrote %s\n", outPdf);
    printf("OK\n");
closejob:
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}
