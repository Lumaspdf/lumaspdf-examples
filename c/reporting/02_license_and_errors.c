/* LumasReport example 02 -- License info + deliberate errors (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

static PPDF mPdf;
static TRPT mEng;

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

static void FeaturesToStr(unsigned int f, char* out) {
    out[0] = 0;
    if (f & RPT_FEAT_CORE) strcat(out, "CORE ");
    if (f & RPT_FEAT_EXPORT_PDF) strcat(out, "PDF ");
    if (f & RPT_FEAT_EXPORT_WEB) strcat(out, "WEB ");
    if (f & RPT_FEAT_EXPORT_DATA) strcat(out, "DATA ");
    if (f & RPT_FEAT_PREVIEW) strcat(out, "PREVIEW ");
    if (f & RPT_FEAT_PRINT) strcat(out, "PRINT ");
    if (f & RPT_FEAT_PLUGINS) strcat(out, "PLUGINS ");
    { size_t n = strlen(out); if (n && out[n-1] == ' ') out[n-1] = 0; }
}

static int LastErrorCode(TRPT eng) {
    TRptErrorInfoC info;
    memset(&info, 0, sizeof(info));
    if (rptGetLastError(eng, &info) != 0) return info.Code;
    return 0;
}

static void ShowError(const char* tag, TRPT eng) {
    TRptErrorInfoC info;
    memset(&info, 0, sizeof(info));
    if (rptGetLastError(eng, &info) != 0 && info.Code != 0)
        printf("  %s -> code %d  module=%.16s  location=%.64s  msg=%.256s\n",
               tag, info.Code, info.Module_, info.Location, info.Msg);
    else
        printf("  %s -> (no structured error reported)\n", tag);
}

int main(void) {
    TRPTJOB job;
    int prevCode;
    TRptLicenseInfoC info;
    char feat[128];
    const char* goodLrpt = "02_good.lrpt";
    const char* badLrpt = "02_bad.lrpt";
    const char* outPdf = "02_out.pdf";
    const char* xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"LicDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"16\">\n"
        "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">License &amp; error demo</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";

    if (!BootEngine()) return 1;

    printf("== License info ==\n");
    memset(&info, 0, sizeof(info));
    info.StructSize = (int)sizeof(info);
    if (rptGetLicenseInfo(mEng, &info) != 0) {
        FeaturesToStr(info.Features, feat);
        printf("  Edition  : %d\n", info.Edition);
        printf("  Features : $%08X (%s)\n", info.Features, feat);
        printf("  LicClass : %d\n", info.LicClass);
        printf("  LockClass: %d\n", info.LockClass);
        if (info.Expiry == 0) printf("  Expiry   : 0 (perpetual / unbound)\n");
        else printf("  Expiry   : %lld\n", (long long)info.Expiry);
        printf("  Customer : %.64s\n", info.Customer);
    } else {
        printf("  rptGetLicenseInfo failed\n");
        DumpRptError(mEng);
    }

    printf("== Deliberate errors ==\n");

    WriteText(badLrpt, "this is not a report at all\n");
    job = rptOpenReportA(mEng, badLrpt);
    if (!job) ShowError("open(not-XML .lrpt)", mEng);
    else { printf("  open(not-XML .lrpt) -> unexpectedly succeeded\n"); rptCloseReport(job); }

    WriteText(badLrpt, "<notreport><oops/></notreport>\n");
    job = rptOpenReportA(mEng, badLrpt);
    if (!job) ShowError("open(wrong-root .lrpt)", mEng);
    else { printf("  open(wrong-root .lrpt) -> unexpectedly succeeded\n"); rptCloseReport(job); }

    prevCode = LastErrorCode(mEng);
    if (rptRender(0) != 0) printf("  rptRender(nil) -> unexpectedly succeeded\n");
    else if (LastErrorCode(mEng) == prevCode) printf("  rptRender(nil) -> returned False; no new engine error (last code still %d)\n", prevCode);
    else ShowError("rptRender(nil)", mEng);

    prevCode = LastErrorCode(mEng);
    if (rptExportA(0, RPT_EXP_PDF, outPdf) != 0) printf("  rptExportA(nil) -> unexpectedly succeeded\n");
    else if (LastErrorCode(mEng) == prevCode) printf("  rptExportA(nil) -> returned False; no new engine error (last code still %d)\n", prevCode);
    else ShowError("rptExportA(nil)", mEng);

    printf("== Valid render ==\n");
    WriteText(goodLrpt, xml);
    job = rptOpenReportA(mEng, goodLrpt);
    if (!job) { printf("  open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("  render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("  rendered %d page(s)\n", rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("  export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("  wrote %s\n", outPdf);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
