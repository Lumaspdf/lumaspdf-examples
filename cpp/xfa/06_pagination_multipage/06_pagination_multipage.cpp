// 06_pagination_multipage -- C++ port of
// examples\delphi\xfa\06_pagination_multipage\06_pagination_multipage.dpr
//
// XFA "flavor tour" example 6 of 10 -- MULTI-PAGE PAGINATION: an "Invoice
// Line Items" report for Acme Robotics and Automation Inc., 70 line items
// (occur min="1" max="-1", layout="row"), a 400pt-tall contentArea, 20pt
// rows, 20pt leader/trailer -- forces 4 pages of overflow with
// "continued from/on" leader/trailer banners.
//
// Same pipeline as every example in this tour, PLUS a pre-flight page-count
// check via pdfXFAFormPageCount before pdfRenderXFAForm (mirrors the Delphi
// driver's CheckPageCount=4 assertion):
//
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight)
//   -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (06_pagination_multipage.template.xml /
// .datasets.xml) -- no XML parsing needed, just raw bytes.
//
// Does not rebuild LumasPdf.dll -- links against wrappers\c\lumaspdf.h and
// loads the LumasPdf.dll copied next to this .exe.
#include <lumaspdf.h>
#include <cstdio>
#include <string>
#include <fstream>
#include <sstream>

static bool ReadFileBytes(const std::string& path, std::string& out) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return false;
    std::ostringstream ss;
    ss << f.rdbuf();
    out = ss.str();
    return true;
}

static std::string ExeDir(const char* argv0) {
    std::string s(argv0);
    size_t p = s.find_last_of("\\/");
    return p == std::string::npos ? "." : s.substr(0, p);
}

// CheckPageCount >= 0: also calls the pdfXFAFormPageCount pre-flight export
// BEFORE rendering, asserting it matches CheckPageCount exactly -- same
// convention as the Delphi driver's own RenderExample.
static int RenderExample(const std::string& templatePath, const std::string& datasetsPath,
                          const std::string& outPdfPath, int checkPageCount = -1) {
    printf("=== %s + %s -> %s ===\n", templatePath.c_str(), datasetsPath.c_str(), outPdfPath.c_str());

    std::string templateBuf, datasetsBuf;
    if (!ReadFileBytes(templatePath, templateBuf)) {
        printf("FILE-NOT-FOUND: %s\n", templatePath.c_str());
        return -100;
    }
    bool haveDatasets = ReadFileBytes(datasetsPath, datasetsBuf);
    printf("template packet bytes: %zu\n", templateBuf.size());
    printf("datasets packet bytes: %zu\n", haveDatasets ? datasetsBuf.size() : 0);

    PPDF pdf = pdfNewPDF();
    if (!pdf) {
        printf("pdfNewPDF FAILED\n");
        return -100;
    }

    int result = -100;
    if (!pdfCreateNewPDFA(pdf, outPdfPath.c_str())) {
        printf("pdfCreateNewPDFA FAILED\n");
        pdfDeletePDF(pdf);
        return -100;
    }

    int idx = pdfCreateXFAStreamA(pdf, "template", (void*)templateBuf.data(), (UI32)templateBuf.size());
    printf("pdfCreateXFAStreamA(template) -> index %d\n", idx);
    if (idx < 0) {
        printf("pdfCreateXFAStreamA(template) FAILED\n");
        pdfDeletePDF(pdf);
        return -100;
    }

    if (haveDatasets && !datasetsBuf.empty()) {
        idx = pdfCreateXFAStreamA(pdf, "datasets", (void*)datasetsBuf.data(), (UI32)datasetsBuf.size());
        printf("pdfCreateXFAStreamA(datasets) -> index %d\n", idx);
        if (idx < 0) {
            printf("pdfCreateXFAStreamA(datasets) FAILED\n");
            pdfDeletePDF(pdf);
            return -100;
        }
    } else {
        printf("(no datasets packet found -- template-only render)\n");
    }

    if (checkPageCount >= 0) {
        int pre = pdfXFAFormPageCount(pdf);
        printf("pdfXFAFormPageCount (pre-flight, before any AppendPage) -> %d\n", pre);
        if (pre != checkPageCount) {
            printf("PAGECOUNT-MISMATCH: expected %d got %d\n", checkPageCount, pre);
            pdfDeletePDF(pdf);
            return -102;
        }
    }

    result = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d\n", result);
    if (result < 0) {
        printf("pdfRenderXFAForm FAILED, code %d\n", result);
        pdfDeletePDF(pdf);
        return result;
    }
    if (checkPageCount >= 0 && result != checkPageCount) {
        printf("RENDER-PAGECOUNT-MISMATCH: pre-flight said %d but render produced %d\n",
               checkPageCount, result);
        pdfDeletePDF(pdf);
        return -103;
    }

    if (!pdfCloseFile(pdf)) {
        printf("pdfCloseFile FAILED\n");
        pdfDeletePDF(pdf);
        return -101;
    }
    printf("OK: wrote %s\n", outPdfPath.c_str());
    pdfDeletePDF(pdf);
    return result;
}

int main(int argc, char** argv) {
    std::string dir = ExeDir(argv[0]);
    int r = RenderExample(
        dir + "/06_pagination_multipage.template.xml",
        dir + "/06_pagination_multipage.datasets.xml",
        dir + "/06_pagination_multipage.pdf", 4);
    printf("RESULT|06_pagination_multipage=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- hand-derived pagination over 70 rows,\n");
        printf("400pt contentArea, 20pt rows, 20pt leader/trailer:\n");
        printf("  Page 1 rows 1-19  (19 rows), no leader, trailer drawn\n");
        printf("  Page 2 rows 20-37 (18 rows), leader drawn, trailer drawn\n");
        printf("  Page 3 rows 38-55 (18 rows), leader drawn, trailer drawn\n");
        printf("  Page 4 rows 56-70 (15 rows), leader drawn, NO trailer (true last page)\n");
        printf("  Total pages -> 4 (19+18+18+15 = 70, matches 70 authored <Line> records)\n");
    }
    return r >= 0 ? 0 : 1;
}
