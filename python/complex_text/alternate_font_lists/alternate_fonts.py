# ============================================================================
#  alternate_fonts -- Python (ctypes) port of
#  examples\Vb6\complex_text\alternate_font_lists\alternate_fonts.bas
#  Complex text layout with an alternate font list to improve font
#  substitution. Multi-language text is loaded as UTF-16 and laid out with the
#  wide version of WriteFTextEx().
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

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, "..", "..", "..", "test_files")


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def get_file_buffer(filename):
    # Read raw bytes and decode as UTF-16LE (mirrors the Delphi/VB6 WideString read).
    try:
        with open(filename, "rb") as fh:
            data = fh.read()
    except OSError:
        return ""
    return data.decode("utf-16-le", "replace")


def main():
    fonts = [
        "Malgun Gothic",   # Korean
        "Mangal",          # Hindi or Marathi
        "Nyala",           # Amharic
        "Shonar Bangla",   # Bengali
        "Shruti",          # Gujarati
    ]

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # no PDF file is created here (output opened later)

    txt = get_file_buffer(os.path.join(TEST, "multi_lang.txt"))

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    # Enable complex text layout
    L.pdfSetGStateFlags(pdf, L.gfComplexText, 0)

    # Provide an alternate font list.
    alt_fonts = L.pdfCreateAltFontList(pdf)
    arr = (ctypes.c_wchar_p * len(fonts))(*fonts)
    L.pdfSetAltFontsW(pdf, alt_fonts, ctypes.cast(arr, ctypes.c_void_p), len(fonts))

    L.pdfAppend(pdf)

    # The font must be loaded with cpUnicode.
    L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 10.0, 1, L.cpUnicode)
    # Activate the alternate font list
    L.pdfActivateAltFontList(pdf, alt_fonts, 1)

    L.pdfSetLeading(pdf, L.pdfGetTypoLeading(pdf))
    L.pdfWriteFTextExW(pdf, 50.0, 50.0, L.pdfGetPageWidth(pdf) - 100.0,
                       L.pdfGetPageHeight(pdf) - 100.0, L.taJustify, txt)

    L.pdfEndPage(pdf)

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
    if L.pdfCloseFile(pdf) != 0:
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
