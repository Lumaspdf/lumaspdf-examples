# ============================================================================
#  edit_page -- Python (ctypes) port of examples\Vb6\edit_page\edit_page.bas
#  Imports a rotated page, opens it for editing and writes a formatted text
#  block onto it.
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


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    cr = chr(13)

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later

    # Import anything and don't convert pages to templates
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)

    in_file = os.path.join(here, "rotated_270.pdf")
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    # Move the coordinate origin into the visible area.
    L.pdfSetUseVisibleCoords(pdf, 1)

    L.pdfEditPage(pdf, 1)
    orientation = L.pdfGetOrientation(pdf)
    if orientation != 0:
        L.pdfSetOrientationEx(pdf, orientation)
    L.pdfSetLeading(pdf, 14.0)
    f = L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 12.0, 0, L.cp1252)
    L.pdfSetListFont(pdf, f)

    # ANSI (A) export -> the bullet is code page 1252 char 144.
    b = chr(144)
    s = ("It is not difficult to edit an imported page but two things must be considered:" + cr + cr
         + "\\LI[20," + b + "]\\LD[16]The page's orientation.\\EL#\\LI[20," + b + "]\\LD[12]The coordinate origin. "
         + "The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\\EL#" + cr + "\\LD[12]"
         + "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. "
         + "LumasPDF moves the zero point then automatically into the visible area of the page." + cr + cr
         + "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present." + cr + cr
         + "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated "
         + "into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file." + cr + cr
         + "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was "
         + "not rotated. If this produces a wrong result then don't call SetOrientationEx()." + cr + cr
         + "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() "
         + "and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.")

    L.pdfWriteFTextExA(pdf, 50.0, 200.0, L.pdfGetPageWidth(pdf) - 100.0, -1.0, L.taJustify, s.encode("latin-1", "replace"))
    L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        out_file = os.path.join(here, "out.pdf")
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
