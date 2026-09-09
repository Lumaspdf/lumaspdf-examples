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

# signed_pdfa -- port of examples\Vb6\signed_pdfa\signed_pdfa.bas
# Creates a PDF/A-1b compatible file with a digitally-signed signature field,
# checks conformance, adds the matching output intent, then signs the file.

HERE = os.path.dirname(os.path.abspath(__file__))
CR = "\r"

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
    L.pdfSetFontA(pdf, b"Arial", L.fsNone, 10.0, 1, L.cp1252)
    body = ("This is a PDF/A 1b compatible PDF file that was digitally signed with "
            "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important "
            "to avoid the usage of the 14 Standard fonts." + CR + CR +
            "When signing a PDF/A compliant PDF file with the default settings (without creation of a user "
            "defined appearance) the font Arial must be available on the system because it is used to print "
            "the certificate properties into the signature field." + CR + CR +
            "The font Arial must also be available if an empty signature field was added to the file "
            "without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A "
            "compliant PDF file later with Adobe's Acrobat. The signed PDF file is still compatible "
            "to PDF/A. If you use a third party solution to digitally sign the PDF file then test "
            "whether the signed file is still valid with the PDF/A 1b preflight tool included in Acrobat 8 "
            "Professional." + CR + CR +
            "Signature fields must be visible and the print flag must be set (default). CheckConformance() "
            "adjusts these flags if necessary and produces a warning if changes were applied. If no changes "
            "should be allowed, just return -1 in the error callback function. If the error callback function "
            "returns 0, DynaPDF assumes that the prior changes were accepted and processing continues." + CR + CR +
            "\\FC[255]Notice:\\FC[0]" + CR +
            "It makes no sense to execute CheckConformance() without an error callback function or error event "
            "in VB. If you cannot see what happens during the execution of CheckConformance(), it is "
            "completely useless to use this function!" + CR + CR +
            "CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. "
            "Once the the settings were found it is usually not longer recommended to execute this function. "
            "However, it is of course possible to use CheckConformance() as a general approach to make sure "
            "that files created with DynaPDF are PDF/A compatible.")
    L.pdfWriteFTextA(pdf, L.taLeft, body.encode("latin-1"))

    # ---------------------- Signature field appearance ----------------------
    sig_field = L.pdfCreateSigField(pdf, b"Signature", -1, 200.0, 400.0, 200.0, 80.0)
    L.pdfSetFieldColor(pdf, sig_field, L.fcBorderColor, L.csDeviceRGB, L.NO_COLOR)
    L.pdfPlaceSigFieldValidateIcon(pdf, sig_field, 0.0, 15.0, 50.0, 50.0)
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
    L.pdfWriteFTextExA(pdf, 50.0, 45.0, 150.0, -1.0, L.taCenter, b"DynaPDF")

    L.pdfEndTemplate(pdf)                 # Close the appearance template.
    # ------------------------------------------------------------------------

    L.pdfEndPage(pdf)

    # Check whether the file is compatible to PDF/A 1b.
    # last two args are OnFontNotFound / OnReplaceICCProfile callbacks (null here)
    _null_fnf = L.TOnFontNotFoundProc(0)
    _null_icc = L.TOnReplaceICCProfile(0)
    rc = L.pdfCheckConformance(pdf, L.ctPDFA_1b_2005, 0, None, _null_fnf, _null_icc)
    if rc in (1, 3):     # Gray, RGB
        L.pdfAddOutputIntentA(pdf, os.path.join(HERE, "sRGB.icc").encode("latin-1"))
    elif rc == 2:        # CMYK
        L.pdfAddOutputIntentA(pdf, os.path.join(HERE, "ISOcoated_v2_bas.ICC").encode("latin-1"))

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
