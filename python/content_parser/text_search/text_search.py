# ============================================================================
#  text_search -- Python (ctypes) port of
#  examples\Vb6\content_parser\text_search\text_search.bas
#
#  Imports sample_multipage.pdf, searches for the Unicode string "PDF" across the
#  content stream via pdfParseContent + a flattened CTextSearch state machine,
#  and draws yellow multiply-blend rectangles over each match. Prints per-page
#  and total hit counts. Output out.pdf.
#
#  The Delphi/VB6 OO helper (CTextSearch) plus graphics-state stack (CStack)
#  are flattened here to module-level globals (single instance; Data ignored).
#  Python 'or'/'and' short-circuit, so the direct translation of the
#  wrongLine test is fine; the div-by-zero guard in IsPointOnLine is kept.
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

tfNotInitialized = 5
MAX_LINE_ERROR = 4.0  # square of the allowed error (2*2)

IDENT = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


class State:
    def __init__(self):
        self.PDF = 0
        # live graphics state
        self.ActiveFont = 0
        self.CharSpacing = 0.0
        self.FontSize = 1.0
        self.FontType = L.ftType1
        self.Matrix = IDENT
        self.SpaceWidth = 0.0
        self.TextDrawMode = L.dmNormal
        self.TextScale = 100.0
        self.WordSpacing = 0.0
        # graphics-state stack
        self.Stack = []
        # search / hit-tracking state
        self.EndX1 = 0.0
        self.EndY1 = 0.0
        self.EndX4 = 0.0
        self.EndY4 = 0.0
        self.HavePos = False
        self.LastTextDir = tfNotInitialized
        self.LastTextInfX = 0.0
        self.LastTextInfY = 0.0
        self.OutBuf = ctypes.create_string_buffer(64)  # 32 WideChars
        self.SearchChars = []
        self.SearchTextLen = 0
        self.SearchPos = 0
        self.SelCount = 0
        self.x1 = 0.0
        self.y1 = 0.0
        self.x4 = 0.0
        self.y4 = 0.0


S = State()


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


# ------------------------- matrix / geometry -------------------------
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
    if denom == 0.0:            # degenerate segment: "on" only if coincident
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


# ------------------------- search string handling -------------------------
def SetSearchText(txt):
    S.SearchTextLen = len(txt)
    S.SearchChars = [ord(c) for c in txt]
    S.SearchPos = 0


def SPCode():
    if S.SearchPos >= S.SearchTextLen:
        return 0
    return S.SearchChars[S.SearchPos]


def Reset_():
    S.HavePos = False
    S.SearchPos = 0


def Compare(text_ptr, length):
    data = ctypes.string_at(text_ptr, length * 2)
    pos = 0
    end = length * 2
    while pos < end:
        wc = data[pos] | (data[pos + 1] << 8)
        if SPCode() != wc:
            S.HavePos = False
            S.SearchPos = 0
            return False
        pos += 2
        S.SearchPos += 1
        if SPCode() == 0:
            S.SearchPos = 0
            return pos == end
    return True


# ------------------------- graphics-state stack -------------------------
def SaveGState():
    S.Stack.append((S.ActiveFont, S.CharSpacing, S.FontSize, S.FontType, S.Matrix,
                    S.SpaceWidth, S.TextDrawMode, S.TextScale, S.WordSpacing))
    return 0


def RestoreGState():
    if S.Stack:
        (S.ActiveFont, S.CharSpacing, S.FontSize, S.FontType, S.Matrix,
         S.SpaceWidth, S.TextDrawMode, S.TextScale, S.WordSpacing) = S.Stack.pop()
        return True
    return False


# ------------------------- rectangle drawing -------------------------
def SetStartCoord(matrix, x):
    S.x1, S.y1 = Transform(matrix, x, 0.0)
    S.x4, S.y4 = Transform(matrix, x, S.FontSize)
    S.HavePos = True


def DrawRectEx(x2, y2, x3, y3):
    L.pdfMoveTo(S.PDF, S.x1, S.y1)
    L.pdfLineTo(S.PDF, x2, y2)
    L.pdfLineTo(S.PDF, x3, y3)
    L.pdfLineTo(S.PDF, S.x4, S.y4)
    S.HavePos = False
    S.SelCount += 1
    return L.pdfClosePath(S.PDF, L.fmFill) != 0


def DrawRect(matrix, endx):
    x2, y2 = Transform(matrix, endx, 0.0)
    x3, y3 = Transform(matrix, endx, S.FontSize)
    return DrawRectEx(x2, y2, x3, y3)


