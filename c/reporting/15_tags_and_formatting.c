/* LumasReport example 15 -- Tag language + formatting tour (C port). */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

static void WriteText(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (f) { fputs(content, f); fclose(f); }
}

static char* ReadAllText(const char* path) {
    FILE* f = fopen(path, "rb");
    long n; char* buf;
    if (!f) return NULL;
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    buf = (char*)malloc((size_t)n + 1);
    if (!buf) { fclose(f); return NULL; }
    n = (long)fread(buf, 1, (size_t)n, f);
    buf[n] = 0;
    fclose(f);
    return buf;
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

static const char* ReportTmpl(void) {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"TagTour\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n"
        " <datasources>\n"
        "  <datasource alias=\"d\" provider=\"csv\" conn=\"%CSV%\"/>\n"
        " </datasources>\n"
        " <params>\n"
        "  <param name=\"Name\" default=\"(unset)\"/>\n"
        " </params>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"120\">\n"
        "   <text name=\"h\"   x=\"0\" y=\"0\"  w=\"186\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Tag &amp; formatting tour</text>\n"
        "   <text name=\"ex\"  x=\"0\" y=\"12\" w=\"186\" h=\"6\" fontSize=\"11\">expr 2+3*4 = {{expr: 2+3*4 }}</text>\n"
        "   <text name=\"vr\"  x=\"0\" y=\"20\" w=\"186\" h=\"6\" fontSize=\"11\">var:Name = {{var:Name}}</text>\n"
        "   <text name=\"fn\"  x=\"0\" y=\"28\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATNUM = {{expr: FORMATNUM('#,##0.00', 1234.5) }}</text>\n"
        "   <text name=\"fd\"  x=\"0\" y=\"36\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATDATE = {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>\n"
        "   <text name=\"esc\" x=\"0\" y=\"44\" w=\"186\" h=\"6\" fontSize=\"11\">escape literal = {{{{ }}</text>\n"
        "   <text name=\"a0\" x=\"0\" y=\"56\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"0\">hAlign 0 = left</text>\n"
        "   <text name=\"a1\" x=\"0\" y=\"63\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"1\">hAlign 1 = center</text>\n"
        "   <text name=\"a2\" x=\"0\" y=\"70\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"2\">hAlign 2 = right</text>\n"
        "   <text name=\"a3\" x=\"0\" y=\"77\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"3\">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>\n"
        "   <text name=\"v0\" x=\"0\"   y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"0\">vAlign 0 top</text>\n"
        "   <text name=\"v1\" x=\"63\"  y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"1\">vAlign 1 middle</text>\n"
        "   <text name=\"v2\" x=\"126\" y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"2\">vAlign 2 bottom</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"rows\" height=\"7\" data=\"d\">\n"
        "   <text name=\"r\" x=\"0\" y=\"0\" w=\"186\" h=\"6\" fontSize=\"11\">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

static void Prove(const char* what, const char* needle, const char* hay) {
    if (hay && strstr(hay, needle)) printf("  OK   %s found \"%s\"\n", what, needle);
    else printf("  MISS %s expected \"%s\"\n", what, needle);
}

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* csv = "15_data.csv";
    const char* outPdf = "15_tags.pdf";
    const char* outTxt = "15_tags.txt";
    const char* tmpl;
    char* xml;
    char* pos;
    char* txt;
    char isoToday[16];
    size_t need;
    time_t t; struct tm* lt;
    if (!BootEngine(&pdf, &eng)) return 1;

    WriteText(csv, "Col,Note\nAlpha,first\nBeta,second\n");

    /* Inject the absolute CSV path into the report markup (replace %CSV%). */
    tmpl = ReportTmpl();
    need = strlen(tmpl) + strlen(csv) + 16;
    xml = (char*)malloc(need);
    pos = strstr(tmpl, "%CSV%");
    {
        size_t pre = (size_t)(pos - tmpl);
        memcpy(xml, tmpl, pre);
        xml[pre] = 0;
        strcat(xml, csv);
        strcat(xml, pos + 5);
    }

    job = rptOpenReportMem(eng, xml, (int)strlen(xml));
    if (!job) { printf("open failed\n"); DumpRptError(eng); free(xml); goto cleanup; }

    rptSetParamStr(job, "Name", "Ada_Lovelace");

    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    printf("rendered %d page(s)\n", rptGetPageCount(job));

    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("PDF export failed\n"); DumpRptError(eng); goto closejob; }
    printf("wrote %s\n", outPdf);
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("TEXT export failed\n"); DumpRptError(eng); goto closejob; }
    printf("wrote %s\n", outTxt);
closejob:
    rptCloseReport(job);
    free(xml);

    printf("== Proof (grep the TEXT export) ==\n");
    txt = ReadAllText(outTxt);
    t = time(NULL); lt = localtime(&t);
    strftime(isoToday, sizeof(isoToday), "%Y-%m-%d", lt);

    Prove("expr 2+3*4", "= 14", txt);
    Prove("var:Name", "Ada_Lovelace", txt);
    Prove("FORMATNUM", "1,234.50", txt);
    Prove("FORMATDATE", isoToday, txt);
    Prove("escape {{}}", "{{ }}", txt);
    Prove("fields.d.Col", "Alpha", txt);
    Prove("bare d.Col", "Beta", txt);
    if (txt) free(txt);
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}
