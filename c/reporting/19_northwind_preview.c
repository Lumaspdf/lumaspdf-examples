/* LumasReport example 19 -- Step-by-step .lrpt bound to Northwind.mdb + preview (C port). */
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

#define MDB "E:\\LUMASPDFSDK\\wrappers\\vcl\\Examples\\Northwind.mdb"

static void WriteText(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (f) { fputs(content, f); fclose(f); }
}

static int FileExists(const char* path) {
    FILE* f = fopen(path, "rb");
    if (f) { fclose(f); return 1; }
    return 0;
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

/* x64 build -> use the ACE "(*.mdb, *.accdb)" driver. */
static const char* BuildReportXml(void) {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Northwind Catalog\" tagLangVersion=\"1\">\n"
        "  <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\"\n"
        "        marginRight=\"15\" marginBottom=\"15\"/>\n"
        "  <datasources>\n"
        "    <datasource alias=\"d\" provider=\"odbc\"\n"
        "      conn=\"Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" MDB ";\"\n"
        "      query=\"SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit, p.UnitPrice, p.UnitsInStock FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ORDER BY c.CategoryName, p.ProductName\"/>\n"
        "  </datasources>\n"
        "  <params>\n"
        "    <param name=\"Title\"   default=\"'Northwind Product Catalog'\"/>\n"
        "    <param name=\"Company\" default=\"'LumasPDF Trading Co.'\"/>\n"
        "  </params>\n"
        "  <styles>\n"
        "    <style name=\"Bar\"     backColor=\"005F3A1F\" borderWidth=\"0\"/>\n"
        "    <style name=\"GrpBar\"  backColor=\"002A170F\" borderWidth=\"0\"/>\n"
        "    <style name=\"Title\"   fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n"
        "    <style name=\"Sub\"     fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n"
        "    <style name=\"ColH\"    fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n"
        "    <style name=\"ColHR\"   fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n"
        "    <style name=\"Grp\"     fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n"
        "    <style name=\"Cell\"    fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" vAlign=\"1\"/>\n"
        "    <style name=\"CellR\"   fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" hAlign=\"2\" vAlign=\"1\"/>\n"
        "    <style name=\"Muted\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"008B7464\" vAlign=\"1\"/>\n"
        "    <style name=\"Sub L\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\"/>\n"
        "    <style name=\"SubR\"    fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\" hAlign=\"2\"/>\n"
        "    <style name=\"GTotL\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\"/>\n"
        "    <style name=\"GTotR\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\"/>\n"
        "    <style name=\"Foot\"    fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\"/>\n"
        "    <style name=\"FootR\"   fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\" hAlign=\"2\"/>\n"
        "  </styles>\n"
        "  <bands>\n"
        "    <band kind=\"reportheader\" name=\"rh\" height=\"26\">\n"
        "      <shape name=\"hbar\"  x=\"0\" y=\"0\" w=\"180\" h=\"18\" style=\"Bar\" shape=\"0\"/>\n"
        "      <text  name=\"ttl\"   x=\"5\"  y=\"1\"  w=\"120\" h=\"10\" style=\"Title\" wordWrap=\"0\">{{var:Title}}</text>\n"
        "      <text  name=\"sub\"   x=\"95\" y=\"6\"  w=\"80\"  h=\"6\"  style=\"Sub\"   wordWrap=\"0\">{{var:Company}}</text>\n"
        "      <text  name=\"asof\"  x=\"0\"  y=\"20\" w=\"180\" h=\"4\"  style=\"Muted\" wordWrap=\"0\">Generated {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }} from Northwind.mdb (live ODBC)</text>\n"
        "    </band>\n"
        "    <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "      <shape name=\"cbar\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n"
        "      <text name=\"hP\"  x=\"3\"   y=\"1.5\" w=\"64\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PRODUCT</text>\n"
        "      <text name=\"hK\"  x=\"69\"  y=\"1.5\" w=\"44\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PACK</text>\n"
        "      <text name=\"hU\"  x=\"114\" y=\"1.5\" w=\"21\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">PRICE</text>\n"
        "      <text name=\"hS\"  x=\"137\" y=\"1.5\" w=\"18\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">STOCK</text>\n"
        "      <text name=\"hV\"  x=\"157\" y=\"1.5\" w=\"20\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">VALUE</text>\n"
        "    </band>\n"
        "    <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"9\">\n"
        "      <shape name=\"gbar\" x=\"0\" y=\"1\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n"
        "      <text  name=\"gname\" x=\"4\" y=\"1.7\" w=\"140\" h=\"5\" style=\"Grp\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n"
        "    </band>\n"
        "    <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "      <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" shape=\"0\" backColor=\"00F9F5F1\" visible=\"RowNum % 2 = 0\"/>\n"
        "      <text name=\"cP\" x=\"3\"   y=\"1\" w=\"64\" h=\"4\" style=\"Cell\"  wordWrap=\"0\">{{ProductName}}</text>\n"
        "      <text name=\"cK\" x=\"69\"  y=\"1\" w=\"44\" h=\"4\" style=\"Muted\" wordWrap=\"0\">{{QuantityPerUnit}}</text>\n"
        "      <text name=\"cU\" x=\"114\" y=\"1\" w=\"21\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n"
        "      <text name=\"cS\" x=\"137\" y=\"1\" w=\"18\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{UnitsInStock}}</text>\n"
        "      <text name=\"cV\" x=\"157\" y=\"1\" w=\"20\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', UnitPrice*UnitsInStock) }}</text>\n"
        "      <line name=\"drow\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.15\" color=\"00E2D8CE\"/>\n"
        "    </band>\n"
        "    <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"7\">\n"
        "      <line name=\"gtop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.4\" color=\"005F3A1F\"/>\n"
        "      <text name=\"sl\" x=\"3\"   y=\"1.5\" w=\"110\" h=\"4\" style=\"Sub L\" wordWrap=\"0\">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>\n"
        "      <text name=\"sv\" x=\"137\" y=\"1.5\" w=\"40\"  h=\"4\" style=\"SubR\"  wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n"
        "    </band>\n"
        "    <band kind=\"summary\" name=\"sm\" height=\"16\">\n"
        "      <shape name=\"tbar\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" style=\"Bar\" shape=\"0\"/>\n"
        "      <text name=\"gl\" x=\"4\"   y=\"4.2\" w=\"120\" h=\"6\" style=\"GTotL\" wordWrap=\"0\">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>\n"
        "      <text name=\"gv\" x=\"120\" y=\"4.2\" w=\"56\"  h=\"6\" style=\"GTotR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n"
        "    </band>\n"
        "    <band kind=\"pagefooter\" name=\"pf\" height=\"9\">\n"
        "      <line name=\"ft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"00B9B9B9\"/>\n"
        "      <text name=\"fl\" x=\"0\"   y=\"2.5\" w=\"120\" h=\"4\" style=\"Foot\"  wordWrap=\"0\">{{var:Company}} -- confidential</text>\n"
        "      <text name=\"fr\" x=\"120\" y=\"2.5\" w=\"57\"  h=\"4\" style=\"FootR\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n"
        "    </band>\n"
        "  </bands>\n"
        "</report>\n";
}

static int IsHeadless(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++) {
        if (strstr(argv[i], "--headless") || strstr(argv[i], "--no-preview") || strstr(argv[i], "/headless"))
            return 1;
    }
    return 0;
}

