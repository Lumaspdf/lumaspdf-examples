# ============================================================================
#  repair -- Python (ctypes) port of examples\c\repair\repair.c
#  Fixes a damaged PDF with a SINGLE method: pdfConvertFileA(..., ctNormalize).
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
    rc = L.pdfConvertFileA(
        pdf,
        b"../../test_files/corrupt.pdf",   # 4-page damaged input (mangled xref)
        b"repaired.pdf",
        L.ctNormalize, 0,
        None, None, None,                  # RGBProfile, CMYKProfile, OwnerPwd
        None,                              # UserData
        L.TOnFontNotFoundProc(0),          # OnFontNotFound
        L.TOnReplaceICCProfile(0))         # OnReplaceICC
    print("pdfConvertFile(ctNormalize) rc=%d  (repair-mode used: %d)"
          % (rc, L.pdfGetInRepairMode(pdf)))
    L.pdfDeletePDF(pdf)
    return 1 if rc < 0 else 0


if __name__ == "__main__":
    sys.exit(main())
