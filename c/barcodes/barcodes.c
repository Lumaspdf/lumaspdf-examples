/* ============================================================================
 *  barcodes -- C (x64/MSVC) port of examples\Vb6\barcodes\barcodes.bas
 *  Writes every supported barcode type onto a grid of pages. The large typed
 *  const table of barcodes is reproduced as a C array of structs (indices 0..93).
 * ========================================================================= */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

/* Full set of TPDFBarcodeType values (hex from the .bas; local names carry a
 * trailing underscore where they would otherwise shadow a header #define). */
#define bctAustraliaPost     0x3F
#define bctAustraliaRedir    0x44
#define bctAustraliaReply    0x42
#define bctAustraliaRout     0x43
#define bctAztec_            0x5C
#define bctAztecRunes_       0x80
#define bctC2Of5IATA         0x04
#define bctC2Of5Industrial   0x07
#define bctC2Of5Interleaved  0x03
#define bctC2Of5Logic        0x06
#define bctC2Of5Matrix       0x02
#define bctChannelCode       0x8C
#define bctCodabar           0x12
#define bctCodablockF        0x4A
#define bctCode11            0x01
#define bctCode128           0x14
#define bctCode128B          0x3C
#define bctCode16K           0x17
#define bctCode32            0x81
#define bctCode39            0x08
#define bctCode49            0x18
#define bctCode93            0x19
#define bctCodeOne_          0x8D
#define bctDAFT              0x5D
#define bctDataBarOmniTrunc  0x1D
#define bctDataBarExpStacked 0x51
#define bctDataBarExpanded   0x1F
#define bctDataBarLimited    0x1E
#define bctDataBarStacked    0x4F
#define bctDataBarStackedO   0x50
#define bctDataMatrix_       0x47
#define bctDotCode_          0x73
#define bctDPD               0x60
#define bctDPIdentCode       0x16
#define bctDPLeitcode        0x15
#define bctEAN128            0x10
#define bctEAN128_CC         0x83
#define bctEAN14             0x48
#define bctEANX              0x0D
#define bctEANX_CC           0x82
#define bctEANXCheck         0x0E
#define bctExtCode39         0x09
#define bctFIM               0x31
#define bctFlattermarken     0x1C
#define bctHIBC_Aztec_       0x70
#define bctHIBC_CodablockF   0x6E
#define bctHIBC_Code128      0x62
#define bctHIBC_Code39       0x63
#define bctHIBC_DataMatrix_  0x66
#define bctHIBC_MicroPDF417_ 0x6C
#define bctHIBC_PDF417_      0x6A
#define bctHIBC_QR_          0x68
#define bctISBNX             0x45
#define bctITF14             0x59
#define bctJapanPost         0x4C
#define bctKIX               0x5A
#define bctKoreaPost         0x4D
#define bctLOGMARS           0x32
#define bctMailmark          0x79
#define bctMaxicode_         0x39
#define bctMicroPDF417_      0x54
#define bctMicroQR_          0x61
#define bctMSIPlessey        0x47
#define bctNVE18             0x4B
#define bctPDF417_           0x37
#define bctPDF417Truncated_  0x38
#define bctPharmaOneTrack    0x33
#define bctPharmaTwoTrack    0x35
#define bctPLANET            0x52
#define bctPlessey           0x56
#define bctPostNet           0x28
#define bctPZN               0x34
#define bctQRCode_           0x3A
#define bctRMQR_             0x91
#define bctRoyalMail4State   0x46
#define bctRSS_EXP_CC        0x86
#define bctRSS_EXPSTACK_CC   0x8B
#define bctRSS_LTD_CC        0x85
#define bctRSS14_CC          0x84
#define bctRSS14Stacked_CC   0x89
#define bctRSS14StackOMNI_CC 0x8A
#define bctTelepen           0x20
#define bctUltracode_        0x90
#define bctUPCA              0x22
#define bctUPCA_CC           0x87
#define bctUPCACheckDigit    0x23
#define bctUPCE              0x25
#define bctUPCE_CC           0x88
#define bctUPCECheckDigit    0x26
#define bctUPNQR_            0x8F
#define bctUSPSOneCode       0x55
#define bctVIN               0x49

typedef struct {
    SI32        BarcodeType;
    const char* BarcodeName;
    SI32        DataType;
    const char* Data;
    const char* Primary;
} TTestBarcode;

