# ============================================================================
#  text_coordinates -- Python (ctypes) port of
#  examples\Vb6\content_parser\text_coordinates\text_coordinates.bas
#
#  Imports dynapdf_help.pdf, then for every page runs pdfParseContent with a
#  callback interface. The MarkText callback draws lines under each text record
#  to visualise the computed text coordinates, alternating the stroke colour
#  blue/red for successive text records. Output is out.pdf.
#
#  The Delphi/VB6 OO helper (CTextCoordinates + CStack) is flattened to
#  module-level globals; the callback Data pointer is ignored.
# ============================================================================
import os
import sys
import ctypes
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

HERE = os.path.dirname(os.path.abspath(__file__))
IN_PDF = _here('dynapdf_help.pdf')

clRed = 0xFF
clBlue = 0xFF0000

IDENT = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


class GState:
    __slots__ = ("ActiveFont", "CharSpacing", "FontSize", "FontType", "Matrix",
                 "SpaceWidth", "TextDrawMode", "TextScale", "WordSpacing")

    def __init__(self):
        self.ActiveFont = 0
        self.CharSpacing = 0.0
        self.FontSize = 1.0
        self.FontType = L.ftType1
        self.Matrix = IDENT
        self.SpaceWidth = 0.0
        self.TextDrawMode = L.dmNormal
        self.TextScale = 100.0
        self.WordSpacing = 0.0

    def copy(self):
        g = GState()
        for f in self.__slots__:
            setattr(g, f, getattr(self, f))
        return g

    def assign(self, o):
        for f in self.__slots__:
            setattr(self, f, getattr(o, f))


# ------------------------- module state -------------------------
m_PDF = 0
m_Count = 0
G = GState()
m_Stack = []


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


# ------------------------- matrix helpers -------------------------
def _mtuple(ptr_ctm):
    m = ptr_ctm[0]
    return (m.a, m.b, m.c, m.d, m.x, m.y)


def MulMatrix(m1, m2):
    a1, b1, c1, d1, x1, y1 = m1
    a2, b2, c2, d2, x2, y2 = m2
    return (
        a2 * a1 + b2 * c1,
        a2 * b1 + b2 * d1,
        c2 * a1 + d2 * c1,
        c2 * b1 + d2 * d1,
        x2 * a1 + y2 * c1 + x1,
        x2 * b1 + y2 * d1 + y1,
    )


def Transform(m, x, y):
    a, b, c, d, mx, my = m
    return (x * a + y * c + mx, x * b + y * d + my)


# ------------------------- CStack -------------------------
def RestoreGState():
    if m_Stack:
        G.assign(m_Stack.pop())
        return True
    return False


def SaveGState():
    m_Stack.append(G.copy())
    return 0


def ResetGState():
    G.ActiveFont = 0
    G.CharSpacing = 0.0
    G.FontSize = 1.0
    G.FontType = L.ftType1
    G.Matrix = IDENT
    G.TextDrawMode = L.dmNormal
    G.TextScale = 100.0
    G.WordSpacing = 0.0


def TCInit():
    global m_Count
    while RestoreGState():
        pass
    m_Count = 0
    ResetGState()


# ------------------------- font width helper -------------------------
def text_width(font, text_ptr, length, cs, ws, ts):
    if length <= 0 or not text_ptr:
        return 0.0
    data = ctypes.string_at(text_ptr, length)
    return L.fntGetTextWidth(font, data, length, cs, ws, ts)