# ------------------------- init / reset -------------------------
def InitGState():
    while RestoreGState():
        pass
    S.ActiveFont = 0
    S.CharSpacing = 0.0
    S.FontSize = 1.0
    S.Matrix = IDENT
    S.SpaceWidth = 0.0
    S.TextDrawMode = L.dmNormal
    S.TextScale = 100.0
    S.WordSpacing = 0.0
    S.LastTextDir = tfNotInitialized
    S.LastTextInfX = 0.0
    S.LastTextInfY = 0.0


def TS_Create():
    S.ActiveFont = 0
    S.CharSpacing = 0.0
    S.FontSize = 1.0
    S.FontType = L.ftType1
    S.Matrix = IDENT
    S.SpaceWidth = 0.0
    S.TextDrawMode = L.dmNormal
    S.TextScale = 100.0
    S.WordSpacing = 0.0
    S.Stack = []


def TS_Init():
    InitGState()
    Reset_()
    S.SelCount = 0


# ------------------------- text-matching core -------------------------
def _signed32(u):
    return u - 0x100000000 if u > 0x7FFFFFFF else u


def MarkSubString(x, matrix, rec):
    # rec is a TTextRecordA (ctypes struct instance). Returns (ok, x).
    i = 0
    space_width2 = -S.SpaceWidth * 6.0
    max_len = rec.Length
    src_ptr = rec.Text
    if rec.Advance < -S.SpaceWidth:
        # If the distance is too large we assume no space was emulated here.
        if (rec.Advance > space_width2) and (SPCode() == 32):
            if not S.HavePos:
                SetStartCoord(matrix, x)
                S.SearchPos += 1
                if SPCode() == 0:
                    if not DrawRect(matrix, x - rec.Advance):
                        return (False, x)
                    Reset_()
            elif SPCode() == 0:
                if not DrawRect(matrix, 0.0):
                    return (False, x)
                Reset_()
            else:
                S.SearchPos += 1
        else:
            Reset_()
    x = x - rec.Advance
    w = ctypes.c_double()
    out_len = ctypes.c_int32()
    decoded = ctypes.c_int32()
    out_ptr = ctypes.cast(S.OutBuf, ctypes.c_void_p)
    while i < max_len:
        chunk = ctypes.string_at(src_ptr + i, max_len - i)
        consumed = L.fntTranslateRawCode(S.ActiveFont, chunk, max_len - i,
                                         ctypes.byref(w), out_ptr,
                                         ctypes.byref(out_len), ctypes.byref(decoded),
                                         S.CharSpacing, S.WordSpacing, S.TextScale)
        c = _signed32(consumed)
        if c <= 0:
            break  # safety: never let i stall
        i += c
        if decoded.value == 0:
            return (True, x)
        if Compare(ctypes.addressof(S.OutBuf), out_len.value):
            if not S.HavePos:
                SetStartCoord(matrix, x)
            x = x + w.value
            if S.SearchPos == 0:
                if not DrawRect(matrix, x - S.CharSpacing):
                    return (False, x)
        else:
            x = x + w.value
    return (True, x)


def MarkText(matrix_t, source, count, width):
    x1 = 0.0
    y1 = 0.0
    x2 = 0.0
    y2 = S.FontSize
    m = MulMatrix(S.Matrix, matrix_t)
    x1, y1 = Transform(m, x1, y1)
    x2, y2 = Transform(m, x2, y2)
    if y1 == y2:
        text_dir = ((1 if x1 > x2 else 0) + 1) * 2
    else:
        text_dir = 1 if y1 > y2 else 0

    wrong_line = False
    if text_dir != S.LastTextDir:
        wrong_line = True
    elif not IsPointOnLine(x1, y1, S.EndX1, S.EndY1, S.LastTextInfX, S.LastTextInfY):
        wrong_line = True

    if wrong_line:
        S.LastTextInfX, S.LastTextInfY = Transform(m, 1000000.0, 0.0)
        Reset_()
    else:
        x3, y3 = Transform(m, S.SpaceWidth, 0.0)
        space_width = CalcDistance(x1, y1, x3, y3)
        distance = CalcDistance(S.EndX1, S.EndY1, x1, y1)
        if distance > space_width:
            if (distance < space_width * 6.0) and (SPCode() == 32):
                if not S.HavePos:
                    S.HavePos = True
                    S.SearchPos += 1
                    if SPCode() == 0:
                        S.x1 = S.EndX1
                        S.y1 = S.EndY1
                        S.x4 = S.EndX4
                        S.y4 = S.EndY4
                        if not DrawRectEx(x1, y1, x2, y2):
                            return -1
                        Reset_()
                elif SPCode() == 32:
                    if not DrawRectEx(x1, y1, x2, y2):
                        return -1
                    Reset_()
                else:
                    S.SearchPos += 1
            else:
                Reset_()

    x = 0.0
    recs = ctypes.cast(source, ctypes.POINTER(L.TTextRecordA))
    for i in range(count):
        ok, x = MarkSubString(x, m, recs[i])
        if not ok:
            return -1
    S.LastTextDir = text_dir
    S.EndX1, S.EndY1 = Transform(m, width, 0.0)
    S.EndX4, S.EndY4 = Transform(m, 0.0, S.FontSize)
    return 0