int main(int argc, char** argv) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* lrpt = "19_northwind.lrpt";
    const char* outPdf = "19_northwind.pdf";
    const char* outTxt = "19_northwind.txt";
    const char* xml;
    int pages = 0;
    if (!FileExists(MDB)) { printf("Northwind.mdb not found: %s\n", MDB); return 0; }
    if (!BootEngine(&pdf, &eng)) return 1;

    xml = BuildReportXml();
    WriteText(lrpt, xml);
    printf("STEP 1-14: wrote %s (%d bytes)\n", lrpt, (int)strlen(xml));

    job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(eng); goto cleanup; }

    rptSetParamStr(job, "Title", "Northwind Product Catalog");
    rptSetParamStr(job, "Company", "LumasPDF Trading Co.");

    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    pages = rptGetPageCount(job);
    printf("RENDER: %d page(s) bound from Northwind.mdb\n", pages);

    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("pdf export failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("text export failed\n"); DumpRptError(eng); goto closejob; }
    printf("EXPORT: %s  +  %s\n", outPdf, outTxt);

    if (IsHeadless(argc, argv)) {
        printf("PREVIEW: skipped (--headless). Open %s to view.\n", outPdf);
    } else {
        printf("PREVIEW: opening the embedded viewer -- close the window to continue...\n");
        if (rptPreviewA(job, "Northwind Product Catalog") == 0) {
            printf("  preview failed (continuing -- not fatal):\n");
            DumpRptError(eng);
        }
    }
closejob:
    rptCloseReport(job);

    if (FileExists(outPdf) && pages >= 1)
        printf("OK: %s exists, %d page(s).\n", outPdf, pages);
    else
        printf("VERIFY FAILED: PDF missing or zero pages\n");
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}
