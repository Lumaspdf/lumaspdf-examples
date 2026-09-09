# ============================================================================
#  checkconformance -- Python (ctypes) port of
#  examples\Vb6\pdfa_extension\checkconformance\checkconformance.bas
#  Imports a PDF and converts it to PDF/A-3b via CheckConformance, using
#  callbacks to replace missing fonts and ICC profiles, then writes the result.
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
FIXTURE = _here('sample_multipage.pdf')
TEST_FILES = r"test_files"


def cstr(p):
    if not p:
        return ""
    return ctypes.cast(p, ctypes.c_char_p).value.decode("latin-1", "replace")


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


# Data is the PDF handle passed as UserData to CheckConformance.
@L.TOnFontNotFoundProc
def font_not_found(data, pdffont, fontname, style, stdfontidx, is_symbol):
    # Replace with Arial preserving the requested style.
    return L.pdfReplaceFontA(data, pdffont, b"Arial", style, 1)


@L.TOnReplaceICCProfile
def replace_icc(data, profile_type, colorspace):
    if profile_type == L.ictRGB:
        p = os.path.join(TEST_FILES, "sRGB.icc")
    elif profile_type == L.ictCMYK:
        p = os.path.join(TEST_FILES, "ISOcoated_v2_bas.ICC")
    else:
        p = os.path.join(TEST_FILES, "gray.icc")
    return L.pdfReplaceICCProfileA(data, colorspace, p.encode("latin-1"))


def convert_file(pdf, conv_type, in_file, out_file):
    L.pdfCreateNewPDFA(pdf, b"")            # The output file is opened later
    L.pdfSetDocInfoA(pdf, L.diProducer, b"")

    if conv_type == L.ctNormalize:
        conv_flags = L.coAllowDeviceSpaces
    elif conv_type == L.ctPDFA_1b_2005:
        conv_flags = L.coDefault | L.coFlattenLayers
    elif conv_type in (L.ctPDFA_2b, L.ctPDFA_2u):
        conv_flags = L.coDefault | L.coDeletePresentation
    else:
        # ctPDFA_3b etc.: embedded files are allowed.
        conv_flags = (L.coDefault | L.coDeletePresentation) & ~L.coDeleteEmbeddedFiles

    conv_flags |= L.coCheckImages
    conv_flags |= L.coRepairDamagedImages

    if conv_type != L.ctNormalize:
        L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage | L.ifPrepareForPDFA)
        L.pdfSetImportFlags2(pdf, L.if2UseProxy | L.if2DuplicateCheck)
    else:
        L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
        L.pdfSetImportFlags2(pdf, L.if2UseProxy | L.if2DuplicateCheck | L.if2Normalize)

    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        print("Could not open the import file (it may be encrypted)!")
        L.pdfFreePDF(pdf)
        return False
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    retval = L.pdfCheckConformance(pdf, conv_type, conv_flags, pdf, font_not_found, replace_icc)
    if retval == 1:
        L.pdfAddOutputIntentA(pdf, os.path.join(TEST_FILES, "sRGB.icc").encode("latin-1"))
    elif retval == 2:
        L.pdfAddOutputIntentA(pdf, os.path.join(TEST_FILES, "ISOcoated_v2_bas.ICC").encode("latin-1"))
    elif retval == 3:
        L.pdfAddOutputIntentA(pdf, os.path.join(TEST_FILES, "gray.icc").encode("latin-1"))

    e = L.TPDFError()
    e.StructSize = ctypes.sizeof(L.TPDFError)
    for i in range(L.pdfGetErrLogMessageCount(pdf)):
        L.pdfGetErrLogMessage(pdf, i, e)
        if e.Msg:
            print(cstr(e.Msg))

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            return False
        return L.pdfCloseFile(pdf) != 0
    return False


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfSetCMapDirA(pdf, os.path.join(HERE, "CMap").encode("latin-1"), L.lcmDelayed | L.lcmRecursive)
    out_file = os.path.join(HERE, "out.pdf")

    if convert_file(pdf, L.ctPDFA_3b, FIXTURE, out_file):
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
