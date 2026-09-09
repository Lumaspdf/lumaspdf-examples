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

# extract_invoice -- Python (ctypes) port of the VB6 mirror.
# Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
# buffer via AttachFileEx) and then verifies the embedded e-invoice can be
# found and extracted again.

HERE = os.path.dirname(os.path.abspath(__file__))
TF = os.path.join(HERE, "..", "..", "..", "test_files")

# console colour helpers (kernel32)
_k32 = ctypes.windll.kernel32
STD_OUTPUT_HANDLE = -11

clRed = 0x0000FF
clGreen = 0x008000
clYellow = 0x00FFFF
clWhite = 0xFFFFFF


def _set_color(color):
    h = _k32.GetStdHandle(STD_OUTPUT_HANDLE)
    _k32.SetConsoleTextAttribute(h, 7)
    attr = {clRed: 12, clGreen: 10, clYellow: 14, clWhite: 15}.get(color)
    if attr is not None:
        _k32.SetConsoleTextAttribute(h, attr)


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_cb = L.TErrorProc(_err)  # keep global ref


def _ptr_to_str(p):
    if not p:
        return ""
    return ctypes.cast(p, ctypes.c_char_p).value.decode('latin-1', 'replace')


def have_einvoice(pdf, in_file_name):
    info = L.TPDFVersionInfo()
    info.StructSize = ctypes.sizeof(info)
    fs = L.TPDFFileSpec()

    result = False
    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetImportFlags(pdf, L.ifDocInfo | L.ifEmbeddedFiles)
    L.pdfSetImportFlags2(pdf, L.if2UseProxy)

    if L.pdfOpenImportFileA(pdf, in_file_name.encode('latin-1'), L.ptOpen, b"") < 0:
        L.pdfFreePDF(pdf)
        return False

    L.pdfImportCatalogObjects(pdf)

    if L.pdfGetPDFVersionEx(pdf, ctypes.byref(info)) == 0:
        L.pdfFreePDF(pdf)
        return False

    if (info.PDFAVersion != 3) or (not info.FXDocName):
        L.pdfFreePDF(pdf)
        return False

    doc_name = _ptr_to_str(info.FXDocName)
    ef = L.pdfFindEmbeddedFileA(pdf, doc_name.encode('latin-1'))
    if ef < 0:
        _set_color(clRed)
        print("Invoice " + doc_name + " not found!")
        L.pdfFreePDF(pdf)
        return False
    if ef != 0:
        _set_color(clYellow)
        print("Warning: The invoice should be the first file attachment. This might cause unnecessary problems.")
    if L.pdfGetEmbeddedFile(pdf, ef, ctypes.byref(fs), 1) != 0:
        result = fs.BufSize > 0
    L.pdfFreePDF(pdf)
    return result


def create_invoice(pdf, facturx, invoice_name, out_file):
    result = False
    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetDocInfoA(pdf, L.diProducer, b"")

    if L.pdfOpenImportFileA(pdf, os.path.join(TF, "test_invoice.pdf").encode('latin-1'), L.ptOpen, b"") < 0:
        L.pdfFreePDF(pdf)
        return False

    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

    # Override the attachment name (XRechnung requires xrechnung.xml).
    try:
        with open(os.path.join(TF, "factur-x.xml"), "rb") as fh:
            buffer = fh.read()
    except OSError:
        buffer = b""

    if buffer:
        ef = L.pdfAttachFileExA(pdf, buffer, len(buffer), invoice_name.encode('latin-1'),
                                b"EN 19631 compliant invoice", 0)
    else:
        ef = L.pdfAttachFileExA(pdf, 0, 0, invoice_name.encode('latin-1'),
                                b"EN 19631 compliant invoice", 0)

    if facturx:
        L.pdfSetPDFVersion(pdf, L.pvFacturX_Comfort)
        L.pdfAssociateEmbFile(pdf, L.adCatalog, -1, L.arAlternative, ef)
    else:
        L.pdfSetPDFVersion(pdf, L.pvFacturX_XRechnung)
        L.pdfAssociateEmbFile(pdf, L.adCatalog, -1, L.arSource, ef)

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode('latin-1')) != 0:
            result = L.pdfCloseFile(pdf) != 0
    L.pdfFreePDF(pdf)
    return result


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)

    outFile = os.path.join(HERE, "out.pdf.")

    if (not create_invoice(pdf, True, "factur-x.xml", outFile)) or (not have_einvoice(pdf, outFile)) \
       or (not create_invoice(pdf, False, "xrechnung.xml", outFile)) or (not have_einvoice(pdf, outFile)):
        _set_color(clRed)
        print("XML Invoice not found!")
    else:
        _set_color(clGreen)
        print("All tests passed!")

    _set_color(clWhite)
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