static const TTestBarcode TEST_CODES[94] = {
    { bctAustraliaPost,     "Australia Post",                bcdtBinary, "12345678", "" },
    { bctAustraliaRedir,    "Australia Redirect Code",       bcdtBinary, "12345678", "" },
    { bctAustraliaReply,    "Australia Reply-Paid",          bcdtBinary, "12345678", "" },
    { bctAustraliaRout,     "Australia Routing Code",        bcdtBinary, "12345678", "" },
    { bctAztec_,            "Aztec binary mode",             bcdtBinary, "123456789012", "" },
    { bctAztec_,            "Aztec GS1 Mode",                bcdtGS1Mode, "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917", "" },
    { bctAztecRunes_,       "Aztec Runes",                   bcdtBinary, "123", "" },
    { bctC2Of5IATA,         "Code 2 of 5 IATA",              bcdtBinary, "1234567890", "" },
    { bctC2Of5Industrial,   "Code 2 of 5 Industrial",        bcdtBinary, "1234567890", "" },
    { bctC2Of5Interleaved,  "Code 2 of 5 Interleaved",       bcdtBinary, "1234567890", "" },
    { bctC2Of5Logic,        "Code 2 of 5 Data Logic",        bcdtBinary, "1234567890", "" },
    { bctC2Of5Matrix,       "Code 2 of 5 Matrix",            bcdtBinary, "1234567890", "" },
    { bctChannelCode,       "Channel Code",                  bcdtBinary, "1234567", "" },
    { bctCodabar,           "Codabar",                       bcdtBinary, "A123456789B", "" },
    { bctCodablockF,        "Codablock-F",                   bcdtBinary, "1234567890abcdefghijklmnopqrstuvwxyz", "" },
    { bctCode11,            "Code 11",                       bcdtBinary, "1234567890", "" },
    { bctCode128,           "Code 128",                      bcdtBinary, "1234567890", "" },
    { bctCode128B,          "Code 128",                      bcdtBinary, "1234567890", "" },
    { bctCode16K,           "Code 16K binary mode",          bcdtBinary, "[90]A1234567890", "" },
    { bctCode16K,           "Code 16K GS1 mode",             bcdtGS1Mode, "[90]A1234567890", "" },
    { bctCode32,            "Code 32",                       bcdtBinary, "12345678", "" },
    { bctCode39,            "Code 39",                       bcdtBinary, "1234567890", "" },
    { bctCode49,            "Code 49",                       bcdtBinary, "1234567890", "" },
    { bctCode93,            "Code 93",                       bcdtBinary, "1234567890", "" },
    { bctCodeOne_,          "Code One",                      bcdtBinary, "1234567890", "" },
    { bctDAFT,              "DAFT Code",                     bcdtBinary, "aftdaftdftaft", "" },
    { bctDataBarOmniTrunc,  "GS1 DataBar Omnidirectional",   bcdtBinary, "0123456789012", "" },
    { bctDataBarExpStacked, "GS1 DataBar Stacked",           bcdtBinary, "[90]1234567890", "" },
    { bctDataBarExpanded,   "GS1 DataBar Expanded",          bcdtBinary, "[90]1234567890", "" },
    { bctDataBarLimited,    "GS1 DataBar Limited",           bcdtBinary, "0123456789012", "" },
    { bctDataBarStacked,    "GS1 DataBar Stacked",           bcdtBinary, "0123456789012", "" },
    { bctDataBarStackedO,   "GS1 DataBar Stacked Omni",      bcdtBinary, "0123456789012", "" },
    { bctDataMatrix_,       "Data Matrix ISO 16022",         bcdtBinary, "0123456789012", "" },
    { bctDotCode_,          "DotCode",                       bcdtBinary, "0123456789012", "" },
    { bctDPD,               "DPD Code",                      bcdtBinary, "1234567890123456789012345678", "" },
    { bctDPIdentCode,       "Deutsche Post Identcode",       bcdtBinary, "12345678901", "" },
    { bctDPLeitcode,        "Deutsche Post Leitcode",        bcdtBinary, "1234567890123", "" },
    { bctEAN128,            "EAN 128",                       bcdtBinary, "[90]0101234567890128TEC-IT", "" },
    { bctEAN128_CC,         "EAN 128 Composite Code",        bcdtBinary, "[10]1234-1234", "[90]123456" },
    { bctEAN14,             "EAN 14",                        bcdtBinary, "1234567890", "" },
    { bctEANX,              "EAN X",                         bcdtBinary, "1234567890", "" },
    { bctEANX_CC,           "EAN Composite Symbol",          bcdtBinary, "[90]12341234", "12345678" },
    { bctEANXCheck,         "EAN + Check Digit",             bcdtBinary, "12345", "" },
    { bctExtCode39,         "Ext. Code 3 of 9 (Code 39+)",   bcdtBinary, "1234567890", "" },
    { bctFIM,               "FIM",                           bcdtBinary, "d", "" },
    { bctFlattermarken,     "Flattermarken",                 bcdtBinary, "11111111111111", "" },
    { bctHIBC_Aztec_,       "HIBC Aztec Code",               bcdtBinary, "123456789012", "" },
    { bctHIBC_CodablockF,   "HIBC Codablock-F",              bcdtBinary, "1234567890abcdefghijklmnopqrstuvwxyz", "" },
    { bctHIBC_Code128,      "HIBC Code 128",                 bcdtBinary, "1234567890", "" },
    { bctHIBC_Code39,       "HIBC Code 39",                  bcdtBinary, "1234567890", "" },
    { bctHIBC_DataMatrix_,  "HIBC Data Matrix",              bcdtBinary, "0123456789012", "" },
    { bctHIBC_MicroPDF417_, "HIBC Micro PDF417",             bcdtBinary, "01234567890abcde", "" },
    { bctHIBC_PDF417_,      "HIBC PDF417",                   bcdtBinary, "01234567890abcde", "" },
    { bctHIBC_QR_,          "HIBC QR Code",                  bcdtBinary, "01234567890abcde", "" },
    { bctISBNX,             "ISBN (EAN-13 with validation)", bcdtBinary, "0123456789", "" },
    { bctITF14,             "ITF-14",                        bcdtBinary, "0123456789", "" },
    { bctJapanPost,         "Japanese Postal Code",          bcdtBinary, "0123456789", "" },
    { bctKIX,               "Dutch Post KIX Code",           bcdtBinary, "0123456789", "" },
    { bctKoreaPost,         "Korea Post",                    bcdtBinary, "123456", "" },
    { bctLOGMARS,           "LOGMARS",                       bcdtBinary, "1234567890abcdef", "" },
    { bctMailmark,          "Royal Mail 4-State Mailmark",   bcdtBinary, "11210012341234567AB19XY1A", "" },
    { bctMaxicode_,         "Maxicode",                      bcdtBinary, "1234567890abcdef", "" },
    { bctMicroPDF417_,      "Micro PDF417",                  bcdtBinary, "1234567890abcdef", "" },
    { bctMicroQR_,          "Micro QR Code",                 bcdtBinary, "1234567890abcdef", "" },
    { bctMSIPlessey,        "MSI Plessey",                   bcdtBinary, "12345678901", "" },
    { bctNVE18,             "NVE-18",                        bcdtBinary, "1234567890123456", "" },
    { bctPDF417_,           "PDF417",                        bcdtBinary, "1234567890abcdef", "" },
    { bctPDF417Truncated_,  "PDF417 Truncated",              bcdtBinary, "1234567890abcdef", "" },
    { bctPharmaOneTrack,    "Pharmacode One-Track",          bcdtBinary, "123456", "" },
    { bctPharmaTwoTrack,    "Pharmacode Two-Track",          bcdtBinary, "123456", "" },
    { bctPLANET,            "PLANET",                        bcdtBinary, "12345678901", "" },
    { bctPlessey,           "Plessey",                       bcdtBinary, "12345678901", "" },
    { bctPostNet,           "PostNet",                       bcdtBinary, "12345678901", "" },
    { bctPZN,               "PZN",                           bcdtBinary, "1234567", "" },
    { bctQRCode_,           "QR Code",                       bcdtBinary, "1234567890abcdef", "" },
    { bctRMQR_,             "Rect. Micro QR Code (rMQR)",    bcdtBinary, "1234567890abcdef", "" },
    { bctRoyalMail4State,   "Royal Mail 4 State (RM4SCC)",   bcdtBinary, "1234567890abcdef", "" },
    { bctRSS_EXP_CC,        "CS GS1 DataBar Ext. component", bcdtBinary, "[90]12341234", "[10]12345678" },
    { bctRSS_EXPSTACK_CC,   "CS GS1 DataBar Exp. Stacked",   bcdtBinary, "[90]12341234", "[10]12345678" },
    { bctRSS_LTD_CC,        "CS GS1 DataBar Limited",        bcdtBinary, "[90]12341234", "1234567" },
    { bctRSS14_CC,          "CS GS1 DataBar-14 Linear",      bcdtBinary, "[90]12341234", "1234567" },
    { bctRSS14Stacked_CC,   "CS GS1 DataBar-14 Stacked",     bcdtBinary, "[90]12341234", "1234567" },
    { bctRSS14StackOMNI_CC, "CS GS1 DataBar-14 Stacked Omni",bcdtBinary, "[90]12341234", "1234567" },
    { bctTelepen,           "Telepen Alpha",                 bcdtBinary, "1234567890abcdef", "" },
    { bctUltracode_,        "Ultracode",                     bcdtBinary, "1234567890abcdef", "" },
    { bctUPCA,              "UPC A",                         bcdtBinary, "1234567890", "" },
    { bctUPCA_CC,           "CS UPC A linear",               bcdtBinary, "[90]12341234", "1234567" },
    { bctUPCACheckDigit,    "UPC A + Check Digit",           bcdtBinary, "12345678905", "" },
    { bctUPCE,              "UCP E",                         bcdtBinary, "1234567", "" },
    { bctUPCE_CC,           "CS UPC E linear",               bcdtBinary, "[90]12341234", "1234567" },
    { bctUPCECheckDigit,    "UCP E + Check Digit",           bcdtBinary, "12345670", "" },
    { bctUPNQR_,            "UPNQR (Univ. Placilni Nalog QR)",bcdtBinary, "1234567890abcdef", "" },
    { bctUSPSOneCode,       "USPS OneCode",                  bcdtBinary, "01234567094987654321", "" },
    { bctVIN,               "Vehicle Ident Number (USA)",    bcdtBinary, "01234567094987654", "" }
};

