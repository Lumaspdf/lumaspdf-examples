/* LumasReport example 04 -- All band kinds, multi-page grouped (C port). */
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

static void BuildCsv(char* buf, size_t cap) {
    int g, r;
    size_t n = 0;
    n += (size_t)snprintf(buf + n, cap - n, "grp,item,val\n");
    for (g = 1; g <= 3; g++)
        for (r = 1; r <= 30; r++)
            n += (size_t)snprintf(buf + n, cap - n, "Group-%d,Item %d-%02d,%d\n", g, g, r, g * 100 + r);
}

int main(void) {
    TRPTJOB job;
    int pages;
    char csvData[8192];
    char xml[4096];
    const char* csv = "04_data.csv";
    const char* lrpt = "04_report.lrpt";
    const char* outPdf = "04_out.pdf";

    if (!BootEngine()) return 1;

    BuildCsv(csvData, sizeof(csvData));
    WriteText(csv, csvData);

    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"BandsDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"%s\"/></datasources>\n"
        " <styles>\n"
        "  <style name=\"Wm\"  fontSize=\"48\" bold=\"1\" textColor=\"00EEEEEE\" hAlign=\"1\" vAlign=\"1\"/>\n"
        "  <style name=\"Ov\"  fontSize=\"8\"  textColor=\"00B0B0B0\" hAlign=\"2\"/>\n"
        "  <style name=\"Grp\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" backColor=\"002A6099\" vAlign=\"1\"/>\n"
        " </styles>\n"
        " <bands>\n"
        "  <band kind=\"background\" name=\"bg\" height=\"297\">\n"
        "   <text name=\"wm\" x=\"20\" y=\"120\" w=\"150\" h=\"40\" style=\"Wm\" rotation=\"45\" wordWrap=\"0\">BACKGROUND</text>\n"
        "  </band>\n"
        "  <band kind=\"overlay\" name=\"ov\" height=\"297\">\n"
        "   <text name=\"ol\" x=\"0\" y=\"150\" w=\"180\" h=\"6\" style=\"Ov\" rotation=\"90\" wordWrap=\"0\">overlay band</text>\n"
        "  </band>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"16\">\n"
        "   <text name=\"rt\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">reportheader band</text>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "   <text name=\"pt\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"9\" wordWrap=\"0\">pageheader band - grp / item / val</text>\n"
        "  </band>\n"
        "  <band kind=\"groupheader\" name=\"gh\" group=\"d.grp\" height=\"8\">\n"
        "   <text name=\"gt\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"Grp\" wordWrap=\"0\">groupheader band: {{d.grp}}</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "   <text name=\"di\" x=\"4\"   y=\"0\" w=\"120\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">detail band: {{d.item}}</text>\n"
        "   <text name=\"dv\" x=\"130\" y=\"0\" w=\"46\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.val}}</text>\n"
        "  </band>\n"
        "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.grp\" height=\"7\">\n"
        "   <text name=\"ft\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"9\" italic=\"1\" wordWrap=\"0\">groupfooter band: end of {{d.grp}}</text>\n"
        "  </band>\n"
        "  <band kind=\"pagefooter\" name=\"pf\" height=\"7\">\n"
        "   <text name=\"pft\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"8\" hAlign=\"center\" wordWrap=\"0\">pagefooter band</text>\n"
        "  </band>\n"
        "  <band kind=\"summary\" name=\"sm\" height=\"16\">\n"
        "   <text name=\"st\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" fontSize=\"14\" hAlign=\"center\">summary band - report complete</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", csv);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    pages = rptGetPageCount(job);
    printf("rendered %d page(s)\n", pages);
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("wrote %s\n", outPdf);
    if (pages < 2) printf("FAIL: expected >= 2 pages, got %d\n", pages);
    else printf("OK: multi-page grouped report with all band kinds\n");
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
