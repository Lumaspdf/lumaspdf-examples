# ============================================================================
#  image_extraction -- Python (ctypes) port of
#  examples\Vb6\content_parser\image_extraction\image_extraction.bas
#  Imports sample_multipage.pdf and extracts every image into a multi-page TIFF by
#  parsing each page's content stream. The InsertImage callback re-adds each
#  decompressed image (CCITT4 for 1bpp, LZW otherwise); templates and image
#  objects are de-duplicated so each is handled once.
#  The flat API passes the pdf handle as the parser Data pointer, so Data IS
#  the pdf handle here.
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

# De-dup lists (Delphi used two TList of pointers)
m_Images = set()
m_Templates = set()


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


# ------------------------- parse callbacks -------------------------
@L.TBeginTemplate
def parse_begin_template(data, pdfobject, handle, bbox, matrix):
    if handle in m_Templates:
        return 1  # skip the template
    m_Templates.add(handle)
    return 0


@L.TInsertImage
def parse_insert_image(data, image_ptr):
    img = image_ptr[0]
    if img.InlineImage == 0:
        key = img.ObjectPtr
        if key in m_Images:  # already handled?
            return 0
        m_Images.add(key)
    # A compressed image can arrive if it could not be decompressed.
    if img.Filter != L.dfNone:
        return 0
    # Note that Flate compression is no standard filter.
    if img.BitsPerPixel == 1:
        L.pdfAddImage(data, L.cfCCITT4, L.icNone, image_ptr)
    else:
        L.pdfAddImage(data, L.cfLZW, L.icNone, image_ptr)
    return 0


def main():
    stack = L.TPDFParseInterface()
    stack.BeginTemplate = ctypes.cast(parse_begin_template, ctypes.c_void_p)
    stack.InsertImage = ctypes.cast(parse_insert_image, ctypes.c_void_p)

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # no PDF file is created here

    # Avoid the conversion of pages to templates
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
    if L.pdfOpenImportFileA(pdf, IN_PDF.encode("latin-1"), L.ptOpen, b"") < 0:
        print('Input file "sample_multipage.pdf" not found!')
        L.pdfDeletePDF(pdf)
        return
    if L.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0:
        L.pdfDeletePDF(pdf)
        return
    # Flatten form fields so images of these objects are extracted too.
    L.pdfFlattenForm(pdf)

    out_file = os.path.join(HERE, "out.tif")

    # Create a multi-page TIFF.
    if L.pdfCreateImageA(pdf, out_file.encode("latin-1"), L.ifmTIFF) == 0:
        L.pdfDeletePDF(pdf)
        return
    for i in range(1, L.pdfGetPageCount(pdf) + 1):
        L.pdfEditPage(pdf, i)
        # The pdf handle is passed as the parser Data.
        L.pdfParseContent(pdf, pdf, stack, L.pfDecomprAllImages)
        L.pdfEndPage(pdf)
    if L.pdfCloseImage(pdf) != 0:
        print('TIFF image "' + out_file + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
