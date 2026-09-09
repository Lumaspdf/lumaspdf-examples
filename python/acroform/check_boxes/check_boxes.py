# ============================================================================
#  check_boxes -- Python (ctypes) port of examples\Vb6\acroform\check_boxes\check_boxes.bas
#  Normal check boxes, field groups (radio-like), radio buttons and a reset action.
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

clLtGray = 12632256  # VCL clLtGray (= clSilver)


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0  # try to continue if an error occurs


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 10.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 50.0, 50.0, b"Normal check boxes.")

    L.pdfChangeFontSize(pdf, 1.0)
    f = L.pdfCreateCheckBox(pdf, b"N1", b"C1", 1, -1, 50.0, 70.0, 20.0, 20.0)
    L.pdfSetCheckBoxDefState(pdf, f, 1)
    f = L.pdfCreateCheckBox(pdf, b"N2", b"C2", 1, -1, 80.0, 70.0, 20.0, 20.0)
    L.pdfSetCheckBoxDefState(pdf, f, 1)
    f = L.pdfCreateCheckBox(pdf, b"N3", b"C1", 1, -1, 110.0, 70.0, 20.0, 20.0)
    L.pdfSetCheckBoxDefState(pdf, f, 1)

    L.pdfChangeFontSize(pdf, 10.0)
    L.pdfWriteTextA(pdf, 50.0, 100.0, b"Field group with check boxes.")

    L.pdfChangeFontSize(pdf, 1.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C1", 0, -1, 50.0, 120.0, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C2", 0, -1, 80.0, 120.0, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C1", 1, -1, 110.0, 120.0, 20.0, 20.0)

    L.pdfChangeFontSize(pdf, 10.0)
    L.pdfWriteFTextExA(pdf, 50.0, 150.0, 220.0, -1.0, L.taLeft,
        b"This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.")

    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0

    L.pdfChangeFontSize(pdf, 1.0)
    L.pdfSetCheckBoxChar(pdf, L.ccCircle)
    L.pdfCreateCheckBox(pdf, b"G2", b"C1", 0, -1, 50.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G2", b"C2", 0, -1, 80.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G2", b"C3", 1, -1, 110.0, y, 20.0, 20.0)

    L.pdfChangeFontSize(pdf, 10.0)
    L.pdfWriteFTextExA(pdf, 300.0, 50.0, 250.0, -1.0, L.taLeft,
        b"This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.")

    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0

    L.pdfChangeFontSize(pdf, 15.0)
    r = L.pdfCreateRadioButton(pdf, b"Radio1", b"R1", 1, -1, 300.0, y, 20.0, 20.0)
    L.pdfSetCheckBoxDefState(pdf, r, 0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 330.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R3", 0, r, 360.0, y, 20.0, 20.0)

    L.pdfChangeFontSize(pdf, 10.0)
    f = L.pdfCreateButtonA(pdf, b"Reset", b"Reset", -1, 400.0, y, 60.0, 20.0)
    L.pdfSetFieldColor(pdf, f, L.fcBackColor, L.csDeviceRGB, clLtGray)
    L.pdfSetFieldBorderStyle(pdf, f, L.bsBevelled)

    act = L.pdfCreateResetAction(pdf)
    L.pdfAddActionToObj(pdf, L.otField, L.oeOnMouseUp, act, f)
    L.pdfAddFieldToFormAction(pdf, act, r, 1)

    y = y + 40.0
    L.pdfChangeFontSize(pdf, 10.0)
    L.pdfWriteFTextExA(pdf, 300.0, y, 250.0, -1.0, L.taLeft,
        b"The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.")
    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0

    L.pdfChangeFontSize(pdf, 15.0)
    r = L.pdfCreateRadioButton(pdf, b"Radio2", b"R1", 1, -1, 300.0, y, 20.0, 20.0)
    L.pdfSetFieldFlags(pdf, r, L.ffRadioIsUnion, 0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 330.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R1", 1, r, 360.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 390.0, y, 20.0, 20.0)
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
