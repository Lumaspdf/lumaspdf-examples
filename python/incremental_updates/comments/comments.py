# ============================================================================
#  comments -- Python (ctypes) port of
#  examples\Vb6\incremental_updates\comments\comments.bas
#  Incremental updates: create a file with one square annotation in memory, then
#  repeatedly reply to the annotation saving each step as an incremental update.
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


# Keep the import buffer alive while the document references it.
_keep = {}


def create_test_file(pdf):
    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetPageCoords(pdf, L.pcTopDown)
    L.pdfAppend(pdf)
    L.pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, L.NO_COLOR, 255,
                      L.csDeviceRGB, b"Jim", b"Test", b"Just a test...")
    L.pdfEndPage(pdf)
    if L.pdfCloseFile(pdf) == 0:
        return None
    size = ctypes.c_uint32(0)
    p = L.pdfGetBuffer(pdf, ctypes.byref(size))
    if not p or size.value <= 0:
        return None
    buf = ctypes.string_at(p, size.value)
    L.pdfFreePDF(pdf)  # releases the original buffer, resets the instance
    return buf


def load_test_file(pdf, buf):
    L.pdfCreateNewPDFA(pdf, b"")
    # if2IncrementalUpd also sets ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict
    L.pdfSetImportFlags2(pdf, L.if2IncrementalUpd)
    cbuf = ctypes.create_string_buffer(buf, len(buf))
    _keep["buf"] = cbuf  # keep alive
    if L.pdfOpenImportBuffer(pdf, ctypes.cast(cbuf, ctypes.c_void_p), len(buf), L.ptOpen, b"") < 0:
        return False
    return L.pdfImportPDFFile(pdf, 1, 1.0, 1.0) > 0


def save_file(pdf):
    if L.pdfCloseFile(pdf) == 0:
        return None
    size = ctypes.c_uint32(0)
    p = L.pdfGetBuffer(pdf, ctypes.byref(size))
    if not p or size.value <= 0:
        return None
    buf = ctypes.string_at(p, size.value)
    L.pdfFreePDF(pdf)
    return buf


def main():
    here = os.path.dirname(os.path.abspath(__file__))

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)

    buf = create_test_file(pdf)
    if buf is None:
        L.pdfDeletePDF(pdf)
        return

    if load_test_file(pdf, buf):
        reply = L.pdfSetAnnotMigrationStateA(pdf, 0, L.asCreateReply, b"Harry")
        L.pdfSetAnnotStringA(pdf, reply, L.asContent, b"Hi Jim, your test annotation looks fine!")
        buf = save_file(pdf)
        if buf and load_test_file(pdf, buf):
            reply = L.pdfSetAnnotMigrationStateA(pdf, reply, L.asCreateReply, b"Tommy")
            L.pdfSetAnnotStringA(pdf, reply, L.asContent, b"Just a test whether I can reply to a reply...")
            buf = save_file(pdf)
            if buf and load_test_file(pdf, buf):
                reply = L.pdfSetAnnotMigrationStateA(pdf, reply, L.asCreateReply, b"Jim")
                L.pdfSetAnnotStringA(pdf, reply, L.asContent, b"Seems to work very well!")
                if L.pdfHaveOpenDoc(pdf) != 0:
                    file_path = os.path.join(here, "out.pdf")
                    if L.pdfOpenOutputFileA(pdf, file_path.encode("latin-1")) != 0:
                        if L.pdfCloseFile(pdf) != 0:
                            print('PDF file "' + file_path + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
