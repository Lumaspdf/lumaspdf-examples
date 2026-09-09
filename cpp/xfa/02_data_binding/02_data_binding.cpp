// 02_data_binding -- C++ port of
// examples\delphi\xfa\02_data_binding\02_data_binding.dpr
//
// XFA "flavor tour" example 2 of 10 -- DATA BINDING: implicit by-name
// binding, explicit <bind match="dataRef" ref="..."/> SOM path binding, and
// <bind match="none"/> literal-only binding, all against one realistic
// nested <xfa:datasets> packet.
//
// Same pipeline as every example in this tour:
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
// The packet files here are already pre-split (02_data_binding.template.xml
// / .datasets.xml) so no XML parsing is needed -- just read raw bytes.
//
// Does not rebuild LumasPdf.dll -- links against wrappers\c\lumaspdf.h and
// loads the LumasPdf.dll copied next to this .exe (same convention every
// examples\cpp\* program in this project follows).
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
    printf("LumasPDF XFA flavor tour -- example 2/10: Data Binding\n");
    printf("(implicit by-name + explicit dataRef SOM path + match=none literal)\n\n");

    std::string dir = ExeDir(argv[0]);
    int r = RenderExample(
        dir + "/02_data_binding.template.xml",
        dir + "/02_data_binding.datasets.xml",
        dir + "/02_data_binding.render.pdf");
    printf("\nRESULT|02_data_binding=%d\n", r);

    if (r >= 0) {
        printf("\nChecklist (see README.md) -- extract text from 02_data_binding.render.pdf\n");
        printf("and confirm each field's resolved value:\n");
        printf("  Customer Name (implicit)                -> Acme Robotics LLC\n");
        printf("  Account ID (implicit)                   -> ACCT-88213\n");
        printf("  Street (implicit, nested subform)       -> 500 Innovation Way\n");
        printf("  State (implicit, nested subform)        -> IL\n");
        printf("  Zip (implicit, nested subform)          -> 62704\n");
        printf("  Shipping City (explicit dataRef, 3 deep) -> Springfield\n");
        printf("  Primary Contact Email (dataRef, 4 deep)  -> ap@acmerobotics.example\n");
        printf("  Status (match=\"none\" literal)           -> Active - Verified (NOT PENDING_CLOSURE)\n");
    }
    return r >= 0 ? 0 : 1;
}
