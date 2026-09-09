// 08_picture_clause_formatting -- C++ port of
// examples\delphi\xfa\08_picture_clause_formatting\08_picture_clause_formatting.dpr
//
// XFA "flavor tour" example 8 of 10 -- PICTURE-CLAUSE FORMATTING: a
// "Purchase Receipt" exercising real num{}/date{}/text{} <picture> patterns
// applied both to plain bound values and to a value produced by a FormCalc
// <calculate> script (GrandTotalField = Item1Price + Item2Price +
// Item3Price, then formatted num{zzz,zz9.99}), proving the
// calculate-then-format pipeline order.
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (08_picture_clause_formatting.template.xml /
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

static int RenderExample(const std::string& templatePath, const std::string& datasetsPath,
                          const std::string& outPdfPath) {
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

    result = pdfRenderXFAForm(pdf);
    printf("pdfRenderXFAForm -> %d (expected: page count >= 1)\n", result);
    if (result < 1) {
        printf("RENDER-FAILED, code %d\n", result);
        pdfDeletePDF(pdf);
        return result;
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
        dir + "/08_picture_clause_formatting.template.xml",
        dir + "/08_picture_clause_formatting.datasets.xml",
        dir + "/08_picture_clause_formatting.pdf");
    printf("RESULT|08_picture_clause_formatting=%d\n", r);

    if (r >= 1) {
        printf("\nExpect RESULT|08_picture_clause_formatting=1 (one page rendered).\n");
        printf("Verify with any text extractor (e.g. pypdf) -- the extracted text should read:\n");
        printf("  Purchase Receipt -- Picture-Clause Formatting\n");
        printf("  Customer: Acme Corp\n");
        printf("  Unit Price: 1,875.50\n");
        printf("  Discount: ($125.00)\n");
        printf("  Date: July 24, 2026\n");
        printf("  Phone: 555-123-4567\n");
        printf("  845.25 620.00 410.25\n");
        printf("  Grand Total: 1,875.50   (calculate result Item1+Item2+Item3, then formatted)\n");
    }
    return r >= 1 ? 0 : 1;
}
