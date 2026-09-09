/* PDFViewer -- opens 18_invoice.pdf in the SDK's EMBEDDED viewer window.
 * Faithful C port of examples\Vb6\pdfviewer\PDFViewer.bas.
 * Calls the flat export vwrShowFileW(FileName, Title) with wchar_t* args.
 * The call BLOCKS until the user closes the viewer window.
 *
 * Note: lumaspdf.h typedefs HDC/HWND/PBITMAPINFO itself, so it must NOT be
 * combined with <windows.h>. We derive the exe directory from wmain's argv[0].
 */
#include <stdio.h>
#include <wchar.h>
#include "lumaspdf.h"

int wmain(int argc, wchar_t **argv)
{
    wchar_t path[1024];
    wchar_t dir[1024];
    wchar_t *slash;
    LBOOL ok;
    const wchar_t *title = L"18_invoice.pdf - LumasPDF embedded preview";

    /* 18_invoice.pdf sits next to the exe. */
    wcsncpy(dir, argv[0], 1023);
    dir[1023] = 0;
    slash = wcsrchr(dir, L'\\');
    if (!slash) slash = wcsrchr(dir, L'/');
    if (slash) *slash = 0; else wcscpy(dir, L".");
    _snwprintf(path, 1024, L"%s\\18_invoice.pdf", dir);

    (void)argc;
    wprintf(L"Opening embedded viewer for: %s\n", path);
    ok = vwrShowFileW(path, (LWCHAR*)title);

    if (!ok) {
        wprintf(L"The embedded viewer could not be shown for: %s\n", path);
        return 1;
    }
    return 0;
}
