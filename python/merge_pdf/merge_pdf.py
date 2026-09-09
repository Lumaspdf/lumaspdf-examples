# ============================================================================
#  merge_pdf -- Python (ctypes) port of examples\Vb6\merge_pdf\merge_pdf.bas
#  Generic code to merge arbitrary PDF files (with special handling for
#  interactive forms / PDF collections).
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
    return 0


def extract_file_name(path):
    return os.path.basename(path)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    cr = chr(13)

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 14.0, 0, L.cp1252)
    intro = ("The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that "
             "all destinations refer to the new page numbers after import." + cr + cr
             + "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number "
             "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().")
    L.pdfWriteFTextExA(pdf, 50.0, 50.0, L.pdfGetPageWidth(pdf) - 100.0, -1.0, L.taJustify, intro.encode("latin-1", "replace"))
    L.pdfEndPage(pdf)

    first = True
    dest_page = 1
    have_xfa = False
    is_collection = False

    files = [os.path.join(here, "license.pdf"), os.path.join(here, "dynapdf_help.pdf")]

    for i in range(2):
        if L.pdfOpenImportFileA(pdf, files[i].encode("latin-1"), L.ptOpen, b"") < 0:
            L.pdfDeletePDF(pdf)
            return
        if first:
            first = False
            have_xfa = (L.pdfGetInIsXFAForm(pdf) != 0)
            is_collection = (L.pdfGetInIsCollection(pdf) != 0)
            dest_page = L.pdfImportPDFFile(pdf, dest_page + 1, 1.0, 1.0)
            if dest_page < 0:
                break
        else:
            if is_collection:
                if L.pdfGetInIsCollection(pdf) != 0:
                    L.pdfSetImportFlags(pdf, L.ifEmbeddedFiles)
                    if L.pdfImportCatalogObjects(pdf) == 0:
                        break
                else:
                    L.pdfCloseImportFile(pdf)
                    L.pdfAttachFileA(pdf, files[i].encode("latin-1"),
                                     extract_file_name(files[i]).encode("latin-1"), 1)
            else:
                if (L.pdfGetInIsCollection(pdf) != 0) or (((L.pdfGetInIsXFAForm(pdf) != 0) or (L.pdfGetInFieldCount(pdf) > 0)) and ((L.pdfGetFieldCount(pdf) > 0) or have_xfa)):
                    break
                L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
                L.pdfSetImportFlags2(pdf, L.if2UseProxy)
                dest_page = L.pdfImportPDFFile(pdf, dest_page + 1, 1.0, 1.0)
                if dest_page < 0:
                    break
        L.pdfCloseImportFile(pdf)

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
