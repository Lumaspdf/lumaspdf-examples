// print_pdf -- POSIX port of examples/cpp/rendering_engine/print_pdf/print_pdf.cpp
// (itself a port of examples/Vb6/rendering_engine/print_pdf/print_pdf.bas).
//
// Loads a PDF, imports its first page, and PRINTS it through the engine's
// printing subsystem.
//
// ===========================================================================
//  PLATFORM DIVERGENCE -- this example uses a different printing mechanism
//  than the Windows version, because the engine itself does.
// ===========================================================================
// WINDOWS does it in two halves: the app opens the common Print dialog
// (comdlg32 PrintDlgA with PD_RETURNDC) to get a printer DEVICE CONTEXT, then
// hands that HDC to pdfPrintPDFFileA, which replays the rendered pages onto it
// with GDI (CreateDCW / StartDocW / StartPage / StretchDIBits / EndPage /
// EndDoc). Both halves are Win32-only: there is no PrintDlg on POSIX, no HDC,
// and the engine's rasterizer behind that replay is GDI-based and returns an
// empty buffer off Windows (see cpp/src/pdf/raster.cpp's own #else branch).
//
// POSIX (Linux/macOS) is not a stub -- it is a genuinely different, and simpler,
// submission model, implemented in cpp/src/pdf/print_exports.cpp's `#else //
// !_WIN32` branch: pdfPrintPDFFile*/pdfPrintPage* serialize the live document
// with TLumasPdfDoc::SnapshotToBuffer(), write those bytes to a scratch file
// under $TMPDIR, and submit that file to CUPS with cupsPrintFile(). No pixels
// are replayed; CUPS renders the PDF itself. The document is NOT closed or
// mutated by the call (SnapshotToBuffer serializes to a fresh in-memory stream),
// so it stays usable afterwards, exactly as on Windows.
//
// CONSEQUENCES FOR THIS EXAMPLE, all of them properties of the API and not of
// the port:
//
//   * NO PRINT DIALOG. There is nothing to replace PrintDlgA with, and nothing
//     to feed it into: the `HDC DC` argument is documented as ignored in the
//     POSIX branch ((void)DC). This example therefore passes 0 for it. If you
//     want a print dialog on Linux, that is GTK's GtkPrintUnixDialog in YOUR
//     application, and its result has no channel into this API (below).
//
//   * NO PRINTER SELECTION. Nothing in this API family carries a printer name:
//     TPDFPrintParams is StructSize-only, and HDC is Windows' own
//     already-bound-to-a-printer handle. Every POSIX job consequently goes to
//     the CUPS DEFAULT destination (lumas::PrnGetDefaultPrinter() ->
//     cupsGetDefault()). Choosing a queue would need an ABI addition.
//     ("lp -d <queue>" or setting the user default with "lpoptions -d <queue>"
//     is the workaround until then.)
//
//   * Flags (pffAutoRotateAndCenter / pffShrinkToPrintArea) and the Margin
//     rect are Windows-DC page-fitting concepts and are likewise ignored on
//     POSIX ((void)Flags; (void)Margin). They are still passed here, unchanged
//     from the Windows example, so the two sources stay comparable -- but do
//     not expect them to have an effect. The CUPS-side equivalents are job
//     options ("fit-to-page", "media", ...) which this API cannot express yet.
//
//   * ENGINE LIMITATION FOUND WHILE WRITING THIS: the printer-ENUMERATION
//     exports are NOT wired up on POSIX even though the engine has a working
//     CUPS implementation of them internally. printing.cpp implements
//     PrnGetPrinterNames() with cupsGetDests() and PrnGetDefaultPrinter() with
//     cupsGetDefault(), but print_exports.cpp's !_WIN32 branch returns nullptr
//     unconditionally from pdfGetPrinterNames*/pdfGetDefaultPrinterName*/
//     pdfGetPrinterBins*/pdfGetPrinterMediaTypes*, so a caller cannot see them.
//     Only the four job-submission entry points reach CUPS. This example prints
//     what those getters actually return, rather than pretending otherwise --
//     wiring them to the already-existing Prn* functions is a small engine fix,
//     not a missing platform capability.
//
// EXIT CODE: 0 whenever the example itself behaved correctly, including when
// the machine simply has no CUPS destination configured -- that is a fact about
// the box, not a failure of the code, and mirrors the Windows version returning
// 0 after the user cancels the Print dialog. A genuine engine failure (cannot
// open the input, cannot import the page) returns 1.
// ===========================================================================
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv) {
    (void)argc; (void)argv;

    PPDF pdf = pdfNewPDF();
    if (pdf == 0) { printf("pdfNewPDF failed\n"); return 1; }
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");          // in-memory document

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_multipage.pdf", ptOpen, "") < 0) {
        printf("cannot open %s\n", LUMAS_REPO_ROOT "/sample_multipage.pdf");
        pdfDeletePDF(pdf);
        return 1;
    }

    pdfAppend(pdf);
        pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    // Run the document's OpenAction/"will print" JavaScript, same as Windows.
    pdfApplyAppEvent(pdf, aePrint, 0);

    // What the engine's own printer getters report here. On POSIX these are the
    // unconditional-nullptr stubs described in the header -- shown so the
    // limitation is visible in the output instead of only in a comment.
    const char* defName = pdfGetDefaultPrinterNameA(pdf);
    const char* allNames = pdfGetPrinterNamesA(pdf);
    printf("pdfGetDefaultPrinterNameA -> %s\n", defName ? defName : "(null)");
    printf("pdfGetPrinterNamesA       -> %s\n", allNames ? allNames : "(null)");
    printf("(both are unconditional nullptr on POSIX; the CUPS destination the\n"
           " job below actually targets is resolved inside the engine via\n"
           " cupsGetDefault() and is not exposed through these exports.)\n");

    // Submit the whole current document to the CUPS default destination.
    // DC = 0, Margin = nullptr, Parms = nullptr: all ignored on POSIX.
    // Flags are carried over from the Windows example unchanged (see header).
    printf("submitting to the CUPS default destination...\n");
    LBOOL ok = pdfPrintPDFFileA(pdf, "", "Test Print", (HDC)0,
                                pffDefault | pffAutoRotateAndCenter | pffShrinkToPrintArea,
                                nullptr, nullptr);
    if (ok) {
        printf("Page 1 successfully printed\n");
    } else {
        // Distinguishing the two reasons needs CUPS itself, which this example
        // does not link -- so report both honestly rather than guess.
        printf("Not printed. Either no CUPS default destination is configured\n"
               "(check: lpstat -d), or cupsPrintFile() rejected the job.\n");
    }

    pdfDeletePDF(pdf);
    return 0;
}
