// 12_custom_function -- C++ port of examples\Vb6\reporting\12_custom_function.bas
// Registers a C-implemented expression function GREET/1 matching the engine's
// user-function ABI: SI32 PDF_CALL(User, Args:PRptCValue, NArgs, ResultV:PRptCValue).
#include "rptcommon.h"

enum { VK_INT = 2, VK_STR = 5 };

// Backing store handed back to the engine; must outlive the callback return.
static std::string gResult;

static SI32 PDF_CALL GreetFn(void* User, PRptCValue Args, SI32 NArgs, PRptCValue ResultV) {
    if (NArgs != 1 || Args == nullptr || ResultV == nullptr) return -1;
    std::string ArgStr;
    if (Args[0].Kind == VK_STR) {
        if (Args[0].S) ArgStr = Args[0].S;
    } else if (Args[0].Kind == VK_INT) {
        char b[32]; snprintf(b, sizeof(b), "%lld", (long long)Args[0].I);
        ArgStr = b;
    } else {
        return -2;
    }
    gResult = "Hello, " + ArgStr + "!";
    ResultV->Kind = VK_STR;
    ResultV->S = (char*)gResult.c_str();
    return 0;
}

static std::string BuildXml() {
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

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    if (rptRegisterFunction(mEng, "GREET", 1, 1, (void*)GreetFn, nullptr) == 0) {
        printf("rptRegisterFunction failed\n"); DumpRptError(mEng); goto Cleanup;
    }
    printf("registered custom function GREET/1\n");

    {
    const char* Lrpt = "12_custom_function.lrpt";
    const char* OutPdf = "12_custom_function.pdf";
    const char* OutTxt = "12_custom_function.txt";
    WriteText(Lrpt, BuildXml());

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("export PDF failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("export TEXT failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    printf("OK\n");
    rptCloseReport(Job);
    }
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
