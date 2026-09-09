// 05_elements -- C++ port of examples\Vb6\reporting\05_elements.bas
#include "rptcommon.h"
#include <vector>

static std::vector<unsigned char> gBmp;
static void PutB(long v) { gBmp.push_back((unsigned char)(v & 0xFF)); }
static void PutW(long v) { PutB(v & 0xFF); PutB((v >> 8) & 0xFF); }
static void PutD(long v) { PutB(v & 0xFF); PutB((v >> 8) & 0xFF); PutB((v >> 16) & 0xFF); PutB((v >> 24) & 0xFF); }

static void WriteBmp8x8(const char* Path) {
    gBmp.clear();
    // BITMAPFILEHEADER
    PutB('B'); PutB('M');
    PutD(54 + 192);
    PutD(0);
    PutD(54);
    // BITMAPINFOHEADER
    PutD(40);
    PutD(8); PutD(8);
    PutW(1);
    PutW(24);
    PutD(0);
    PutD(192);
    PutD(2835); PutD(2835);
    PutD(0); PutD(0);
    // pixels bottom-up BGR
    for (int Y = 0; Y < 8; ++Y)
        for (int X = 0; X < 8; ++X) {
            if (((X + Y) & 1) == 0) { PutB(0); PutB(0); PutB(255); }
            else { PutB(255); PutB(0); PutB(0); }
        }
    FILE* f = fopen(Path, "wb");
    if (f) { fwrite(gBmp.data(), 1, gBmp.size(), f); fclose(f); }
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Lrpt = "05_elements.lrpt";
    const char* Sub = "05_sub.lrpt";
    const char* Img = "05_img.bmp";
    const char* OutPdf = "05_elements.pdf";

    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Sub\" tagLangVersion=\"1\">\n"
        " <page width=\"70\" height=\"30\" marginLeft=\"1\" marginTop=\"1\" marginRight=\"1\" marginBottom=\"1\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"sh\" height=\"10\">\n"
        "   <text name=\"st\" x=\"0\" y=\"0\" w=\"66\" h=\"6\" fontSize=\"8\">Subreport content here.</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
    WriteText(Sub, Xml);
    WriteBmp8x8(Img);
    Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Elements\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"150\">\n"
        "   <text name=\"title\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">Every Element Kind</text>\n"
        "   <text name=\"note\"  x=\"0\" y=\"12\" w=\"180\" h=\"6\" fontSize=\"9\" hAlign=\"center\">text / line / shape / image / barcode / subreport</text>\n"
        "   <line  name=\"rule\" x=\"0\" y=\"20\" w=\"180\" h=\"0.3\" toX=\"180\" toY=\"0\"/>\n"
        "   <shape name=\"rect\" x=\"0\"  y=\"26\" w=\"55\" h=\"22\" shape=\"0\"/>\n"
        "   <shape name=\"rrct\" x=\"63\" y=\"26\" w=\"55\" h=\"22\" shape=\"1\"/>\n"
        "   <shape name=\"elps\" x=\"126\" y=\"26\" w=\"55\" h=\"22\" shape=\"2\"/>\n"
        "   <text name=\"l1\" x=\"0\"   y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=0 rect</text>\n"
        "   <text name=\"l2\" x=\"63\"  y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=1 roundrect</text>\n"
        "   <text name=\"l3\" x=\"126\" y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=2 ellipse</text>\n"
        "   <image name=\"pic\" x=\"0\" y=\"58\" w=\"24\" h=\"24\" source=\"" + std::string(Img) + "\" stretch=\"1\"/>\n"
        "   <text name=\"il\" x=\"0\" y=\"83\" w=\"40\" h=\"5\" fontSize=\"7\">8x8 BMP image</text>\n"
        "   <barcode name=\"qr\"  x=\"40\"  y=\"58\" w=\"24\" h=\"24\" type=\"0\" text=\"QR:LumasReport\"/>\n"
        "   <barcode name=\"pdf\" x=\"70\"  y=\"58\" w=\"40\" h=\"24\" type=\"1\" text=\"PDF417-DATA-001\"/>\n"
        "   <barcode name=\"dm\"  x=\"116\" y=\"58\" w=\"24\" h=\"24\" type=\"2\" text=\"DataMatrix99\"/>\n"
        "   <barcode name=\"az\"  x=\"146\" y=\"58\" w=\"24\" h=\"24\" type=\"3\" text=\"AZTEC-XYZ\"/>\n"
        "   <text name=\"bl\" x=\"40\" y=\"83\" w=\"140\" h=\"5\" fontSize=\"7\">barcodes: QR / PDF417 / DataMatrix / Aztec</text>\n"
        "   <subreport name=\"sub\" x=\"0\" y=\"92\" w=\"90\" h=\"30\" ref=\"05_sub.lrpt\"/>\n"
        "   <text name=\"sl\" x=\"0\" y=\"123\" w=\"120\" h=\"5\" fontSize=\"7\">^ subreport (05_sub.lrpt) merged above</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s)\n", (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
