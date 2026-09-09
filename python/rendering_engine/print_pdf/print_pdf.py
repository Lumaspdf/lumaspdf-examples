# ============================================================================
#  print_pdf -- Python (ctypes) port of
#  examples\Vb6\rendering_engine\print_pdf\print_pdf.bas
#  Loads a PDF, imports the first page and prints it. A printer is chosen
#  through the standard Print dialog (PrintDlg), as the VB6/Delphi original.
#
#  NOTE: This opens the Windows Print dialog (needs a printer / interactive UI).
#  It cannot be run head-less; it is provided as a faithful port.
# ============================================================================
import os
import sys
import ctypes
from ctypes import wintypes
import os, sys


def _here(name):
    """A fixture that ships with the examples, found without a
    hard-coded path: walk up looking for test_files/."""
    d = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        c = os.path.join(d, 'test_files', name)
        if os.path.isfile(c):
            return c
        d = os.path.dirname(d)
    return name

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

FIXTURE = _here('sample_multipage.pdf')

PD_RETURNDC = 0x100
PD_HIDEPRINTTOFILE = 0x100000
PD_DISABLEPRINTTOFILE = 0x80000
PD_NOSELECTION = 0x4


class PRINTDLG(ctypes.Structure):
    _fields_ = [
        ("lStructSize", wintypes.DWORD),
        ("hwndOwner", wintypes.HWND),
        ("hDevMode", wintypes.HGLOBAL),
        ("hDevNames", wintypes.HGLOBAL),
        ("hDC", wintypes.HDC),
        ("Flags", wintypes.DWORD),
        ("nFromPage", wintypes.WORD),
        ("nToPage", wintypes.WORD),
        ("nMinPage", wintypes.WORD),
        ("nMaxPage", wintypes.WORD),
        ("nCopies", wintypes.WORD),
        ("hInstance", wintypes.HINSTANCE),
        ("lCustData", wintypes.LPARAM),
        ("lpfnPrintHook", ctypes.c_void_p),
        ("lpfnSetupHook", ctypes.c_void_p),
        ("lpPrintTemplateName", wintypes.LPCSTR),
        ("lpSetupTemplateName", wintypes.LPCSTR),
        ("hPrintTemplate", wintypes.HGLOBAL),
        ("hSetupTemplate", wintypes.HGLOBAL),
    ]


_PrintDlg = ctypes.windll.comdlg32.PrintDlgA
_PrintDlg.argtypes = [ctypes.POINTER(PRINTDLG)]
_PrintDlg.restype = wintypes.BOOL
_DeleteDC = ctypes.windll.gdi32.DeleteDC
_DeleteDC.argtypes = [wintypes.HDC]
_DeleteDC.restype = wintypes.BOOL


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def get_printer_dc():
    pd = PRINTDLG()
    pd.lStructSize = ctypes.sizeof(PRINTDLG)
    pd.Flags = PD_RETURNDC | PD_HIDEPRINTTOFILE | PD_DISABLEPRINTTOFILE | PD_NOSELECTION
    if _PrintDlg(ctypes.byref(pd)) != 0:
        return pd.hDC
    print("Cancelled!")
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # We create no PDF file in this example

    # Import anything and don't convert pages to templates
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
    if L.pdfOpenImportFileA(pdf, FIXTURE.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return

    # We print only the first page in this example.
    L.pdfAppend(pdf)
    L.pdfImportPageEx(pdf, 1, 1.0, 1.0)
    L.pdfEndPage(pdf)

    # ApplyAppEvent ensures the same result Acrobat would print (layers, etc.).
    L.pdfApplyAppEvent(pdf, L.aePrint, 0)

    dc = get_printer_dc()
    if dc:
        if L.pdfPrintPDFFileA(pdf, b"", b"Test Print", ctypes.c_void_p(dc),
                              L.pffDefault | L.pffAutoRotateAndCenter | L.pffShrinkToPrintArea,
                              None, None) != 0:
            print("Page 1 successfully printed")
        _DeleteDC(dc)

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
