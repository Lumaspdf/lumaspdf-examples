# ============================================================================
#  pdfviewer -- Python (ctypes) port of examples\Vb6\pdfviewer\PDFViewer.bas
#  Opens 18_invoice.pdf in the SDK's EMBEDDED viewer window via the flat
#  export vwrShowFileW(FileNamePtr, TitlePtr). Both args are PWideChar
#  (UTF-16) pointers -> pass Python str via ctypes.c_wchar_p.
#  vwrShowFileW BLOCKS until the viewer window is closed.
# ============================================================================
import os
import sys
import ctypes
import os, sys
# the wrapper lives at <root>/wrappers/python (source checkout) or beside
# the example tree (shipped package) -- find it without a hard-coded path
_d = os.path.dirname(os.path.abspath(__file__))
for _ in range(6):
    for _c in (os.path.join(_d, 'wrappers', 'python'), _d):
        if os.path.isfile(os.path.join(_c, 'lumaspdf.py')):
            sys.path.insert(0, _c)
            break
    else:
        _d = os.path.dirname(_d)
        continue
    break
import lumaspdf as L


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    pdf = os.path.join(here, "18_invoice.pdf")
    title = "18_invoice.pdf - LumasPDF embedded preview"

    if not os.path.exists(pdf):
        print("Not found: " + pdf)
        return

    # Open the embedded viewer. Blocks until the window is closed.
    ok = L.vwrShowFileW(ctypes.c_wchar_p(pdf), ctypes.c_wchar_p(title))

    if ok == 0:
        print("The embedded viewer could not be shown for:\n" + pdf)
    else:
        print("Viewer closed OK: " + pdf)


if __name__ == "__main__":
    main()
