# ============================================================================
#  multiple_signatures -- Python (ctypes) port of examples\Vb6\incremental_updates\
#  multiple_signatures\multiple_signatures.bas
#  Signs a PDF four times (two visible + two invisible signatures) using
#  incremental updates so that each new signature does not invalidate the
#  previous ones. When signing a file in place, a temp file is used.
# ============================================================================
import os
import sys
import ctypes
import tempfile
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

CERT = r"test_files\test_cert.pfx"
LICENSE = _here('license.pdf')


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


def sign_file(pdf, in_file, out_file, field_name, reason, pos_x, visible):
    out_name = out_file
    used_temp = False
    if in_file == out_file:
        fd, tmp = tempfile.mkstemp(suffix=".pdf", dir=os.path.dirname(out_file))
        os.close(fd)
        out_name = tmp
        used_temp = True

    L.pdfCreateNewPDFA(pdf, out_name.encode("latin-1"))

    # Avoids the demo string being stamped on each edited page (which would
    # invalidate previous signatures).
    L.pdfSetLicenseKey(pdf, b"SigDemo")

    L.pdfSetImportFlags2(pdf, L.if2IncrementalUpd)
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        return False
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

    if visible:
        L.pdfSetPageCoords(pdf, L.pcTopDown)
        L.pdfEditPage(pdf, 1)
        sig = L.pdfCreateSigField(pdf, field_name.encode("latin-1"), -1, pos_x, 30.0, 180.0, 40.0)
        L.pdfSetFieldBorderWidth(pdf, sig, 0.0)
        L.pdfEndPage(pdf)

    ok = (L.pdfCloseAndSignFile(pdf, CERT.encode("latin-1"), b"123456",
                                reason.encode("latin-1"), b"") != 0)
    if ok and used_temp:
        try:
            os.remove(out_file)
        except OSError:
            pass
        os.replace(out_name, out_file)
    return ok


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(here, "out.pdf")

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)

    if sign_file(pdf, LICENSE, file_path, "Signature1", "Test signature 1", 50.0, True):
        if sign_file(pdf, file_path, file_path, "Signature2", "Test signature 2", 430.0, True):
            if sign_file(pdf, file_path, file_path, "", "Test signature 3", 0.0, False):
                if sign_file(pdf, file_path, file_path, "", "Test signature 4", 0.0, False):
                    print('PDF file "' + file_path + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
