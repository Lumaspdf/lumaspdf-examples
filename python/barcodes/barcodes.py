# ============================================================================
#  barcodes -- Python (ctypes) port of examples\Vb6\barcodes\barcodes.bas
#  Writes every supported barcode type onto a grid of pages.
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

# -- TPDFBarcodeType values (full set declared locally) --
bctAustraliaPost = 0x3F
bctAustraliaRedir = 0x44
bctAustraliaReply = 0x42
bctAustraliaRout = 0x43
bctAztec_ = 0x5C
bctAztecRunes_ = 0x80
bctC2Of5IATA = 0x4
bctC2Of5Industrial = 0x7
bctC2Of5Interleaved = 0x3
bctC2Of5Logic = 0x6
bctC2Of5Matrix = 0x2
bctChannelCode = 0x8C
bctCodabar = 0x12
bctCodablockF = 0x4A
bctCode11 = 0x1
bctCode128 = 0x14
bctCode128B = 0x3C
bctCode16K = 0x17
bctCode32 = 0x81
bctCode39 = 0x8
bctCode49 = 0x18
bctCode93 = 0x19
bctCodeOne_ = 0x8D
bctDAFT = 0x5D
bctDataBarOmniTrunc = 0x1D
bctDataBarExpStacked = 0x51
bctDataBarExpanded = 0x1F
bctDataBarLimited = 0x1E
bctDataBarStacked = 0x4F
bctDataBarStackedO = 0x50
bctDataMatrix_ = 0x47
bctDotCode_ = 0x73
bctDPD = 0x60
bctDPIdentCode = 0x16
bctDPLeitcode = 0x15
bctEAN128 = 0x10
bctEAN128_CC = 0x83
bctEAN14 = 0x48
bctEANX = 0xD
bctEANX_CC = 0x82
bctEANXCheck = 0xE
bctExtCode39 = 0x9
bctFIM = 0x31
bctFlattermarken = 0x1C
bctHIBC_Aztec_ = 0x70
bctHIBC_CodablockF = 0x6E
bctHIBC_Code128 = 0x62
bctHIBC_Code39 = 0x63
bctHIBC_DataMatrix_ = 0x66
bctHIBC_MicroPDF417_ = 0x6C
bctHIBC_PDF417_ = 0x6A
bctHIBC_QR_ = 0x68
bctISBNX = 0x45
bctITF14 = 0x59
bctJapanPost = 0x4C
bctKIX = 0x5A
bctKoreaPost = 0x4D
bctLOGMARS = 0x32
bctMailmark = 0x79
bctMaxicode_ = 0x39
bctMicroPDF417_ = 0x54
bctMicroQR_ = 0x61
bctMSIPlessey = 0x47
bctNVE18 = 0x4B
bctPDF417_ = 0x37
bctPDF417Truncated_ = 0x38
bctPharmaOneTrack = 0x33
bctPharmaTwoTrack = 0x35
bctPLANET = 0x52
bctPlessey = 0x56
bctPostNet = 0x28
bctPZN = 0x34
bctQRCode_ = 0x3A
bctRMQR_ = 0x91
bctRoyalMail4State = 0x46
bctRSS_EXP_CC = 0x86
bctRSS_EXPSTACK_CC = 0x8B
bctRSS_LTD_CC = 0x85
bctRSS14_CC = 0x84
bctRSS14Stacked_CC = 0x89
bctRSS14StackOMNI_CC = 0x8A
bctTelepen = 0x20
bctUltracode_ = 0x90
bctUPCA = 0x22
bctUPCA_CC = 0x87
bctUPCACheckDigit = 0x23
bctUPCE = 0x25
bctUPCE_CC = 0x88
bctUPCECheckDigit = 0x26
bctUPNQR_ = 0x8F
bctUSPSOneCode = 0x55
bctVIN = 0x49


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


