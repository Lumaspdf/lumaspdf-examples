# ============================================================================
#  annotation_types -- Python (ctypes) port of
#  examples\Vb6\annotations\annotation_types\annotation_types.bas
#  A tour of annotation types: highlight family, circle/square, text (note),
#  file attachment, free text (+callout) and line annotations with every
#  line-end style.
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

clYellow = 65535
clRed = 255
clCream = 15793151
clBlack = 0
clGray = 8421504


def RGB(r, g, b):
    return r | (g << 8) | (b << 16)


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


# Delphi AddHighlightAnnot helper.
def add_highlight_annot(pdf, annot_type, color, x, y, text, subject, comment):
    w = L.pdfGetTextWidthA(pdf, text)
    L.pdfWriteTextA(pdf, x, y, text)
    L.pdfHighlightAnnotA(pdf, annot_type, x, y + L.pdfGetDescent(pdf), w, 20.0, color, b"Test app", subject, comment)


def main():
    cr = chr(13)

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)

    y = 50.0
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 20.0, 0, L.cp1252)
    add_highlight_annot(pdf, L.atHighlight, clYellow, 50.0, y, b"Highlight Annotation", b"Highlight Annotations", b"This is a highlight annotation")
    add_highlight_annot(pdf, L.atSquiggly, clRed, 300.0, y, b"Squiggly Annotation", b"Highlight Annotations", b"This is a squiggly annotation")
    y = y + 30.0
    add_highlight_annot(pdf, L.atStrikeOut, clRed, 50.0, y, b"Strikeout Annotation", b"Highlight Annotations", b"This is a strikeout annotation")
    add_highlight_annot(pdf, L.atUnderline, clRed, 300.0, y, b"Underline Annotation", b"Highlight Annotations", b"This is a underline annotation")

    y = y + 40.0
    L.pdfCircleAnnotA(pdf, 50.0, y, 200.0, 100.0, 1.0, clCream, clBlack, L.csDeviceRGB, b"Test app", b"Circle Annotations", b"This is a circle annotation")
    L.pdfSquareAnnotA(pdf, 300.0, y, 200.0, 100.0, 1.0, clCream, clBlack, L.csDeviceRGB, b"Test app", b"Square Annotations", b"This is a square annotation")

    y = y + 130.0
    L.pdfChangeFontSize(pdf, 12.0)
    txt = ("The icon color of text and file attachment annotations can be changed if "
           "necessary with SetAnnotColor(). The background color must be set." + cr + cr + "Text Annotations:")
    L.pdfWriteFTextExA(pdf, 50.0, y, L.pdfGetPageWidth(pdf) - 100.0, -1.0, L.taLeft, txt.encode("latin-1", "replace"))

    y = L.pdfGetPageHeight(pdf) - L.pdfGetLastTextPosY(pdf) + 10.0
    # The default icon color can be changed if necessary
    L.pdfTextAnnotA(pdf, 50.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiComment, 0)
    a = L.pdfTextAnnotA(pdf, 100.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiHelp, 0)
    L.pdfSetAnnotColor(pdf, a, L.fcBackColor, L.csDeviceRGB, RGB(200, 20, 30))

    L.pdfTextAnnotA(pdf, 150.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiInsert, 0)
    a = L.pdfTextAnnotA(pdf, 200.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiKey, 0)
    L.pdfSetAnnotColor(pdf, a, L.fcBackColor, L.csDeviceRGB, RGB(50, 200, 30))
    L.pdfTextAnnotA(pdf, 250.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiNewParagraph, 0)
    a = L.pdfTextAnnotA(pdf, 300.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiNote, 0)
    L.pdfSetAnnotColor(pdf, a, L.fcBackColor, L.csDeviceRGB, RGB(70, 120, 210))
    L.pdfTextAnnotA(pdf, 350.0, y, 200.0, 100.0, b"Test app", b"This is a text annotation", L.aiParagraph, 0)

    y = y + 50.0
    L.pdfWriteTextA(pdf, 50.0, y, b"File Attachment Annotations:")

    y = y + 20.0
    L.pdfFileAttachAnnotA(pdf, 50.0, y, L.faiGraph, b"Test app", b"An example attachment", b"../../../test_files/gdi.emf", 1)
    L.pdfFileAttachAnnotA(pdf, 100.0, y, L.faiPaperClip, b"Test app", b"An example attachment", b"../../../test_files/gdi.emf", 1)
    a = L.pdfFileAttachAnnotA(pdf, 150.0, y, L.faiPushPin, b"Test app", b"An example attachment", b"../../../test_files/gdi.emf", 1)
    L.pdfSetAnnotColor(pdf, a, L.fcBackColor, L.csDeviceRGB, RGB(70, 120, 210))
    L.pdfFileAttachAnnotA(pdf, 200.0, y, L.faiTag, b"Test app", b"An example attachment", b"../../../test_files/gdi.emf", 1)

    y = y + 60.0
    a = L.pdfFreeTextAnnotA(pdf, 50.0, y, 200.0, 80.0, b"Test app", b"This is a FreeText Annotation.", L.taCenter)
    L.pdfSetAnnotBorderWidth(pdf, a, 3.0)
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, clGray)

    a = L.pdfFreeTextAnnotA(pdf, 400.0, y, 150.0, 45.0, b"Test app", b"This is a FreeText Callout Annotation with a cloudy border.", L.taCenter)
    L.pdfSetAnnotBorderWidth(pdf, a, 2.0)
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, clRed)
    L.pdfSetAnnotBorderEffect(pdf, a, L.beCloudy1)
    L.pdfConvToFreeTextCallout(pdf, a, 300.0, y + 40.0, 30.0, L.leOpenArrow)

    y = y + 120.0
    L.pdfWriteTextA(pdf, 50.0, y, b"Line Annotations:")

    for le in (L.leNone, L.leButt, L.leCircle, L.leClosedArrow, L.leRClosedArrow,
               L.leDiamond, L.leOpenArrow, L.leROpenArrow, L.leSlash, L.leSquare):
        y = y + (30.0 if le == L.leNone else 20.0)
        L.pdfLineAnnotA(pdf, 50.0, y, 350.0, y, 1.0, le, le, clRed, clBlack, L.csDeviceRGB, b"Test app", b"Line Annotations", b"This is a line annotation")

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
