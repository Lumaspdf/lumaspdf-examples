// 07_table_layout -- C++ port of
// examples\delphi\xfa\07_table_layout\07_table_layout.dpr
//
// XFA "flavor tour" example 7 of 10 -- TABLE LAYOUT: a "Product Comparison
// Table" (layout="table", columnWidths="216pt 108pt 108pt 108pt"), 6
// layout="row" children (HeaderRow + DataRow1..5), each row 4 <field>s with
// a different <para hAlign> per column (left/right/center/right) to
// exercise RenderTableCell's real per-cell alignment.
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (07_table_layout.template.xml / .datasets.xml)
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
        dir + "/07_table_layout.template.xml",
        dir + "/07_table_layout.datasets.xml",
        dir + "/07_table_layout.pdf");
    printf("RESULT|07_table_layout=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- extract text/positions from 07_table_layout.pdf:\n");
        printf("  6 rows stacked at y = 688, 668, 648, 628, 608, 588 (20pt decrement, zero gap)\n");
        printf("  Column 1 Product (hAlign=left)   -> every row starts at x=39 (flush-left)\n");
        printf("  Column 2 Price   (hAlign=right)  -> every row ends at the same x (~356.99/357)\n");
        printf("  Column 3 Stock   (hAlign=center) -> centered on column axis x=414\n");
        printf("  Column 4 Rating  (hAlign=right)  -> every row ends at the same x (~573.0)\n");
        printf("  columnWidths=\"216pt 108pt 108pt 108pt\", table x=36 y=90 w=540\n");
    }
    return r >= 0 ? 0 : 1;
}