# ------------------------- MarkText -------------------------
def MarkText(matrix_t, source, kerning, count, awidth, decoded):
    global m_Count
    if decoded == 0:
        return 0

    x1 = 0.0
    y1 = 0.0
    m = MulMatrix(G.Matrix, matrix_t)
    x1, y1 = Transform(m, x1, y1)

    text_width_acc = 0.0
    if G.FontType == L.ftType0:
        recs = ctypes.cast(kerning, ctypes.POINTER(L.TTextRecordW))
        for i in range(count):
            krec = recs[i]
            if krec.Advance != 0.0:
                text_width_acc -= krec.Advance
                x1, y1 = Transform(m, text_width_acc, 0.0)
            text_width_acc += krec.Width
            x2, y2 = Transform(m, text_width_acc, 0.0)
            L.pdfMoveTo(m_PDF, x1, y1)
            L.pdfLineTo(m_PDF, x2, y2)
            if (m_Count & 1) != 0:
                L.pdfSetStrokeColor(m_PDF, clRed)
            else:
                L.pdfSetStrokeColor(m_PDF, clBlue)
            if L.pdfStrokePath(m_PDF) == 0:
                return -1
            x1, y1 = x2, y2
    else:
        recs = ctypes.cast(source, ctypes.POINTER(L.TTextRecordA))
        x2 = x1
        y2 = y1
        for i in range(count):
            srec = recs[i]
            if srec.Advance != 0.0:
                text_width_acc -= srec.Advance
                x1, y1 = Transform(m, text_width_acc, 0.0)
            rlen = srec.Length
            if not srec.Text:
                rlen = 0
            srcbytes = ctypes.string_at(srec.Text, rlen) if rlen > 0 else b""
            base = srec.Text
            j = 0
            last = 0
            while j < rlen:
                if srcbytes[j] != 32:
                    j += 1
                else:
                    if j > last:
                        text_width_acc += text_width(G.ActiveFont, base + last, j - last,
                                                     G.CharSpacing, G.WordSpacing, G.TextScale)
                        x2, y2 = Transform(m, text_width_acc, 0.0)
                        L.pdfMoveTo(m_PDF, x1, y1)
                        L.pdfLineTo(m_PDF, x2, y2)
                        if (m_Count & 1) != 0:
                            L.pdfSetStrokeColor(m_PDF, clRed)
                        else:
                            L.pdfSetStrokeColor(m_PDF, clBlue)
                        if L.pdfStrokePath(m_PDF) == 0:
                            return -1
                    last = j
                    j += 1
                    while j < rlen and srcbytes[j] == 32:
                        j += 1
                    text_width_acc += text_width(G.ActiveFont, base + last, j - last,
                                                 G.CharSpacing, G.WordSpacing, G.TextScale)
                    last = j
                    x1, y1 = Transform(m, text_width_acc, 0.0)
            if j > last:
                text_width_acc += text_width(G.ActiveFont, base + last, j - last,
                                             G.CharSpacing, G.WordSpacing, G.TextScale)
                x2, y2 = Transform(m, text_width_acc, 0.0)
                L.pdfMoveTo(m_PDF, x1, y1)
                L.pdfLineTo(m_PDF, x2, y2)
                if (m_Count & 1) != 0:
                    L.pdfSetStrokeColor(m_PDF, clRed)
                else:
                    L.pdfSetStrokeColor(m_PDF, clBlue)
                if L.pdfStrokePath(m_PDF) == 0:
                    return -1
            x1, y1 = x2, y2
    m_Count += 1
    return 0


# ------------------------- parse* callback thunks -------------------------
@L.TBeginTemplate
def parse_begin_template(data, pdfobject, handle, bbox, matrix):
    if SaveGState() < 0:
        return -1
    if matrix:
        ctm = ctypes.cast(matrix, ctypes.POINTER(L.TCTM))
        G.Matrix = MulMatrix(G.Matrix, _mtuple(ctm))
    return 0


@L.TEndTemplate
def parse_end_template(data):
    RestoreGState()


@L.TMulMatrix
def parse_mul_matrix(data, pdfobject, matrix):
    G.Matrix = MulMatrix(G.Matrix, _mtuple(matrix))


@L.TRestoreGraphicState
def parse_restore_gstate(data):
    RestoreGState()
    return 0


@L.TSaveGraphicState
def parse_save_gstate(data):
    SaveGState()
    return 0


