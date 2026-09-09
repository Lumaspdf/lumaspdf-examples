// 04_flow_layout -- C++ port of
// examples\delphi\xfa\04_flow_layout\04_flow_layout.dpr
//
// XFA "flavor tour" example 4 of 10 -- FLOW LAYOUT: an "Employment
// Application" with two sibling flowed subforms under a layout="position"
// root -- TermsPanel (layout="tb", 6 clauses stacked vertically with zero
// gap) and SkillsPanel (layout="lr-tb", 9 tags packed left-to-right,
// wrapping across 3 lines).
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (04_flow_layout.template.xml / .datasets.xml)
// -- no XML parsing needed, just raw bytes.
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
    printf("pdfRenderXFAForm -> %d\n", result);
    if (result < 0) {
        printf("pdfRenderXFAForm FAILED, code %d\n", result);
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
        dir + "/04_flow_layout.template.xml",
        dir + "/04_flow_layout.datasets.xml",
        dir + "/04_flow_layout.pdf");
    printf("RESULT|04_flow_layout=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- hand-computed geometry:\n");
        printf("  TermsPanel (tb, x=36 w=540, h=24 each, gap=0):\n");
        printf("    Clause1..6 y = 92, 116, 140, 164, 188, 212 (curY steps of +24)\n");
        printf("  SkillsPanel (lr-tb, x=36 y=270 w=540, tag w=110 h=20, 4 per line):\n");
        printf("    Skill1..4 (line 1) x = 36, 146, 256, 366  @ y=270\n");
        printf("    Skill5..8 (line 2) x = 36, 146, 256, 366  @ y=290\n");
        printf("    Skill9    (line 3) x = 36              @ y=310\n");
        printf("  21 total layout boxes (form1 + 2 headers + 2 panels + 6 clauses + 9 skills + 1 header)\n");
    }
    return r >= 0 ? 0 : 1;
}
