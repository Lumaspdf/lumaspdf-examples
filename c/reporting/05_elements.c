/* LumasReport example 05 -- Every element kind (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

static PPDF mPdf;
static TRPT mEng;

static unsigned char mBmp[54 + 192];
static int mBi;

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

static void PutB(int v) { mBmp[mBi++] = (unsigned char)(v & 0xFF); }
static void PutW(int v) { PutB(v & 0xFF); PutB((v >> 8) & 0xFF); }
static void PutD(int v) { PutB(v & 0xFF); PutB((v >> 8) & 0xFF); PutB((v >> 16) & 0xFF); PutB((v >> 24) & 0xFF); }

static void WriteBmp8x8(const char* path) {
    int x, y;
    FILE* f;
    mBi = 0;
    PutB('B'); PutB('M');
    PutD(54 + 192);
    PutD(0);
    PutD(54);
    PutD(40);
    PutD(8); PutD(8);
    PutW(1);
    PutW(24);
    PutD(0);
    PutD(192);
    PutD(2835); PutD(2835);
    PutD(0); PutD(0);
    for (y = 0; y < 8; y++)
        for (x = 0; x < 8; x++) {
            if (((x + y) & 1) == 0) { PutB(0); PutB(0); PutB(255); }
            else { PutB(255); PutB(0); PutB(0); }
        }
    f = fopen(path, "wb");
    if (f) { fwrite(mBmp, 1, sizeof(mBmp), f); fclose(f); }
}

int main(void) {
    TRPTJOB job;
    char xml[4096];
    const char* lrpt = "05_elements.lrpt";
    const char* sub = "05_sub.lrpt";
    const char* img = "05_img.bmp";
    const char* outPdf = "05_elements.pdf";
    const char* subXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Sub\" tagLangVersion=\"1\">\n"
        " <page width=\"70\" height=\"30\" marginLeft=\"1\" marginTop=\"1\" marginRight=\"1\" marginBottom=\"1\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"sh\" height=\"10\">\n"
        "   <text name=\"st\" x=\"0\" y=\"0\" w=\"66\" h=\"6\" fontSize=\"8\">Subreport content here.</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";

    if (!BootEngine()) return 1;

    WriteText(sub, subXml);
    WriteBmp8x8(img);

    snprintf(xml, sizeof(xml),
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
        "   <image name=\"pic\" x=\"0\" y=\"58\" w=\"24\" h=\"24\" source=\"%s\" stretch=\"1\"/>\n"
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
        "</report>\n", img);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s)\n", rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("wrote %s\n", outPdf);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