# ------------------------- CTextSearch methods -------------------------
def BeginTemplate(matrix_ptr):
    if SaveGState() < 0:
        return -1
    if matrix_ptr:
        ctm = ctypes.cast(matrix_ptr, ctypes.POINTER(L.TCTM))
        S.Matrix = MulMatrix(S.Matrix, _mtuple(ctm))
    return 0


def TS_SetFont(font, fonttype, fontsize):
    S.ActiveFont = font
    S.FontSize = fontsize
    S.FontType = fonttype
    S.SpaceWidth = L.fntGetSpaceWidth(font, fontsize) * 0.5


# ------------------------- parse* callback thunks -------------------------
@L.TBeginTemplate
def parse_begin_template(data, pdfobject, handle, bbox, matrix):
    return BeginTemplate(matrix)


@L.TEndTemplate
def parse_end_template(data):
    RestoreGState()


@L.TMulMatrix
def parse_mul_matrix(data, pdfobject, matrix):
    S.Matrix = MulMatrix(S.Matrix, _mtuple(matrix))


@L.TRestoreGraphicState
def parse_restore_gstate(data):
    RestoreGState()
    return 0


@L.TSaveGraphicState
def parse_save_gstate(data):
    return SaveGState()


@L.TSetCharSpacing
def parse_set_charspacing(data, pdfobject, value):
    S.CharSpacing = value


@L.TSetFont
def parse_set_font(data, pdfobject, fonttype, embedded, fontname, style, fontsize, font):
    TS_SetFont(font, fonttype, fontsize)


@L.TSetTextDrawMode
def parse_set_textdrawmode(data, pdfobject, mode):
    S.TextDrawMode = mode


@L.TSetTextScale
def parse_set_textscale(data, pdfobject, value):
    S.TextScale = value


@L.TSetWordSpacing
def parse_set_wordspacing(data, pdfobject, value):
    S.WordSpacing = value


@L.TShowTextArrayA
def parse_show_text_array_a(data, obj, matrix, source, count, width):
    return MarkText(_mtuple(matrix), source, count, width)


def main():
    sel_count = 0
    TS_Create()

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
    stack.ShowTextArrayA = ctypes.cast(parse_show_text_array_a, ctypes.c_void_p)

    S.PDF = L.pdfNewPDF()
    L.pdfSetOnErrorProc(S.PDF, 0, err_proc)
    L.pdfCreateNewPDFA(S.PDF, b"")

    L.pdfSetCMapDirA(S.PDF, os.path.join(HERE, "CMap").encode("latin-1"),
                     L.lcmRecursive | L.lcmDelayed)

    L.pdfSetImportFlags(S.PDF, L.ifImportAll | L.ifImportAsPage)

    if L.pdfOpenImportFileA(S.PDF, IN_PDF.encode("latin-1"), L.ptOpen, b"") < 0:
        print('Input file "' + IN_PDF + '" not found!')
        L.pdfDeletePDF(S.PDF)
        return
    if L.pdfImportPDFFile(S.PDF, 1, 1.0, 1.0) < 0:
        L.pdfDeletePDF(S.PDF)
        return

    L.pdfFlattenAnnots(S.PDF, L.affMarkupAnnots)
    L.pdfFlattenForm(S.PDF)

    SetSearchText("PDF")

    g = L.TPDFExtGState()
    L.pdfInitExtGState(ctypes.byref(g))
    g.BlendMode = L.bmMultiply
    gs = L.pdfCreateExtGState(S.PDF, ctypes.byref(g))

    for i in range(1, L.pdfGetPageCount(S.PDF) + 1):
        L.pdfEditPage(S.PDF, i)
        L.pdfSetExtGState(S.PDF, gs)
        L.pdfSetFillColor(S.PDF, 255 | (255 << 8))  # RGB(255,255,0)
        TS_Init()
        L.pdfParseContent(S.PDF, 0, stack, L.pfNone)
        L.pdfEndPage(S.PDF)
        if S.SelCount > 0:
            sel_count += S.SelCount
            print("Found string on Page: %d %d times!" % (i, S.SelCount))

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(S.PDF) != 0:
        if L.pdfOpenOutputFileA(S.PDF, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(S.PDF)
            return
    if L.pdfCloseFile(S.PDF) != 0:
        print('PDF file "' + out_file + '" successfully created!')
    print("\nFound string in the file %d times!" % sel_count)
    L.pdfDeletePDF(S.PDF)


if __name__ == "__main__":
    main()
