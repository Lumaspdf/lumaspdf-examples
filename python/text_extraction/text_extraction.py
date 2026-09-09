import sys, os, ctypes
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

# text_extraction -- Python (ctypes) port of the VB6 mirror.
# Imports a PDF and extracts its text via pdfGetPageText()/TPDFStack,
# rebuilding text lines and word boundaries by transforming each text
# record to user space. Output out.txt is UTF-16LE (with BOM).

HERE = os.path.dirname(os.path.abspath(__file__))

# TTextDir
tfNotInitialized = 5
MAX_LINE_ERROR = 4.0  # square of the allowed error (2*2)

# module state (was the CPDFToText helper class)
m_PDF = 0
m_File = None
m_Stack = L.TPDFStack()
m_LastTextDir = tfNotInitialized
m_LastTextEndX = 0.0
m_LastTextEndY = 0.0
m_LastTextInfX = 0.0
m_LastTextInfY = 0.0

m_Templates = []


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_cb = L.TErrorProc(_err)  # keep global ref


# ------------------------- output helpers -------------------------
def WriteWStr(s):
    if s:
        m_File.write(s.encode('utf-16-le'))


def WriteWCharsFromPtr(ptr, wchar_count):
    if ptr and wchar_count > 0:
        m_File.write(ctypes.string_at(ptr, wchar_count * 2))


# ------------------------- matrix helpers -------------------------
def MulMatrix(M1, M2):
    # M1, M2 are TCTM; return (a,b,c,d,x,y)
    a = M2.a * M1.a + M2.b * M1.c
    b = M2.a * M1.b + M2.b * M1.d
    c = M2.c * M1.a + M2.d * M1.c
    d = M2.c * M1.b + M2.d * M1.d
    x = M2.x * M1.a + M2.y * M1.c + M1.x
    y = M2.x * M1.b + M2.y * M1.d + M1.y
    return (a, b, c, d, x, y)


def Transform(M, x, y):
    a, b, c, d, mx, my = M
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
    if denom == 0.0:
        return True
    di = (x * dx + y * dy) / denom
    if di < 0.0:
        di = 0.0
    elif di > 1.0:
        di = 1.0
    dx = x - di * dx
    dy = y - di * dy
    di = dx * dx + dy * dy
    return di < MAX_LINE_ERROR


# ------------------------- text reconstruction -------------------------
def AddText():
    global m_LastTextDir, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY

    m = MulMatrix(m_Stack.ctm, m_Stack.tm)
    x1, y1 = Transform(m, 0.0, 0.0)           # start point of text record
    x2, y2 = Transform(m, 0.0, m_Stack.FontSize)  # second point -> direction

    if y1 == y2:
        textDir = ((1 if x1 > x2 else 0) + 1) * 2
    else:
        textDir = 1 if y1 > y2 else 0

    if (textDir != m_LastTextDir) or (not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)):
        m_LastTextInfX, m_LastTextInfY = Transform(m, 1000000.0, 0.0)
        if m_LastTextDir != tfNotInitialized:
            WriteWStr("\r\n")
    else:
        x3, y3 = Transform(m, m_Stack.SpaceWidth, 0.0)
        spaceWidth = CalcDistance(x1, y1, x3, y3)
        distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1)
        if distance > spaceWidth:
            WriteWStr(" ")

    spw = -m_Stack.SpaceWidth * 0.5
    recs = ctypes.cast(m_Stack.Kerning, ctypes.POINTER(L.TTextRecordW))
    for i in range(m_Stack.KerningCount):
        rec = recs[i]
        if rec.Advance < spw:
            WriteWStr(" ")
        WriteWCharsFromPtr(rec.Text, rec.Length)

    ex, ey = Transform(m, m_Stack.TextWidth + spw, 0.0)  # spw is negative
    m_LastTextEndX = ex
    m_LastTextEndY = ey
    m_LastTextDir = textDir


def ParseText():
    haveMore = (L.pdfGetPageText(m_PDF, ctypes.byref(m_Stack)) != 0)
    if (not haveMore) and (m_Stack.TextLen == 0):
        return
    AddText()
    if haveMore:
        while L.pdfGetPageText(m_PDF, ctypes.byref(m_Stack)) != 0:
            AddText()


def ParseTemplates():
    tmplCount = L.pdfGetTemplCount(m_PDF)
    for i in range(tmplCount):
        if L.pdfEditTemplate(m_PDF, i) == 0:
            return
        tmpl = L.pdfGetTemplHandle(m_PDF)
        if tmpl not in m_Templates:
            m_Templates.append(tmpl)
            if L.pdfInitStack(m_PDF, ctypes.byref(m_Stack)) == 0:
                return
            ParseText()
            tmplCount2 = L.pdfGetTemplCount(m_PDF)
            for _j in range(tmplCount2):
                ParseTemplates()
            L.pdfEndTemplate(m_PDF)
        else:
            L.pdfEndTemplate(m_PDF)


def ParsePage():
    global m_LastTextEndX, m_LastTextEndY, m_LastTextDir, m_LastTextInfX, m_LastTextInfY, m_Templates
    m_Templates = []
    if L.pdfInitStack(m_PDF, ctypes.byref(m_Stack)) == 0:
        em = L.pdfGetErrorMessage(m_PDF)
        if em:
            print(em.decode('latin-1', 'replace'))
        return
    m_LastTextEndX = 0.0
    m_LastTextEndY = 0.0
    m_LastTextDir = tfNotInitialized
    m_LastTextInfX = 0.0
    m_LastTextInfY = 0.0
    ParseText()
    ParseTemplates()


def main():
    global m_PDF, m_File

    m_PDF = L.pdfNewPDF()
    L.pdfCreateNewPDFA(m_PDF, b"")
    L.pdfSetOnErrorProc(m_PDF, 0, _cb)

    L.pdfSetCMapDirA(m_PDF, os.path.join(HERE, "CMap").encode('latin-1'),
                     L.lcmRecursive | L.lcmDelayed)

    L.pdfSetImportFlags(m_PDF, L.ifImportAll | L.ifImportAsPage)

    inFile = os.path.join(HERE, "in.pdf")
    if L.pdfOpenImportFileA(m_PDF, inFile.encode('latin-1'), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(m_PDF)
        return
    L.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0)
    L.pdfCloseImportFile(m_PDF)

    L.pdfFlattenAnnots(m_PDF, L.affMarkupAnnots)
    L.pdfFlattenForm(m_PDF)

    outFile = os.path.join(HERE, "out.txt")
    m_File = open(outFile, "wb")
    m_File.write(bytes((255, 254)))  # UTF-16LE BOM

    for i in range(1, L.pdfGetPageCount(m_PDF) + 1):
        L.pdfEditPage(m_PDF, i)
        WriteWStr(("\r\n" if i > 1 else "") +
                  "%%----------------------- Page %d -----------------------------\r\n" % i)
        ParsePage()
        L.pdfEndPage(m_PDF)
    m_File.close()

    print("Text successfully extracted to " + outFile)
    L.pdfDeletePDF(m_PDF)


if __name__ == "__main__":
    main()
