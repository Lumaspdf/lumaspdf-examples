# ============================================================================
#  collections -- Python (ctypes) port of examples\Vb6\collections\collections.bas
#  Imports a cover page, creates a PDF portfolio (collection) and attaches
#  three files to it.
# ============================================================================
import os
import sys
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

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, "..", "..", "test_files")


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def main():
    pdf = L.pdfNewPDF()
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later
    L.pdfSetOnErrorProc(pdf, 0, err_proc)

    cover = os.path.join(TEST, "collection_en.pdf")
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
    if L.pdfOpenImportFileA(pdf, cover.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        print('Input file "' + cover + '" not found!')
        return
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)
    L.pdfCreateCollection(pdf, L.civTile)

    ef = L.pdfAttachFileA(pdf, os.path.join(TEST, "taxform.pdf").encode("latin-1"), b"A PDF file...", 1)
    L.pdfSetColDefFile(pdf, ef)  # opened when viewing in Acrobat 8 or later
    L.pdfAttachFileA(pdf, os.path.join(TEST, "fulltest.emf").encode("latin-1"), b"An EMF file...", 1)
    L.pdfAttachFileA(pdf, os.path.join(TEST, "sample.txt").encode("latin-1"), b"A text file...", 1)

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
    L.pdfCloseFile(pdf)
    print('PDF Collection "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
