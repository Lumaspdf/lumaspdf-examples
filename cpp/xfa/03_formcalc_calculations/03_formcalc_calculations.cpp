// 03_formcalc_calculations -- C++ port of
// examples\delphi\xfa\03_formcalc_calculations\03_formcalc_calculations.dpr
//
// XFA "flavor tour" example 3 of 10 -- FORMCALC CALCULATIONS: an "Order
// Calculator" order summary whose <calculate><script
// contentType="application/x-formcalc"> bodies exercise Sum/Avg/Round/Count,
// If, Concat/Upper/Left, and Date2Num/Num2Date/DateFmt, plus *, -, >=.
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (03_formcalc_calculations.template.xml /
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
        dir + "/03_formcalc_calculations.template.xml",
        dir + "/03_formcalc_calculations.datasets.xml",
        dir + "/03_formcalc_calculations.render.pdf");
    printf("RESULT|03_formcalc_calculations=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- hand-computed vs. rendered, dataset is\n");
        printf("Alex Nguyen / Jul 15, 2026 / Widget 3x12.50, Gadget 2x45.00, Gizmo 5x8.00:\n");
        printf("  Item1Total (3 x 12.50)          -> 37.5\n");
        printf("  Item2Total (2 x 45.00)           -> 90\n");
        printf("  Item3Total (5 x 8.00)            -> 40\n");
        printf("  TotalQty   (Sum)                 -> 10\n");
        printf("  Subtotal   (Sum)                 -> 167.5\n");
        printf("  AvgUnitPrice (Round(Avg,2))       -> 21.83\n");
        printf("  ItemCount  (Count)                -> 3\n");
        printf("  DiscountLabel (If >= 100)         -> Bulk Discount\n");
        printf("  DiscountAmount (Round(*0.10,2))   -> 16.75\n");
        printf("  GrandTotal (Subtotal - Discount)  -> 150.75\n");
        printf("  FullName   (Concat)               -> Alex Nguyen\n");
        printf("  CustomerInitial (Upper(Left(,1)))  -> A\n");
        printf("  OrderDateNum display (Date2Num)    -> 2026-07-15\n");
        printf("  OrderDateFormatted (Num2Date+DateFmt) -> 7/15/26\n");
    }
    return r >= 0 ? 0 : 1;
}
