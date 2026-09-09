# ============================================================================
#  migration_states -- Python (ctypes) port of
#  examples\Vb6\annotations\migration_states\migration_states.bas
#  A square annotation whose review state is set to Completed then Accepted.
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

NO_COLOR = 0xFFFFFFF1  # transparent


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    # To see the migration state, right click on the annotation and then on Review History.
    annot = L.pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, L.csDeviceRGB, b"Jim", b"Test", b"Just test...")
    reply = L.pdfSetAnnotMigrationStateA(pdf, annot, L.asCompleted, b"Harry")
    L.pdfSetAnnotStringA(pdf, reply, L.asContent, b"The state was set to Completed!")

    reply = L.pdfSetAnnotMigrationStateA(pdf, reply, L.asAccepted, b"Jim")
    L.pdfSetAnnotStringA(pdf, reply, L.asContent, b"The state was set to Accepted!")
    L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        out_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out.pdf")
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + out_file + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
