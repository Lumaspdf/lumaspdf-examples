// 01_basic_positioned_form -- C++ port of
// examples\delphi\xfa\01_basic_positioned_form\01_basic_positioned_form.dpr
//
// XFA "flavor tour" example 1 of 10: POSITIONED LAYOUT -- every
// subform/draw/field carries layout="position" and an explicit x/y/w/h, no
// flow/occur/pagination involved. Renders a single-page "Employee
// Information" HR form (masthead, five statically placed data-bound fields,
// a photo-placeholder box) through the real, already-built LumasPdf.dll:
//
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// This driver does not rebuild or relink the engine DLL -- it only links,
// at compile time, against the C wrapper header wrappers\c\lumaspdf.h, and
// at run time loads whatever LumasPdf.dll is sitting next to the .exe
// (standard Windows DLL search order, same convention every examples\cpp\*
// program in this project follows).
//
// KEY SIMPLIFICATION vs the Delphi driver: the Delphi version parses the
// bundled .xdp and splits out the <template>/<xfa:datasets> packets at
// runtime via Lumas.Pdf.Xml. Here the packets are already pre-split into
// their own raw-byte files (01_basic_positioned_form.template.xml /
// .datasets.xml), so this driver needs no XML library at all -- it just
// reads the two files as bytes and hands them straight to
// pdfCreateXFAStreamA.
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

// Mirrors RenderExample from the Delphi .dpr: template/datasets packet
// paths in, rendered PDF path out, returns pdfRenderXFAForm's page count
// (>=0) on success or a negative code on failure.
static int RenderExample(const std::string& templatePath, const std::string& datasetsPath,
                          const std::string& outPdfPath) {
    printf("=== %s + %s -> output.pdf ===\n", templatePath.c_str(), datasetsPath.c_str());

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
        dir + "/01_basic_positioned_form.template.xml",
        dir + "/01_basic_positioned_form.datasets.xml",
        dir + "/output.pdf");
    printf("RESULT|01_basic_positioned_form=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- open output.pdf and confirm:\n");
        printf("  - Single page, layout=\"position\" throughout (no flow/occur/pagination)\n");
        printf("  - Masthead + five statically-positioned, data-bound fields:\n");
        printf("    name, employee ID, department, hire date, a full-time checkbox\n");
        printf("  - A photo-placeholder box in the corner\n");
    }
    return r >= 0 ? 0 : 1;
}
