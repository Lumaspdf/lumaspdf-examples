// 10_aggregates_groups -- C++ port of examples\Vb6\reporting\10_aggregates_groups.bas
#include "rptcommon.h"

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Csv = "10_data.csv";
    const char* Lrpt = "10_groups.lrpt";
    const char* OutPdf = "10_groups.pdf";
    const char* OutTxt = "10_groups.txt";

    std::string CsvData =
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
    WriteText(Csv, CsvData);
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Groups\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + std::string(Csv) + "\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"10\"><text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\" wordWrap=\"0\">Grouped Catalog</text></band>\n"
        "  <band kind=\"groupheader\" name=\"gh\" group=\"d.Cat\" height=\"7\"><text name=\"g\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"12\" bold=\"1\" wordWrap=\"0\">Category: {{expr: d.Cat}}</text></band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"5\" data=\"d\"><text name=\"i\" x=\"6\" y=\"0\" w=\"110\" h=\"4\" fontSize=\"9\" wordWrap=\"0\">{{Item}}</text><text name=\"a\" x=\"118\" y=\"0\" w=\"26\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{Amount}}</text><text name=\"r\" x=\"148\" y=\"0\" w=\"30\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">[{{expr: SUM(Amount)}}]</text></band>\n"
        "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.Cat\" height=\"6\"><text name=\"gt\" x=\"4\" y=\"0\" w=\"176\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>\n"
        "  <band kind=\"summary\" name=\"sm\" height=\"8\"><text name=\"s\" x=\"4\" y=\"1\" w=\"176\" h=\"6\" fontSize=\"11\" bold=\"1\" wordWrap=\"0\">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>\n"
        " </bands>\n"
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s), grouped by Cat with per-group + grand totals\n", (int)rptGetPageCount(Job));
    rptExportA(Job, RPT_EXP_PDF, OutPdf);
    rptExportA(Job, RPT_EXP_TEXT, OutTxt);
    printf("wrote %s  +  %s\n", OutPdf, OutTxt);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
