// 04_bands -- C++ port of examples\Vb6\reporting\04_bands.bas
#include "rptcommon.h"

static std::string BuildCsv() {
    std::string sb = "grp,item,val\n";
    char buf[128];
    for (int g = 1; g <= 3; ++g)
        for (int r = 1; r <= 30; ++r) {
            snprintf(buf, sizeof(buf), "Group-%d,Item %d-%02d,%d\n", g, g, r, g * 100 + r);
            sb += buf;
        }
    return sb;
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Csv = "04_data.csv";
    const char* Lrpt = "04_report.lrpt";
    const char* OutPdf = "04_out.pdf";
    WriteText(Csv, BuildCsv());
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"BandsDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + std::string(Csv) + "\"/></datasources>\n"
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
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    SI32 Pages;
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    Pages = rptGetPageCount(Job);
    printf("rendered %d page(s)\n", (int)Pages);
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    if (Pages < 2) printf("FAIL: expected >= 2 pages, got %d\n", (int)Pages);
    else printf("OK: multi-page grouped report with all band kinds\n");
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