@L.TSetCharSpacing
def parse_set_charspacing(data, pdfobject, value):
    G.CharSpacing = value


@L.TSetFont
def parse_set_font(data, pdfobject, fonttype, embedded, fontname, style, fontsize, font):
    G.ActiveFont = font
    G.FontSize = fontsize
    G.FontType = fonttype
    G.SpaceWidth = L.fntGetSpaceWidth(font, fontsize)


@L.TSetTextDrawMode
def parse_set_textdrawmode(data, pdfobject, mode):
    G.TextDrawMode = mode


@L.TSetTextScale
def parse_set_textscale(data, pdfobject, value):
    G.TextScale = value


@L.TSetWordSpacing
def parse_set_wordspacing(data, pdfobject, value):
    G.WordSpacing = value


@L.TShowTextArrayW
def parse_show_text_array_w(data, source, matrix, kerning, count, width, decoded):
    return MarkText(_mtuple(matrix), source, kerning, count, width, decoded)


def main():
    global m_PDF, m_Count
    stack = L.TPDFParseInterface()
    stack.BeginTemplate = ctypes.cast(parse_begin_template, ctypes.c_void_p)
    stack.EndTemplate = ctypes.cast(parse_end_template, ctypes.c_void_p)
    stack.MulMatrix = ctypes.cast(parse_mul_matrix, ctypes.c_void_p)
    stack.RestoreGraphicState = ctypes.cast(parse_restore_gstate, ctypes.c_void_p)
    stack.SaveGraphicState = ctypes.cast(parse_save_gstate, ctypes.c_void_p)
    stack.SetCharSpacing = ctypes.cast(parse_set_charspacing, ctypes.c_void_p)
    stack.SetFont = ctypes.cast(parse_set_font, ctypes.c_void_p)
    stack.SetTextDrawMode = ctypes.cast(parse_set_textdrawmode, ctypes.c_void_p)
    stack.SetTextScale = ctypes.cast(parse_set_textscale, ctypes.c_void_p)
    stack.SetWordSpacing = ctypes.cast(parse_set_wordspacing, ctypes.c_void_p)
    stack.ShowTextArrayW = ctypes.cast(parse_show_text_array_w, ctypes.c_void_p)

    m_PDF = L.pdfNewPDF()
    m_Count = 0
    ResetGState()

    L.pdfSetOnErrorProc(m_PDF, 0, err_proc)
    L.pdfCreateNewPDFA(m_PDF, b"")

    cmap = os.path.join(HERE, "CMap")
    L.pdfSetCMapDirA(m_PDF, cmap.encode("latin-1"), L.lcmRecursive | L.lcmDelayed)

    L.pdfSetImportFlags(m_PDF, L.ifImportAll | L.ifImportAsPage)

    if L.pdfOpenImportFileA(m_PDF, IN_PDF.encode("latin-1"), L.ptOpen, b"") < 0:
        print('Input file "' + IN_PDF + '" not found!')
        L.pdfDeletePDF(m_PDF)
        return
    if L.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0) < 0:
        L.pdfDeletePDF(m_PDF)
        return

    L.pdfFlattenAnnots(m_PDF, L.affMarkupAnnots)
    L.pdfFlattenForm(m_PDF)

    for i in range(1, L.pdfGetPageCount(m_PDF) + 1):
        L.pdfEditPage(m_PDF, i)
        L.pdfSetLineWidth(m_PDF, 0.5)
        TCInit()
        L.pdfParseContent(m_PDF, 0, stack, L.pfNone)
        L.pdfEndPage(m_PDF)

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(m_PDF) != 0:
        if L.pdfOpenOutputFileA(m_PDF, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(m_PDF)
            return
    if L.pdfCloseFile(m_PDF) != 0:
        print('PDF file "' + out_file + '" successfully created!')

    L.pdfDeletePDF(m_PDF)


if __name__ == "__main__":
    main()
