// One-off helper: splits each XFA flavor-tour .xdp fixture into its raw
// <template>/<xfa:datasets> packet bytes (the same extraction every
// language's XFA driver needs -- FindChild by local name, re-serialize).
// Writes <name>.template.xml / <name>.datasets.xml next to each .xdp so
// every OTHER flavour's example driver can just read two plain files and
// call pdfCreateXFAStreamA directly, with ZERO XML parsing required in that
// target language. Run once; the split files are then committed alongside
// each .xdp like any other fixture asset.
#include <cstdio>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include "../../../cpp/src/pdf/pdf_xml.h"

using namespace lumas;

static std::string ReadAll(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}
static void WriteAll(const std::string& path, const std::string& data) {
    std::ofstream f(path, std::ios::binary);
    f.write(data.data(), (std::streamsize)data.size());
}

static std::string ExtractPacket(XmlNode* root, const std::string& localName) {
    XmlNode* node = root->FindChild(localName);
    if (!node) return "";
    return XmlSerialize(node);
}

int main(int argc, char** argv) {
    std::vector<std::string> names = {
        "01_basic_positioned_form/01_basic_positioned_form",
        "02_data_binding/02_data_binding",
        "03_formcalc_calculations/03_formcalc_calculations",
        "04_flow_layout/04_flow_layout",
        "05_occur_repeating_rows/05_occur_repeating_rows",
        "06_pagination_multipage/06_pagination_multipage",
        "07_table_layout/07_table_layout",
        "08_picture_clause_formatting/08_picture_clause_formatting",
        "09_acroform_widget_synthesis/09_acroform_widget_synthesis",
        "10_javascript_scripting/10_javascript_scripting",
    };
    int ok = 0, fail = 0;
    for (auto& n : names) {
        std::string xdpPath = n + ".xdp";
        std::string raw = ReadAll(xdpPath);
        if (raw.empty()) { printf("MISSING/EMPTY: %s\n", xdpPath.c_str()); fail++; continue; }
        XmlNode* root = XmlParse(raw);
        if (!root) { printf("PARSE-FAIL: %s\n", xdpPath.c_str()); fail++; continue; }
        std::string tmpl = ExtractPacket(root, "template");
        std::string data = ExtractPacket(root, "datasets");
        if (tmpl.empty()) { printf("NO-TEMPLATE: %s\n", xdpPath.c_str()); delete root; fail++; continue; }
        WriteAll(n + ".template.xml", tmpl);
        WriteAll(n + ".datasets.xml", data);
        printf("OK %s : template=%zu bytes, datasets=%zu bytes\n", n.c_str(), tmpl.size(), data.size());
        delete root;
        ok++;
    }
    printf("\n%d ok, %d failed\n", ok, fail);
    return fail > 0 ? 1 : 0;
}
