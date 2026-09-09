# ============================================================================
#  edit_text -- Python (ctypes) port of examples\Vb6\edit_text\edit_text.bas
#  Imports a PDF, then uses the content parser to find every occurrence of a
#  search string on each page and replace it.
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

    pdf = L.pdfNewPDF()
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    # Avoid the conversion of pages to templates
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)

    in_file = os.path.join(here, "dynapdf_help.pdf")
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    ctx = L.psrCreateParserContext(pdf, L.ofDefault, 0)
    search_text = "PDF"    # occurs very often in the help file
    replace_text = "XDF"   # just an example

    content = L.TContent()
    sel = L.TTextSelection()

    for i in range(1, L.pdfGetPageCount(pdf) + 1):
        # cpfEnableTextSelection is required, otherwise no text can be found.
        if L.psrParsePage(pdf, ctx, 0, 0, i, L.cpfEnableTextSelection, 0, content) != 0:
            curr = None  # NULL
            while L.psrFindText(pdf, ctx, 0, L.stDefault, curr, search_text, len(search_text), sel) != 0:
                L.psrReplaceSelText(pdf, ctx, L.rtfDefault, sel, replace_text, len(replace_text))
                curr = ctypes.byref(sel)
            L.psrWriteToPage(pdf, ctx, L.ofDefault, 0)

    L.psrDeleteParserContext(ctypes.byref(ctypes.c_void_p(ctx)))

    out_file = os.path.join(here, "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
    if L.pdfCloseFile(pdf) != 0:
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
