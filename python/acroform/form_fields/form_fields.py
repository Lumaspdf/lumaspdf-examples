# ============================================================================
#  form_fields -- Python (ctypes) port of examples\Vb6\acroform\form_fields\form_fields.bas
#  Text fields (single/multi-line/password/comb), combo boxes, list boxes,
#  editable combo, check boxes and radio buttons.
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


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    y = 50.0
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 10.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 50.0, y, b"Text fields:")

    y = y + 15.0
    f = L.pdfCreateTextField(pdf, b"Text1", -1, 0, 0, 50.0, y, 200.0, 20.0)
    L.pdfSetTextFieldValueA(pdf, f, b"", b"Single line text...", L.taLeft)

    y = y + 30.0
    f = L.pdfCreateTextField(pdf, b"Text2", -1, 1, 0, 50.0, y, 200.0, 50.0)
    L.pdfSetTextFieldValueA(pdf, f, b"", b"This field accepts multi-line text. The maximum text length can be restricted if necessary.", L.taLeft)

    y = y + 60.0
    L.pdfWriteTextA(pdf, 50.0, y, b"A password field:")
    y = y + 15.0
    f = L.pdfCreateTextField(pdf, b"Text3", -1, 0, 0, 50.0, y, 200.0, 20.0)
    L.pdfSetFieldFlags(pdf, f, L.ffPassword, 0)
    L.pdfSetTextFieldValueA(pdf, f, b"", b"**********", L.taLeft)

    y = y + 30.0
    L.pdfWriteTextA(pdf, 50.0, y, b"A fixed length field separated into combs:")
    y = y + 15.0
    f = L.pdfCreateTextField(pdf, b"Text4", -1, 0, 10, 50.0, y, 200.0, 20.0)
    L.pdfSetFieldFlags(pdf, f, L.ffComb, 0)

    y = 50.0
    L.pdfWriteTextA(pdf, 350.0, y, b"Choice fields:")
    y = y + 15.0
    f = L.pdfCreateComboBox(pdf, b"Combo1", 1, -1, 350.0, y, 200.0, 20.0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"", b" Select a value...", 1)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Apple", b"Apple", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Banana", b"Banana", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Pear", b"Pear", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Grape", b"Grape", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Orange", b"Orange", 0)

    y = y + 30.0
    f = L.pdfCreateListBox(pdf, b"List", 1, -1, 350.0, y, 200.0, 50.0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Apple", b"Apple", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Banana", b"Banana", 1)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Pear", b"Pear", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Grape", b"Grape", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Orange", b"Orange", 0)

    y = y + 60.0
    L.pdfWriteTextA(pdf, 350.0, y, b"Editable combo box:")
    y = y + 15.0
    f = L.pdfCreateComboBox(pdf, b"Combo2", 1, -1, 350.0, y, 200.0, 20.0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Apple", b"Apple", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Banana", b"Banana", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Pear", b"Pear", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Grape", b"Grape", 0)
    L.pdfAddValToChoiceFieldA(pdf, f, b"Orange", b"Orange", 0)
    L.pdfSetFieldFlags(pdf, f, L.ffEdit, 0)
    L.pdfSetFieldExpValueA(pdf, f, 1000, b"Select or enter a value...", b"", 1)

    y = y + 30.0
    L.pdfWriteTextA(pdf, 350.0, y, b"Check boxes / Radio buttons:")

    y = y + 15.0
    L.pdfChangeFontSize(pdf, 1.0)
    L.pdfCreateCheckBox(pdf, b"N1", b"C1", 1, -1, 350.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"N2", b"C2", 1, -1, 380.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"N3", b"C1", 1, -1, 410.0, y, 20.0, 20.0)

    L.pdfCreateCheckBox(pdf, b"G1", b"C1", 0, -1, 450.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C2", 0, -1, 480.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C1", 1, -1, 510.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"G1", b"C2", 0, -1, 540.0, y, 20.0, 20.0)

    y = y + 30.0
    L.pdfChangeFontSize(pdf, 15.0)
    L.pdfSetCheckBoxChar(pdf, L.ccCircle)
    r = L.pdfCreateRadioButton(pdf, b"Radio1", b"R1", 1, -1, 350.0, y, 20.0, 20.0)
    L.pdfSetCheckBoxDefState(pdf, r, 0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 380.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R3", 0, r, 410.0, y, 20.0, 20.0)

    r = L.pdfCreateRadioButton(pdf, b"Radio2", b"R1", 1, -1, 450.0, y, 20.0, 20.0)
    L.pdfSetFieldFlags(pdf, r, L.ffRadioIsUnion, 0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 480.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R1", 1, r, 510.0, y, 20.0, 20.0)
    L.pdfCreateCheckBox(pdf, b"", b"R2", 0, r, 540.0, y, 20.0, 20.0)
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
