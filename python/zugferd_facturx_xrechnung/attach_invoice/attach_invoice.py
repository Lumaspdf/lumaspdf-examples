import sys, os, ctypes
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

# attach_invoice -- Python (ctypes) port of the VB6 mirror.
# Imports an existing PDF/A-3 invoice, attaches the factur-x.xml e-invoice,
# associates it with the catalog and sets the FacturX Comfort PDF version.

HERE = os.path.dirname(os.path.abspath(__file__))
TF = os.path.join(HERE, "..", "..", "..", "test_files")


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_cb = L.TErrorProc(_err)  # keep global ref


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)
    L.pdfCreateNewPDFA(pdf, b"")

    # We assume the pdf invoice is already a valid PDF/A-3 file.
    L.pdfSetImportFlags(pdf, L.ifImportAsPage | L.ifImportAll)
    L.pdfOpenImportFileA(pdf, os.path.join(TF, "test_invoice.pdf").encode('latin-1'), L.ptOpen, b"")

    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

    ef = L.pdfAttachFileA(pdf, os.path.join(TF, "factur-x.xml").encode('latin-1'),
                          b"EN 16931 compliant invoice", 0)
    L.pdfAssociateEmbFile(pdf, L.adCatalog, -1, L.arAlternative, ef)

    # ZUGFeRD 2.1+ and FacturX share the same version constants in PDF.
    L.pdfSetPDFVersion(pdf, L.pvFacturX_Comfort)

    if L.pdfHaveOpenDoc(pdf) != 0:
        outFile = os.path.join(HERE, "out.pdf.")
        if L.pdfOpenOutputFileA(pdf, outFile.encode('latin-1')) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + outFile + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