# (BarcodeType, Name, DataType, Data, Primary)
TEST_CODES = [
    (bctAustraliaPost, "Australia Post", L.bcdtBinary, "12345678", ""),
    (bctAustraliaRedir, "Australia Redirect Code", L.bcdtBinary, "12345678", ""),
    (bctAustraliaReply, "Australia Reply-Paid", L.bcdtBinary, "12345678", ""),
    (bctAustraliaRout, "Australia Routing Code", L.bcdtBinary, "12345678", ""),
    (bctAztec_, "Aztec binary mode", L.bcdtBinary, "123456789012", ""),
    (bctAztec_, "Aztec GS1 Mode", L.bcdtGS1Mode, "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917", ""),
    (bctAztecRunes_, "Aztec Runes", L.bcdtBinary, "123", ""),
    (bctC2Of5IATA, "Code 2 of 5 IATA", L.bcdtBinary, "1234567890", ""),
    (bctC2Of5Industrial, "Code 2 of 5 Industrial", L.bcdtBinary, "1234567890", ""),
    (bctC2Of5Interleaved, "Code 2 of 5 Interleaved", L.bcdtBinary, "1234567890", ""),
    (bctC2Of5Logic, "Code 2 of 5 Data Logic", L.bcdtBinary, "1234567890", ""),
    (bctC2Of5Matrix, "Code 2 of 5 Matrix", L.bcdtBinary, "1234567890", ""),
    (bctChannelCode, "Channel Code", L.bcdtBinary, "1234567", ""),
    (bctCodabar, "Codabar", L.bcdtBinary, "A123456789B", ""),
    (bctCodablockF, "Codablock-F", L.bcdtBinary, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
    (bctCode11, "Code 11", L.bcdtBinary, "1234567890", ""),
    (bctCode128, "Code 128", L.bcdtBinary, "1234567890", ""),
    (bctCode128B, "Code 128", L.bcdtBinary, "1234567890", ""),
    (bctCode16K, "Code 16K binary mode", L.bcdtBinary, "[90]A1234567890", ""),
    (bctCode16K, "Code 16K GS1 mode", L.bcdtGS1Mode, "[90]A1234567890", ""),
    (bctCode32, "Code 32", L.bcdtBinary, "12345678", ""),
    (bctCode39, "Code 39", L.bcdtBinary, "1234567890", ""),
    (bctCode49, "Code 49", L.bcdtBinary, "1234567890", ""),
    (bctCode93, "Code 93", L.bcdtBinary, "1234567890", ""),
    (bctCodeOne_, "Code One", L.bcdtBinary, "1234567890", ""),
    (bctDAFT, "DAFT Code", L.bcdtBinary, "aftdaftdftaft", ""),
    (bctDataBarOmniTrunc, "GS1 DataBar Omnidirectional", L.bcdtBinary, "0123456789012", ""),
    (bctDataBarExpStacked, "GS1 DataBar Stacked", L.bcdtBinary, "[90]1234567890", ""),
    (bctDataBarExpanded, "GS1 DataBar Expanded", L.bcdtBinary, "[90]1234567890", ""),
    (bctDataBarLimited, "GS1 DataBar Limited", L.bcdtBinary, "0123456789012", ""),
    (bctDataBarStacked, "GS1 DataBar Stacked", L.bcdtBinary, "0123456789012", ""),
    (bctDataBarStackedO, "GS1 DataBar Stacked Omni", L.bcdtBinary, "0123456789012", ""),
    (bctDataMatrix_, "Data Matrix ISO 16022", L.bcdtBinary, "0123456789012", ""),
    (bctDotCode_, "DotCode", L.bcdtBinary, "0123456789012", ""),
    (bctDPD, "DPD Code", L.bcdtBinary, "1234567890123456789012345678", ""),
    (bctDPIdentCode, "Deutsche Post Identcode", L.bcdtBinary, "12345678901", ""),
    (bctDPLeitcode, "Deutsche Post Leitcode", L.bcdtBinary, "1234567890123", ""),
    (bctEAN128, "EAN 128", L.bcdtBinary, "[90]0101234567890128TEC-IT", ""),
    (bctEAN128_CC, "EAN 128 Composite Code", L.bcdtBinary, "[10]1234-1234", "[90]123456"),
    (bctEAN14, "EAN 14", L.bcdtBinary, "1234567890", ""),
    (bctEANX, "EAN X", L.bcdtBinary, "1234567890", ""),
    (bctEANX_CC, "EAN Composite Symbol", L.bcdtBinary, "[90]12341234", "12345678"),
    (bctEANXCheck, "EAN + Check Digit", L.bcdtBinary, "12345", ""),
    (bctExtCode39, "Ext. Code 3 of 9 (Code 39+)", L.bcdtBinary, "1234567890", ""),
    (bctFIM, "FIM", L.bcdtBinary, "d", ""),
    (bctFlattermarken, "Flattermarken", L.bcdtBinary, "11111111111111", ""),
    (bctHIBC_Aztec_, "HIBC Aztec Code", L.bcdtBinary, "123456789012", ""),
    (bctHIBC_CodablockF, "HIBC Codablock-F", L.bcdtBinary, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
    (bctHIBC_Code128, "HIBC Code 128", L.bcdtBinary, "1234567890", ""),
    (bctHIBC_Code39, "HIBC Code 39", L.bcdtBinary, "1234567890", ""),
    (bctHIBC_DataMatrix_, "HIBC Data Matrix", L.bcdtBinary, "0123456789012", ""),
    (bctHIBC_MicroPDF417_, "HIBC Micro PDF417", L.bcdtBinary, "01234567890abcde", ""),
    (bctHIBC_PDF417_, "HIBC PDF417", L.bcdtBinary, "01234567890abcde", ""),
    (bctHIBC_QR_, "HIBC QR Code", L.bcdtBinary, "01234567890abcde", ""),
    (bctISBNX, "ISBN (EAN-13 with validation)", L.bcdtBinary, "0123456789", ""),
    (bctITF14, "ITF-14", L.bcdtBinary, "0123456789", ""),
    (bctJapanPost, "Japanese Postal Code", L.bcdtBinary, "0123456789", ""),
    (bctKIX, "Dutch Post KIX Code", L.bcdtBinary, "0123456789", ""),
    (bctKoreaPost, "Korea Post", L.bcdtBinary, "123456", ""),
    (bctLOGMARS, "LOGMARS", L.bcdtBinary, "1234567890abcdef", ""),
    (bctMailmark, "Royal Mail 4-State Mailmark", L.bcdtBinary, "11210012341234567AB19XY1A", ""),
    (bctMaxicode_, "Maxicode", L.bcdtBinary, "1234567890abcdef", ""),
    (bctMicroPDF417_, "Micro PDF417", L.bcdtBinary, "1234567890abcdef", ""),
    (bctMicroQR_, "Micro QR Code", L.bcdtBinary, "1234567890abcdef", ""),
    (bctMSIPlessey, "MSI Plessey", L.bcdtBinary, "12345678901", ""),
    (bctNVE18, "NVE-18", L.bcdtBinary, "1234567890123456", ""),
    (bctPDF417_, "PDF417", L.bcdtBinary, "1234567890abcdef", ""),
    (bctPDF417Truncated_, "PDF417 Truncated", L.bcdtBinary, "1234567890abcdef", ""),
    (bctPharmaOneTrack, "Pharmacode One-Track", L.bcdtBinary, "123456", ""),
    (bctPharmaTwoTrack, "Pharmacode Two-Track", L.bcdtBinary, "123456", ""),
    (bctPLANET, "PLANET", L.bcdtBinary, "12345678901", ""),
    (bctPlessey, "Plessey", L.bcdtBinary, "12345678901", ""),
    (bctPostNet, "PostNet", L.bcdtBinary, "12345678901", ""),
    (bctPZN, "PZN", L.bcdtBinary, "1234567", ""),
    (bctQRCode_, "QR Code", L.bcdtBinary, "1234567890abcdef", ""),
    (bctRMQR_, "Rect. Micro QR Code (rMQR)", L.bcdtBinary, "1234567890abcdef", ""),
    (bctRoyalMail4State, "Royal Mail 4 State (RM4SCC)", L.bcdtBinary, "1234567890abcdef", ""),
    (bctRSS_EXP_CC, "CS GS1 DataBar Ext. component", L.bcdtBinary, "[90]12341234", "[10]12345678"),
    (bctRSS_EXPSTACK_CC, "CS GS1 DataBar Exp. Stacked", L.bcdtBinary, "[90]12341234", "[10]12345678"),
    (bctRSS_LTD_CC, "CS GS1 DataBar Limited", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctRSS14_CC, "CS GS1 DataBar-14 Linear", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctRSS14Stacked_CC, "CS GS1 DataBar-14 Stacked", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctRSS14StackOMNI_CC, "CS GS1 DataBar-14 Stacked Omni", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctTelepen, "Telepen Alpha", L.bcdtBinary, "1234567890abcdef", ""),
    (bctUltracode_, "Ultracode", L.bcdtBinary, "1234567890abcdef", ""),
    (bctUPCA, "UPC A", L.bcdtBinary, "1234567890", ""),
    (bctUPCA_CC, "CS UPC A linear", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctUPCACheckDigit, "UPC A + Check Digit", L.bcdtBinary, "12345678905", ""),
    (bctUPCE, "UCP E", L.bcdtBinary, "1234567", ""),
    (bctUPCE_CC, "CS UPC E linear", L.bcdtBinary, "[90]12341234", "1234567"),
    (bctUPCECheckDigit, "UCP E + Check Digit", L.bcdtBinary, "12345670", ""),
    (bctUPNQR_, "UPNQR (Univ. Placilni Nalog QR)", L.bcdtBinary, "1234567890abcdef", ""),
    (bctUSPSOneCode, "USPS OneCode", L.bcdtBinary, "01234567094987654321", ""),
    (bctVIN, "Vehicle Ident Number (USA)", L.bcdtBinary, "01234567094987654", ""),
]


def main():
    pdf = L.pdfNewPDF()
    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfSetPageCoords(pdf, L.pcTopDown)

    bcd = L.TPDFBarcode2()
    bcd.StructSize = ctypes.sizeof(L.TPDFBarcode2)
    L.pdfInitBarcode2(bcd)
    bcd.Options = L.bcoDefault | L.bcoUseActiveFont

    cnt = len(TEST_CODES)
    pw = L.pdfGetPageWidth(pdf) - 100.0
    ph = L.pdfGetPageHeight(pdf) - 100.0
    w = 100.0
    h = 120.0
    nx = int(pw / w)
    ny = int(ph / h)
    incX = w + (pw - nx * w) / (nx - 1)
    incY = h + (ph - ny * h) / (ny - 1)
    h = 100.0
    i = 0

    out_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out.pdf")

    while i < cnt:
        L.pdfAppend(pdf)
        L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 6.5, 1, L.cp1252)
        L.pdfSetLineWidth(pdf, 0.0)
        y = 50.0
        done = False
        for yy in range(ny):
            x = 50.0
            for xx in range(nx):
                bt, nm, dt, dat, prim = TEST_CODES[i]
                data_buf = ctypes.create_string_buffer(dat.encode("latin-1") + b"\0")
                prim_buf = ctypes.create_string_buffer(prim.encode("latin-1") + b"\0")
                bcd.BarcodeType = bt
                bcd.Data = ctypes.cast(data_buf, ctypes.c_void_p)
                bcd.DataType = dt
                bcd.Primary = ctypes.cast(prim_buf, ctypes.c_void_p)
                L.pdfWriteFTextExA(pdf, x, y - 10.0, w, -1.0, L.taCenter, nm.encode("latin-1", "replace"))
                L.pdfRectangle(pdf, x, y, w, h, L.fmStroke)
                if L.pdfInsertBarcode(pdf, x, y, w, h, L.coCenter, L.coCenter, bcd) < 0:
                    L.pdfDeletePDF(pdf)
                    return
                i += 1
                x += incX
                if i == cnt:
                    done = True
                    break
            y += incY
            if done:
                break
        L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
    L.pdfCloseFile(pdf)
    print('Barcodes "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()
