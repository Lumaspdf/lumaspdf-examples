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

# conv_to_zugferd -- Python (ctypes) port of the VB6 mirror.
# Converts a PDF to PDF/A-3 (FacturX Comfort), attaches factur-x.xml and adds
# an output intent. Uses font-not-found and ICC-profile replacement callbacks.

HERE = os.path.dirname(os.path.abspath(__file__))
TF = os.path.join(HERE, "..", "..", "..", "test_files")

fsRegular = getattr(L, "fsRegular", 0)


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_ecb = L.TErrorProc(_err)  # keep global ref


def _weight_from_style(style):
    style &= 0xFFFFFFFF
    w = (style & 0x7FF00000) >> 20
    if style & 0x80000000:
        w += 0x800
    return w


def _font_not_found(data, pdffont, fontname, style, stdidx, issym):
    s = style
    if _weight_from_style(s) < 500:
        s = (s & 0xF) | fsRegular
    return L.pdfReplaceFontA(data, pdffont, b"Arial", s, 1)


def _replace_icc(data, ptype, cs):
    if ptype == L.ictRGB:
        p = os.path.join(TF, "sRGB.icc")
    elif ptype == L.ictCMYK:
        p = os.path.join(TF, "ISOcoated_v2_bas.ICC")
    else:
        p = os.path.join(TF, "gray.icc")
    return L.pdfReplaceICCProfileA(data, cs, p.encode('latin-1'))


_fcb = L.TOnFontNotFoundProc(_font_not_found)  # keep global ref
_icb = L.TOnReplaceICCProfile(_replace_icc)     # keep global ref


def convert_file(pdf, conv_type, in_file, invoice, out_file):
    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetDocInfoA(pdf, L.diProducer, b"")

    if conv_type not in (L.ctFacturX_Comfort, L.ctFacturX_Extended, L.ctFacturX_XRechnung):
        return False  # we create e-invoices in this example and nothing else

    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetDocInfoA(pdf, L.diProducer, b"")

    conv_flags = L.coCheckImages | L.coRepairDamagedImages

    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage | L.ifPrepareForPDFA)
    L.pdfSetImportFlags2(pdf, L.if2UseProxy)

    L.pdfOpenImportFileA(pdf, in_file.encode('latin-1'), L.ptOpen, b"")
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    ef = L.pdfAttachFileA(pdf, invoice.encode('latin-1'), b"EN 16931 compliant invoice", 0)
    if conv_type != L.ctFacturX_XRechnung:
        L.pdfAssociateEmbFile(pdf, L.adCatalog, -1, L.arAlternative, ef)
    else:
        L.pdfAssociateEmbFile(pdf, L.adCatalog, -1, L.arSource, ef)

    retval = L.pdfCheckConformance(pdf, conv_type, conv_flags, pdf, _fcb, _icb)
    if retval == 1:
        L.pdfAddOutputIntentA(pdf, os.path.join(TF, "sRGB.icc").encode('latin-1'))
    elif retval == 2:
        L.pdfAddOutputIntentA(pdf, os.path.join(TF, "ISOcoated_v2_bas.ICC").encode('latin-1'))
    elif retval == 3:
        L.pdfAddOutputIntentA(pdf, os.path.join(TF, "gray.icc").encode('latin-1'))

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode('latin-1')) == 0:
            L.pdfDeletePDF(pdf)
            return False
        return L.pdfCloseFile(pdf) != 0
    return False


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _ecb)

    L.pdfSetCMapDirA(pdf, os.path.join(HERE, "..", "..", "..", "Resource", "CMap").encode('latin-1'),
                     L.lcmDelayed | L.lcmRecursive)

    outFile = os.path.join(HERE, "out.pdf")

    if convert_file(pdf, L.ctFacturX_Comfort,
                    os.path.join(TF, "test_invoice.pdf"),
                    os.path.join(TF, "factur-x.xml"), outFile):
        print('PDF file "' + outFile + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
