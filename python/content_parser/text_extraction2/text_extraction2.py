# ============================================================================
#  text_extraction2 -- Python (ctypes) port of
#    examples\Vb6\content_parser\text_extraction2\text_extraction2.bas
#
#  Extracts the text of a PDF file by driving pdfParseContent() with a
#  TPDFParseInterface struct of callbacks. The Delphi/VB6 CPDFToText + CStack
#  helpers are flattened to module-level globals (one parser instance); the
#  Data pointer in every callback is ignored. Output is out.txt as UTF-16LE
#  (with BOM).
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
IN_PDF = _here('sample_multipage.pdf')

# TTextDir
tfNotInitialized = 5
MAX_LINE_ERROR = 4.0  # square of the allowed error (2*2)

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
m_File = None
G = GState()
m_Stack = []
m_LastTextDir = tfNotInitialized
m_LastTextEndX = 0.0
m_LastTextEndY = 0.0
m_LastTextInfX = 0.0
m_LastTextInfY = 0.0


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


# ------------------------- output helpers -------------------------
def WriteWStr(s):
    if s:
        m_File.write(s.encode("utf-16-le"))


def WriteWCharsFromPtr(ptr, wchar_count):
    if ptr and wchar_count > 0:
        m_File.write(ctypes.string_at(ptr, wchar_count * 2))


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


def CalcDistance(x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    return (dx * dx + dy * dy) ** 0.5


def IsPointOnLine(x, y, x0, y0, x1, y1):
    x = x - x0
    y = y - y0
    dx = x1 - x0
    dy = y1 - y0
    denom = dx * dx + dy * dy
    if denom == 0.0:                # div-by-zero guard (degenerate segment)
        return (x * x + y * y) < MAX_LINE_ERROR
    di = (x * dx + y * dy) / denom
    if di < 0.0:
        di = 0.0
    elif di > 1.0:
        di = 1.0
    dx = x - di * dx
    dy = y - di * dy
    di = dx * dx + dy * dy
    return di < MAX_LINE_ERROR


# ------------------------- CStack -------------------------
def DoRestoreGState():
    if m_Stack:
        G.assign(m_Stack.pop())
        return True
    return False


def DoSaveGState():
    m_Stack.append(G.copy())
    return 0


def ResetGState():
    G.ActiveFont = 0
    G.CharSpacing = 0.0
    G.FontSize = 1.0
    G.FontType = L.ftType1
    G.Matrix = IDENT
    G.SpaceWidth = 0.0
    G.TextDrawMode = L.dmNormal
    G.TextScale = 100.0
    G.WordSpacing = 0.0


def DoInit():
    global m_LastTextDir, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY
    while DoRestoreGState():
        pass
    ResetGState()
    m_LastTextDir = tfNotInitialized
    m_LastTextEndX = 0.0
    m_LastTextEndY = 0.0
    m_LastTextInfX = 0.0
    m_LastTextInfY = 0.0


def DoSetFont(font, fonttype, fontsize):
    G.ActiveFont = font
    G.FontSize = fontsize
    G.FontType = fonttype
    G.SpaceWidth = L.fntGetSpaceWidth(font, fontsize)
    if fontsize < 0.0:
        G.SpaceWidth = -G.SpaceWidth


def DoWritePageIdentifier(page_num):
    if page_num > 1:
        WriteWStr("\r\n")
    WriteWStr("%%----------------------- Page %d -----------------------------\r\n" % page_num)


# ------------------------- text reconstruction -------------------------
def DoAddText(matrix_t, kerning, count, widen, decoded):
    global m_LastTextDir, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY
    if decoded == 0:
        return 0

    m = MulMatrix(G.Matrix, matrix_t)
    x1, y1 = Transform(m, 0.0, 0.0)
    x2, y2 = Transform(m, 0.0, G.FontSize)
    if y1 == y2:
        text_dir = ((1 if x1 > x2 else 0) + 1) * 2
    else:
        text_dir = 1 if y1 > y2 else 0

    if (text_dir != m_LastTextDir) or (not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY,
                                                         m_LastTextInfX, m_LastTextInfY)):
        m_LastTextInfX, m_LastTextInfY = Transform(m, 1000000.0, 0.0)
        if m_LastTextDir != tfNotInitialized:
            WriteWStr("\r\n")
    else:
        x3, y3 = Transform(m, G.SpaceWidth, 0.0)
        space_width = CalcDistance(x1, y1, x3, y3)
        distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1)
        if distance > space_width:
            WriteWStr(" ")

    spw = -G.SpaceWidth * 0.5
    recs = ctypes.cast(kerning, ctypes.POINTER(L.TTextRecordW))
    for i in range(count):
        rec = recs[i]
        if rec.Advance < spw:
            WriteWStr(" ")
        WriteWCharsFromPtr(rec.Text, rec.Length)

    m_LastTextEndX, m_LastTextEndY = Transform(m, widen + spw, 0.0)  # spw is negative
    m_LastTextDir = text_dir
    return 0


# ------------------------- parse* callback thunks -------------------------
@L.TBeginTemplate
def parse_begin_template(data, pdfobject, handle, bbox, matrix):
    if DoSaveGState() < 0:
        return -1
    if matrix:
        ctm = ctypes.cast(matrix, ctypes.POINTER(L.TCTM))
        G.Matrix = MulMatrix(G.Matrix, _mtuple(ctm))
    return 0


@L.TEndTemplate
def parse_end_template(data):
    DoRestoreGState()


@L.TMulMatrix
def parse_mul_matrix(data, pdfobject, matrix):
    G.Matrix = MulMatrix(G.Matrix, _mtuple(matrix))


@L.TRestoreGraphicState
def parse_restore_gstate(data):
    DoRestoreGState()
    return 0


@L.TSaveGraphicState
def parse_save_gstate(data):
    DoSaveGState()
    return 0


@L.TSetCharSpacing
def parse_set_charspacing(data, pdfobject, value):
    G.CharSpacing = value


@L.TSetFont
def parse_set_font(data, pdfobject, fonttype, embedded, fontname, style, fontsize, font):
    DoSetFont(font, fonttype, fontsize)


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
    return DoAddText(_mtuple(matrix), kerning, count, width, decoded)


def main():
    global m_PDF, m_File
    m_PDF = L.pdfNewPDF()
    L.pdfSetOnErrorProc(m_PDF, 0, err_proc)
    L.pdfCreateNewPDFA(m_PDF, b"")

    L.pdfSetCMapDirA(m_PDF, os.path.join(HERE, "CMap").encode("latin-1"),
                     L.lcmRecursive | L.lcmDelayed)

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

    out_file = os.path.join(HERE, "out.txt")
    m_File = open(out_file, "wb")
    m_File.write(bytes((255, 254)))  # UTF-16LE BOM

    for i in range(1, L.pdfGetPageCount(m_PDF) + 1):
        L.pdfEditPage(m_PDF, i)
        DoInit()
        DoWritePageIdentifier(i)
        L.pdfParseContent(m_PDF, 0, stack, L.pfNone)
        L.pdfEndPage(m_PDF)
    m_File.close()

    print("Text successfully extracted to " + out_file)
    L.pdfDeletePDF(m_PDF)


if __name__ == "__main__":
    main()
