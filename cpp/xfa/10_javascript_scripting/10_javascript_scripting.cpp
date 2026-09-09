// 10_javascript_scripting -- C++ port of
// examples\delphi\xfa\10_javascript_scripting\10_javascript_scripting.dpr
//
// XFA "flavor tour" example 10 of 10 -- JS-AS-XFA-SCRIPT:
// <script contentType="application/x-javascript"> calculate scripts, the
// last piece of the XFA dynamic-form engine. On the Delphi engine this
// runs via BESEN (already embedded); the from-scratch C++ port of the
// engine itself (cpp\src\pdf\xfa_script_js.cpp) mirrors it via QuickJS with
// byte-identical output on the shared fx21/fx21b fixtures -- both are done.
// This example exercises the this.rawValue getter/setter +
// xfa.resolveNode(path).rawValue bridge contract, needing no new export --
// it plugs into the SAME pdfRenderXFAForm pipeline FormCalc already uses.
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// Packet files are pre-split (10_javascript_scripting.template.xml /
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
    printf("Wrote %s (%d page(s))\n", outPdfPath.c_str(), result);
    pdfDeletePDF(pdf);
    return result;
}

int main(int argc, char** argv) {
    std::string dir = ExeDir(argv[0]);
    int rc = RenderExample(
        dir + "/10_javascript_scripting.template.xml",
        dir + "/10_javascript_scripting.datasets.xml",
        dir + "/output.pdf");

    if (rc >= 1)
        printf("OK: JavaScript-scripted form rendered, %d page(s). Open output.pdf and confirm:\n", rc);
    else
        printf("FAILED, see errors above.\n");
    printf("  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)\n");
    printf("  - OrderSummary      = \"Purchase Order PO-1042 for Acme Robotics\"\n");
    printf("  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)\n");
    printf("    (occur-repeated JS calculate -- each row must compute independently,\n");
    printf("    not share cached state across instances)\n");

    printf("\nRESULT|10_javascript_scripting=%d\n", rc);
    return rc >= 1 ? 0 : 1;
}
