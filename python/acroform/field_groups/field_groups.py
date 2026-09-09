# ============================================================================
#  field_groups -- Python (ctypes) port of examples\Vb6\acroform\field_groups\field_groups.bas
#  Several text fields sharing one value (a field group), auto-size vs fixed
#  font size, plus a reset button.
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
    return 0


def main():
    cr = chr(13)

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 12.0, 0, L.cp1252)
    L.pdfSetLeading(pdf, 14.0)
    txt = ("The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type." + cr + cr +
           "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. "
           "The latter way is more efficient since it is not required to search for the parent field when a child will be created." + cr + cr +
           "Enter some more text into a field to see the difference between auto size and fixed font size.")
    L.pdfWriteFTextExA(pdf, 50.0, 50.0, L.pdfGetPageWidth(pdf) - 100.0, -1.0, L.taJustify, txt.encode("latin-1", "replace"))

    # GetLastTextPosY() returns bottom up coordinates. We must subtract from the page height.
    base = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 20.0

    L.pdfWriteFTextExA(pdf, 50.0, base, 200.0, -1.0, L.taLeft, b"Font size <= 1.0 means auto size.")

    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0

    L.pdfChangeFontSize(pdf, 1.0)
    f = L.pdfCreateTextField(pdf, b"Auto", -1, 0, 0, 50.0, y, 200.0, 20.0)
    L.pdfSetTextFieldValueA(pdf, f, b"Some text...", b"Some text...", L.taLeft)

    y = y + 30.0
    L.pdfCreateTextField(pdf, b"", f, 0, 0, 50.0, y, 200.0, 30.0)

    y = y + 40.0
    L.pdfCreateTextField(pdf, b"", f, 0, 0, 50.0, y, 200.0, 40.0)

    L.pdfChangeFontSize(pdf, 12.0)
    L.pdfWriteFTextExA(pdf, 345.0, base, 200.0, -1.0, L.taLeft, b"The same fields with a fixed font size.")

    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0

    L.pdfChangeFontSize(pdf, 12.0)
    L.pdfCreateTextField(pdf, b"", f, 0, 0, 345.0, y, 200.0, 20.0)

    y = y + 30.0
    L.pdfChangeFontSize(pdf, 24.0)
    L.pdfCreateTextField(pdf, b"", f, 0, 0, 345.0, y, 200.0, 30.0)

    y = y + 40.0
    L.pdfChangeFontSize(pdf, 34.0)
    L.pdfCreateTextField(pdf, b"", f, 0, 0, 345.0, y, 200.0, 40.0)

    L.pdfChangeFontSize(pdf, 18.0)
    f = L.pdfCreateButtonA(pdf, b"Reset", b"Reset", -1, 222.5, y + 80.0, 150.0, 25.0)
    L.pdfSetFieldColor(pdf, f, L.fcBackColor, L.csDeviceRGB, clLtGray)
    L.pdfSetFieldBorderStyle(pdf, f, L.bsBevelled)

    act = L.pdfCreateResetAction(pdf)
    L.pdfAddActionToObj(pdf, L.otField, L.oeOnMouseUp, act, f)
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
