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

# signature_ap -- port of examples\Vb6\signature_ap\signature_ap.bas
# Builds a page with a digitally-signed signature field whose appearance
# template is drawn with normal PDF functions, then signs the file with a
# self-signed certificate.

HERE = os.path.dirname(os.path.abspath(__file__))

ERRPROC = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_int32,
                             ctypes.c_char_p, ctypes.c_int32)


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode("latin-1", "replace"))
    return 0  # try to continue if an error occurs


_cb = ERRPROC(_err)


def RGB(r, g, b):
    return (r & 0xFF) | ((g & 0xFF) << 8) | ((b & 0xFF) << 16)


def main():
    pdf = L.pdfNewPDF()
    L.pdfCreateNewPDFA(pdf, b"")            # output file is opened later
    L.pdfSetOnErrorProc(pdf, 0, _cb)

    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Arial", L.fsNone, 14.0, 1, L.cp1252)
    body = ("This file is digitally signed with a self sign certificate. "
            "The appearance of the signature field is created with normal classic-API functions. However, it "
            "would also be possible to import a PDF page, an EMF file, or an image into the "
            "appearance template.\n\n"
            "When creating an individual signature appearance make sure to place the validation icon "
            "properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon "
            "depends on the Acrobat version with which the file is opened. However, the unscaled size "
            "of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want "
            "but it is usually best to preserve the aspect ratio and the icon must be placed fully "
            "inside the appearance template.")
    L.pdfWriteFTextA(pdf, L.taLeft, body.encode("latin-1"))

    # ---------------------- Signature field appearance ----------------------
    sig_field = L.pdfCreateSigField(pdf, b"Signature", -1, 200.0, 500.0, 200.0, 80.0)
    L.pdfSetFieldColor(pdf, sig_field, L.fcBorderColor, L.csDeviceRGB, L.NO_COLOR)
    # Place the validation icon on the left side of the signature field.
    L.pdfPlaceSigFieldValidateIcon(pdf, sig_field, 0.0, 15.0, 50.0, 50.0)
    # Creates a template that is already opened; must be closed with EndTemplate().
    L.pdfCreateSigFieldAP(pdf, sig_field)

    L.pdfSaveGraphicState(pdf)
    L.pdfRectangle(pdf, 0.0, 0.0, 200.0, 80.0, L.fmNoFill)
    L.pdfClipPath(pdf, L.cmWinding, L.fmNoFill)
    sh = L.pdfCreateAxialShading(pdf, 0.0, 0.0, 200.0, 0.0, 0.5,
                                 RGB(120, 120, 220), RGB(255, 255, 255), 1, 1)
    L.pdfApplyShading(pdf, sh)
    L.pdfRestoreGraphicState(pdf)

    L.pdfSaveGraphicState(pdf)
    L.pdfEllipse(pdf, 50.5, 1.0, 148.5, 78.0, L.fmNoFill)
    L.pdfClipPath(pdf, L.cmWinding, L.fmNoFill)
    sh = L.pdfCreateAxialShading(pdf, 0.0, 0.0, 0.0, 78.0, 2.0,
                                 RGB(255, 255, 255), RGB(120, 120, 220), 1, 1)
    L.pdfApplyShading(pdf, sh)
    L.pdfRestoreGraphicState(pdf)

    L.pdfSetFontA(pdf, b"Arial", L.fsBold | L.fsUnderlined, 11.0, 1, L.cp1252)
    L.pdfSetFillColor(pdf, RGB(120, 120, 220))
    L.pdfWriteFTextExA(pdf, 50.0, 60.0, 150.0, -1.0, L.taCenter, b"Digitally signed by:")
    L.pdfSetFontA(pdf, b"Arial", L.fsBold | L.fsItalic, 18.0, 1, L.cp1252)
    L.pdfSetFillColor(pdf, RGB(100, 100, 200))
    L.pdfWriteFTextExA(pdf, 50.0, 45.0, 150.0, -1.0, L.taCenter, b"LumasPDF")

    L.pdfEndTemplate(pdf)                 # Close the appearance template.
    # ------------------------------------------------------------------------

    L.pdfEndPage(pdf)

    out_file = os.path.join(HERE, "out.pdf")
    # No fatal error occurred?
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return

    cert = os.path.join(HERE, "test_cert.pfx")
    if L.pdfCloseAndSignFile(pdf, cert.encode("latin-1"), b"123456", b"Test", b"") != 0:
        print('PDF file "%s" successfully created!' % out_file)

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
