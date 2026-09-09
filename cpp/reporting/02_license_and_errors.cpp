// 02_license_and_errors -- C++ port of examples\Vb6\reporting\02_license_and_errors.bas
#include "rptcommon.h"

static std::string FeaturesToStr(unsigned int F) {
    std::string r;
    if (F & RPT_FEAT_CORE) r += "CORE ";
    if (F & RPT_FEAT_EXPORT_PDF) r += "PDF ";
    if (F & RPT_FEAT_EXPORT_WEB) r += "WEB ";
    if (F & RPT_FEAT_EXPORT_DATA) r += "DATA ";
    if (F & RPT_FEAT_PREVIEW) r += "PREVIEW ";
    if (F & RPT_FEAT_PRINT) r += "PRINT ";
    if (F & RPT_FEAT_PLUGINS) r += "PLUGINS ";
    while (!r.empty() && r.back() == ' ') r.pop_back();
    return r;
}

static SI32 LastErrorCode(TRPT Eng) {
    TRptErrorInfoC Info; memset(&Info, 0, sizeof(Info));
    if (rptGetLastError(Eng, &Info) != 0) return Info.Code;
    return 0;
}

static void ShowError(const char* Tag, TRPT Eng) {
    TRptErrorInfoC Info; memset(&Info, 0, sizeof(Info));
    if (rptGetLastError(Eng, &Info) != 0 && Info.Code != 0) {
        printf("  %s -> code %d  module=%s  location=%s  msg=%s\n",
               Tag, (int)Info.Code, TrimNull(Info.Module_), TrimNull(Info.Location), TrimNull(Info.Msg));
    } else {
        printf("  %s -> (no structured error reported)\n", Tag);
    }
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* GoodLrpt = "02_good.lrpt";
    const char* BadLrpt = "02_bad.lrpt";
    const char* OutPdf = "02_out.pdf";
    TRPTJOB Job;
    SI32 PrevCode;

    printf("== License info ==\n");
    TRptLicenseInfoC Info; memset(&Info, 0, sizeof(Info));
    Info.StructSize = sizeof(Info);
    if (rptGetLicenseInfo(mEng, &Info) != 0) {
        printf("  Edition  : %d\n", (int)Info.Edition);
        printf("  Features : $%08X (%s)\n", (unsigned)Info.Features, FeaturesToStr(Info.Features).c_str());
        printf("  LicClass : %d\n", (int)Info.LicClass);
        printf("  LockClass: %d\n", (int)Info.LockClass);
        if (Info.Expiry == 0) printf("  Expiry   : 0 (perpetual / unbound)\n");
        else printf("  Expiry   : %lld\n", (long long)Info.Expiry);
        printf("  Customer : %s\n", TrimNull(Info.Customer));
    } else {
        printf("  rptGetLicenseInfo failed\n");
        DumpRptError(mEng);
    }

    printf("== Deliberate errors ==\n");

    WriteText(BadLrpt, "this is not a report at all\n");
    Job = rptOpenReportA(mEng, BadLrpt);
    if (Job == 0) ShowError("open(not-XML .lrpt)", mEng);
    else { printf("  open(not-XML .lrpt) -> unexpectedly succeeded\n"); rptCloseReport(Job); }

    WriteText(BadLrpt, "<notreport><oops/></notreport>\n");
    Job = rptOpenReportA(mEng, BadLrpt);
    if (Job == 0) ShowError("open(wrong-root .lrpt)", mEng);
    else { printf("  open(wrong-root .lrpt) -> unexpectedly succeeded\n"); rptCloseReport(Job); }

    PrevCode = LastErrorCode(mEng);
    if (rptRender(nullptr) != 0) printf("  rptRender(nil) -> unexpectedly succeeded\n");
    else if (LastErrorCode(mEng) == PrevCode) printf("  rptRender(nil) -> returned False; no new engine error (last code still %d)\n", (int)PrevCode);
    else ShowError("rptRender(nil)", mEng);

    PrevCode = LastErrorCode(mEng);
    if (rptExportA(nullptr, RPT_EXP_PDF, OutPdf) != 0) printf("  rptExportA(nil) -> unexpectedly succeeded\n");
    else if (LastErrorCode(mEng) == PrevCode) printf("  rptExportA(nil) -> returned False; no new engine error (last code still %d)\n", (int)PrevCode);
    else ShowError("rptExportA(nil)", mEng);

    printf("== Valid render ==\n");
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"LicDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"16\">\n"
        "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">License &amp; error demo</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
    WriteText(GoodLrpt, Xml);
    Job = rptOpenReportA(mEng, GoodLrpt);
    if (Job == 0) { printf("  open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("  render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("  rendered %d page(s)\n", (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("  export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("  wrote %s\n", OutPdf);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