static void exedir(const char* a0, char* out, size_t n) {
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv) {
    PPDF pdf;
    char dir[1024], outFile[1100];
    double x, y, w, h, pw, ph, incX, incY;
    int i, nx, ny, xx, yy, cnt;
    TPDFBarcode2 bcd;

    pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    pdfSetPageCoords(pdf, pcTopDown);

    memset(&bcd, 0, sizeof(bcd));
    bcd.StructSize = sizeof(TPDFBarcode2);
    pdfInitBarcode2(&bcd);
    bcd.Options = bcoDefault | bcoUseActiveFont;

    cnt = 94;
    pw = pdfGetPageWidth(pdf) - 100.0;
    ph = pdfGetPageHeight(pdf) - 100.0;
    w = 100.0;
    h = 120.0;
    nx = (int)(pw / w);
    ny = (int)(ph / h);
    incX = w + (pw - nx * w) / (nx - 1);
    incY = h + (ph - ny * h) / (ny - 1);
    h = 100.0;
    i = 0;

    while (i < cnt) {
        pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 6.5, 1, cp1252);
        pdfSetLineWidth(pdf, 0.0);
        y = 50.0;
        for (yy = 1; yy <= ny; yy++) {
            x = 50.0;
            for (xx = 1; xx <= nx; xx++) {
                bcd.BarcodeType = TEST_CODES[i].BarcodeType;
                bcd.Data        = (char*)TEST_CODES[i].Data;
                bcd.DataType    = TEST_CODES[i].DataType;
                bcd.Primary     = (char*)TEST_CODES[i].Primary;
                pdfWriteFTextExA(pdf, x, y - 10.0, w, -1.0, taCenter, TEST_CODES[i].BarcodeName);
                pdfRectangle(pdf, x, y, w, h, fmStroke);
                if (pdfInsertBarcode(pdf, x, y, w, h, coCenter, coCenter, &bcd) < 0) {
                    pdfDeletePDF(pdf);
                    return 0;
                }
                i++;
                x += incX;
                if (i == cnt) break;
            }
            y += incY;
            if (i == cnt) break;
        }
        pdfEndPage(pdf);
    }

    outFile[0] = 0;
    if (pdfHaveOpenDoc(pdf) != 0) {
        exedir(argv[0], dir, sizeof(dir));
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    pdfCloseFile(pdf);
    printf("Barcodes \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    (void)argc;
    return 0;
}
