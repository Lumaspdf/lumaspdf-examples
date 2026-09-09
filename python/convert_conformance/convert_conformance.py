# ============================================================================
#  convert_conformance -- Python (ctypes) port of
#  examples\c\convert_conformance\convert_conformance.c
#  plain PDF -> PDF/A and PDF/X, each a SINGLE pdfConvertFileA call.
#  Run FROM this folder so the ../../test_files/... relative paths resolve.
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


def main():
    pdf = L.pdfNewPDF()

    a = L.pdfConvertFileA(
        pdf,
        b"../../test_files/plain.pdf", b"out_pdfa.pdf",
        L.ctPDFA_2b, 0,
        b"../../test_files/sRGB.icc",
        b"../../test_files/ISOcoated_v2_bas.ICC",
        None, None,
        L.TOnFontNotFoundProc(0), L.TOnReplaceICCProfile(0))
    print("plain -> PDF/A (ctPDFA_2b) rc=%d" % a)

    x = L.pdfConvertFileA(
        pdf,
        b"../../test_files/plain.pdf", b"out_pdfx.pdf",
        L.ctPDFX_4, 0,
        b"../../test_files/sRGB.icc",
        b"../../test_files/ISOcoated_v2_bas.ICC",
        None, None,
        L.TOnFontNotFoundProc(0), L.TOnReplaceICCProfile(0))
    print("plain -> PDF/X (ctPDFX_4)  rc=%d" % x)

    L.pdfDeletePDF(pdf)
    return 1 if (a < 0 or x < 0) else 0


if __name__ == "__main__":
    sys.exit(main())
