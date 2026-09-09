// 07_data_json_xml -- C++ port of examples\Vb6\reporting\07_data_json_xml.bas
#include "rptcommon.h"

static bool RunReport(const char* Tag, const std::string& Xml) {
    std::string Lrpt = std::string("07_") + Tag + ".lrpt";
    std::string OutPdf = std::string("07_") + Tag + ".pdf";
    std::string OutTxt = std::string("07_") + Tag + ".txt";
    WriteText(Lrpt.c_str(), Xml);
    TRPTJOB Job = rptOpenReportA(mEng, Lrpt.c_str());
    if (Job == 0) { printf("%s: open failed\n", Tag); DumpRptError(mEng); return false; }
    if (rptRender(Job) == 0) { printf("%s: render failed\n", Tag); DumpRptError(mEng); rptCloseReport(Job); return false; }
    printf("%s: rendered %d page(s)\n", Tag, (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf.c_str()) == 0) { printf("%s: pdf export failed\n", Tag); DumpRptError(mEng); rptCloseReport(Job); return false; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt.c_str()) == 0) { printf("%s: text export failed\n", Tag); DumpRptError(mEng); rptCloseReport(Job); return false; }
    printf("wrote %s + %s\n", OutPdf.c_str(), OutTxt.c_str());
    rptCloseReport(Job);
    return true;
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Jsn = "07_data.json";
    const char* Xm = "07_data.xml";
    std::string JsonData = "[{\"City\":\"Paris\",\"Country\":\"FR\",\"Pop\":2100},{\"City\":\"Lyon\",\"Country\":\"FR\",\"Pop\":515},{\"City\":\"Nice\",\"Country\":\"FR\",\"Pop\":340}]";
    WriteText(Jsn, JsonData);
    std::string XmlData =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<rows>\n"
        " <row City=\"Berlin\" Country=\"DE\" Pop=\"3600\"/>\n"
        " <row City=\"Munich\" Country=\"DE\" Pop=\"1500\"/>\n"
        " <row City=\"Hamburg\" Country=\"DE\" Pop=\"1900\"/>\n"
        "</rows>\n";
    WriteText(Xm, XmlData);

    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"JsonCities\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"j\" provider=\"json\" conn=\"" + std::string(Jsn) + "\" query=\"\"/></datasources>\n"
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
        "</report>\n";
    if (!RunReport("json", Xml)) goto Cleanup;

    Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"XmlCities\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"x\" provider=\"xml\" conn=\"" + std::string(Xm) + "\" query=\"rows/row\"/></datasources>\n"
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
        "</report>\n";
    if (!RunReport("xml", Xml)) goto Cleanup;
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
