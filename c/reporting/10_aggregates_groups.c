/* LumasReport example 10 -- Aggregates + groups (C port). */
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

int main(void) {
    TRPTJOB job;
    char xml[3072];
    const char* csv = "10_data.csv";
    const char* lrpt = "10_groups.lrpt";
    const char* outPdf = "10_groups.pdf";
    const char* outTxt = "10_groups.txt";
    const char* csvData =
        "Cat,Item,Amount\n"
        "Fruit,Apple,10\n"
        "Fruit,Pear,7\n"
        "Fruit,Plum,5\n"
        "Dairy,Milk,4\n"
        "Dairy,Cheese,9\n"
        "Dairy,Butter,6\n"
        "Grain,Bread,3\n"
        "Grain,Rice,8\n"
        "Grain,Oats,2\n";

    if (!BootEngine()) return 1;

    WriteText(csv, csvData);
    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Groups\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"%s\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"10\"><text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\" wordWrap=\"0\">Grouped Catalog</text></band>\n"
        "  <band kind=\"groupheader\" name=\"gh\" group=\"d.Cat\" height=\"7\"><text name=\"g\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"12\" bold=\"1\" wordWrap=\"0\">Category: {{expr: d.Cat}}</text></band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"5\" data=\"d\"><text name=\"i\" x=\"6\" y=\"0\" w=\"110\" h=\"4\" fontSize=\"9\" wordWrap=\"0\">{{Item}}</text><text name=\"a\" x=\"118\" y=\"0\" w=\"26\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{Amount}}</text><text name=\"r\" x=\"148\" y=\"0\" w=\"30\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">[{{expr: SUM(Amount)}}]</text></band>\n"
        "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.Cat\" height=\"6\"><text name=\"gt\" x=\"4\" y=\"0\" w=\"176\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>\n"
        "  <band kind=\"summary\" name=\"sm\" height=\"8\"><text name=\"s\" x=\"4\" y=\"1\" w=\"176\" h=\"6\" fontSize=\"11\" bold=\"1\" wordWrap=\"0\">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>\n"
        " </bands>\n"
        "</report>\n", csv);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s), grouped by Cat with per-group + grand totals\n", rptGetPageCount(job));
    rptExportA(job, RPT_EXP_PDF, outPdf);
    rptExportA(job, RPT_EXP_TEXT, outTxt);
    printf("wrote %s  +  %s\n", outPdf, outTxt);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
