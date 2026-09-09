/* LumasReport example 07 -- JSON and XML data providers (C port). */
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

static int RunReport(const char* tag, const char* xml) {
    TRPTJOB job;
    char lrpt[64], outPdf[64], outTxt[64];
    snprintf(lrpt, sizeof(lrpt), "07_%s.lrpt", tag);
    snprintf(outPdf, sizeof(outPdf), "07_%s.pdf", tag);
    snprintf(outTxt, sizeof(outTxt), "07_%s.txt", tag);
    WriteText(lrpt, xml);
    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("%s: open failed\n", tag); DumpRptError(mEng); return 0; }
    if (rptRender(job) == 0) { printf("%s: render failed\n", tag); DumpRptError(mEng); rptCloseReport(job); return 0; }
    printf("%s: rendered %d page(s)\n", tag, rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("%s: pdf export failed\n", tag); DumpRptError(mEng); rptCloseReport(job); return 0; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("%s: text export failed\n", tag); DumpRptError(mEng); rptCloseReport(job); return 0; }
    printf("wrote %s + %s\n", outPdf, outTxt);
    rptCloseReport(job);
    return 1;
}

int main(void) {
    char xml[2048];
    const char* jsn = "07_data.json";
    const char* xm = "07_data.xml";
    const char* jsonData = "[{\"City\":\"Paris\",\"Country\":\"FR\",\"Pop\":2100},{\"City\":\"Lyon\",\"Country\":\"FR\",\"Pop\":515},{\"City\":\"Nice\",\"Country\":\"FR\",\"Pop\":340}]";
    const char* xmlData =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<rows>\n"
        " <row City=\"Berlin\" Country=\"DE\" Pop=\"3600\"/>\n"
        " <row City=\"Munich\" Country=\"DE\" Pop=\"1500\"/>\n"
        " <row City=\"Hamburg\" Country=\"DE\" Pop=\"1900\"/>\n"
        "</rows>\n";

    if (!BootEngine()) return 1;

    WriteText(jsn, jsonData);
    WriteText(xm, xmlData);

    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"JsonCities\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"j\" provider=\"json\" conn=\"%s\" query=\"\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"10\">\n"
        "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Cities (JSON source)</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"jd\" height=\"6\" data=\"j\">\n"
        "   <text name=\"c1\" x=\"0\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{j.City}}</text>\n"
        "   <text name=\"c2\" x=\"60\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{j.Country}}</text>\n"
        "   <text name=\"c3\" x=\"90\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{j.Pop}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", jsn);
    if (!RunReport("json", xml)) goto cleanup;

    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"XmlCities\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"x\" provider=\"xml\" conn=\"%s\" query=\"rows/row\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"10\">\n"
        "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Cities (XML source)</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"xd\" height=\"6\" data=\"x\">\n"
        "   <text name=\"c1\" x=\"0\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{x.City}}</text>\n"
        "   <text name=\"c2\" x=\"60\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{x.Country}}</text>\n"
        "   <text name=\"c3\" x=\"90\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{x.Pop}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", xm);
    if (!RunReport("xml", xml)) goto cleanup;
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
