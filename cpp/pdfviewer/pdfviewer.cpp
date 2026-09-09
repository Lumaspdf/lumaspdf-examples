// PDFViewer -- opens 18_invoice.pdf in the SDK's EMBEDDED viewer window.
// Ported from examples\Vb6\pdfviewer\PDFViewer.bas
// Calls the flat export vwrShowFileW(FileName, Title); both args are LWCHAR*,
// a FIXED 2-byte UTF-16 code unit on every platform. LWCHAR is NOT always
// char16_t: lumaspdf.h typedefs it to wchar_t on Windows (where wchar_t already
// IS 2 bytes) and to char16_t elsewhere, and MSVC treats those as unrelated
// types -- which is why the previous std::u16string spelling failed to compile
// here with C2440. Spell the buffer std::basic_string<LWCHAR> and widen the
// ASCII paths into it, so one source is right on every target. The call
// BLOCKS until the user closes the viewer window (Linux: a real GTK3 window,
// see viewer_gtk.cpp; Windows: a real Win32 window since the 2026-08-01
// semantic-audit pass -- verified here, it opens and blocks).
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

typedef std::basic_string<LWCHAR> ustring;   // LWCHAR == wchar_t on Windows, char16_t elsewhere
static ustring Widen(const std::string& s) { return ustring(s.begin(), s.end()); }

int main(int argc, char** argv) {
    std::string exe(argv[0]);
    std::string dir = exe.substr(0, exe.find_last_of("\\/"));
    std::string pdf = dir + "/18_invoice.pdf";
    ustring pdfW = Widen(pdf);
    ustring titleW = Widen("18_invoice.pdf - LumasPDF embedded preview");

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
