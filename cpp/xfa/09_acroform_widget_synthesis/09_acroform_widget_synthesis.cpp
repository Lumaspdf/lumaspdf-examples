// 09_acroform_widget_synthesis -- C++ port of
// examples\delphi\xfa\09_acroform_widget_synthesis\09_acroform_widget_synthesis.dpr
//
// XFA "flavor tour" example 9 of 10 -- ACROFORM WIDGET SYNTHESIS:
// pdfSetXFARenderMode(doc, 1) turns an XFA form into a genuinely fillable
// AcroForm PDF, not just flattened ink. A one-page "Job Application Form"
// exercises every synthesizable widget type at once (textEdit/numericEdit/
// dateTimeEdit -> Tx, checkButton exclGroup -> one Btn radio with 3 Kids,
// choiceList -> Ch combo, button -> Btn pushbutton with a real bevel /AP,
// and an occur-repeated Employer[0..2].EmployerName -> 3 independent Tx
// fields with unique bracket-indexed names).
//
// Renders the SAME template+datasets pair TWICE through the real DLL's
// public export sequence:
//
//   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//   pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(doc,1) only
//   for the second pass] -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF
//
//     mode0.pdf -- Mode 0 (default, no pdfSetXFARenderMode call at all):
//                  flattened ink only, /AcroForm/Fields empty.
//     mode1.pdf -- Mode 1 (pdfSetXFARenderMode(doc, 1)): flattened ink PLUS
//                  a real synthesized /AcroForm with 9 fillable fields.
//
// pdfSetXFARenderMode is called AFTER both pdfCreateXFAStreamA calls and
// BEFORE pdfRenderXFAForm -- exactly the sequence the Delphi .dpr uses.
//
// Packet files are pre-split (09_acroform_widget_synthesis.template.xml /
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

// Mode: 0 = flatten-to-ink only (default, no pdfSetXFARenderMode call at
// all -- exercises the untouched default path); 1 = also synthesize real
// AcroForm fillable widgets.
static int RenderExample(const std::string& templatePath, const std::string& datasetsPath,
                          const std::string& outPdfPath, int mode) {
    printf("=== %s + %s (mode=%d) -> %s ===\n", templatePath.c_str(), datasetsPath.c_str(), mode,
           outPdfPath.c_str());

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

    if (mode != 0) {
        int prev = pdfSetXFARenderMode(pdf, mode);
        printf("pdfSetXFARenderMode(pdf, %d) -> previous=%d (expect 0, the default)\n", mode, prev);
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
    printf("OK: wrote %s (%d page(s))\n", outPdfPath.c_str(), result);
    pdfDeletePDF(pdf);
    return result;
}

int main(int argc, char** argv) {
    std::string dir = ExeDir(argv[0]);
    std::string templatePath = dir + "/09_acroform_widget_synthesis.template.xml";
    std::string datasetsPath = dir + "/09_acroform_widget_synthesis.datasets.xml";

    int r0 = RenderExample(templatePath, datasetsPath, dir + "/mode0.pdf", 0);
    int r1 = RenderExample(templatePath, datasetsPath, dir + "/mode1.pdf", 1);

    printf("\nRESULT|mode0=%d|mode1=%d\n", r0, r1);
    if (r0 >= 1 && r1 >= 1) {
        printf("OK: both renders succeeded.\n");
        printf("  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.\n");
        printf("  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm with 9 fields:\n");
        printf("    ApplicantName (Tx), YearsExperience (Tx), ApplicationDate (Tx),\n");
        printf("    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract),\n");
        printf("    Department (Ch combo, 6 options), SubmitButton (Btn pushbutton, real bevel /AP),\n");
        printf("    Employer[0].EmployerName / Employer[1].EmployerName / Employer[2].EmployerName (Tx x3).\n");
        printf("  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --\n");
        printf("  it is a genuinely fillable form: click into the fields and type.\n");
    } else {
        printf("FAILED, see errors above.\n");
    }
    return (r0 >= 1 && r1 >= 1) ? 0 : 1;
}
