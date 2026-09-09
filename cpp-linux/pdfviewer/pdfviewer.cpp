// PDFViewer -- opens 18_invoice.pdf in the SDK's EMBEDDED viewer window.
// Ported from examples\Vb6\pdfviewer\PDFViewer.bas
// Calls the flat export vwrShowFileW(FileName, Title); both args are LWCHAR*
// (== char16_t*, a FIXED 2-byte UTF-16 code unit on every platform -- NOT the
// native wchar_t, which is 4 bytes off Windows). Paths here are ASCII, so a
// plain widen into std::u16string is enough. The call
// BLOCKS until the user closes the viewer window (Linux: a real GTK3 window,
// see viewer_gtk.cpp; Windows: not yet implemented, returns false honestly --
// see cpp/STATUS.md session 2026-07-25e).
//
// NOTE: lumaspdf.h rolls its own Win32 types, so we must NOT include <windows.h>.
// Portable `main(argc, argv)` + narrow argv[0] (matches every other non-Windows
// example's `exeDir()` idiom) instead of Windows-only `wmain`.

#include <lumaspdf.h>
#include <string>
#include <cstdio>
#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

static std::u16string Widen(const std::string& s) { return std::u16string(s.begin(), s.end()); }

int main(int argc, char** argv) {
    std::string exe(argv[0]);
    std::string dir = exe.substr(0, exe.find_last_of("\\/"));
    std::string pdf = dir + "/18_invoice.pdf";
    std::u16string pdfW = Widen(pdf);
    std::u16string titleW = Widen("18_invoice.pdf - LumasPDF embedded preview");

#ifdef _WIN32
    bool exists = _access(pdf.c_str(), 0) == 0;
#else
    bool exists = access(pdf.c_str(), 0) == 0;
#endif
    if (!exists) {
        printf("Not found: %s\n", pdf.c_str());
        return 1;
    }

    // Open the embedded viewer. Blocks until the window is closed.
    LBOOL ok = vwrShowFileW(const_cast<LWCHAR*>(pdfW.c_str()),
                            const_cast<LWCHAR*>(titleW.c_str()));
    if (!ok) {
        printf("The embedded viewer could not be shown for:\n%s\n", pdf.c_str());
        return 1;
    }
    return 0;
}
