// barcodes -- C++ port of examples\Vb6\barcodes\barcodes.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>
#include <cmath>

// TPDFBarcodeType values (local set matching the VB6 .bas).
static const long bctAustraliaPost     = 0x3F;
static const long bctAustraliaRedir    = 0x44;
static const long bctAustraliaReply    = 0x42;
static const long bctAustraliaRout     = 0x43;
static const long bctAztec_            = 0x5C;
static const long bctAztecRunes_       = 0x80;
static const long bctC2Of5IATA         = 0x4;
static const long bctC2Of5Industrial   = 0x7;
static const long bctC2Of5Interleaved  = 0x3;
static const long bctC2Of5Logic        = 0x6;
static const long bctC2Of5Matrix       = 0x2;
static const long bctChannelCode       = 0x8C;
static const long bctCodabar           = 0x12;
static const long bctCodablockF        = 0x4A;
static const long bctCode11            = 0x1;
static const long bctCode128           = 0x14;
static const long bctCode128B          = 0x3C;
static const long bctCode16K           = 0x17;
static const long bctCode32            = 0x81;
static const long bctCode39            = 0x8;
static const long bctCode49            = 0x18;
static const long bctCode93            = 0x19;
static const long bctCodeOne_          = 0x8D;
static const long bctDAFT              = 0x5D;
static const long bctDataBarOmniTrunc  = 0x1D;
static const long bctDataBarExpStacked = 0x51;
static const long bctDataBarExpanded   = 0x1F;
static const long bctDataBarLimited    = 0x1E;
static const long bctDataBarStacked    = 0x4F;
static const long bctDataBarStackedO   = 0x50;
static const long bctDataMatrix_       = 0x47;
static const long bctDotCode_          = 0x73;
static const long bctDPD               = 0x60;
static const long bctDPIdentCode       = 0x16;
static const long bctDPLeitcode        = 0x15;
static const long bctEAN128            = 0x10;
static const long bctEAN128_CC         = 0x83;
static const long bctEAN14             = 0x48;
static const long bctEANX              = 0xD;
static const long bctEANX_CC           = 0x82;
static const long bctEANXCheck         = 0xE;
static const long bctExtCode39         = 0x9;
static const long bctFIM               = 0x31;
static const long bctFlattermarken     = 0x1C;
static const long bctHIBC_Aztec_       = 0x70;
static const long bctHIBC_CodablockF   = 0x6E;
static const long bctHIBC_Code128      = 0x62;
static const long bctHIBC_Code39       = 0x63;
static const long bctHIBC_DataMatrix_  = 0x66;
static const long bctHIBC_MicroPDF417_ = 0x6C;
static const long bctHIBC_PDF417_      = 0x6A;
static const long bctHIBC_QR_          = 0x68;
static const long bctISBNX             = 0x45;
static const long bctITF14             = 0x59;
static const long bctJapanPost         = 0x4C;
static const long bctKIX               = 0x5A;
static const long bctKoreaPost         = 0x4D;
static const long bctLOGMARS           = 0x32;
static const long bctMailmark          = 0x79;
static const long bctMaxicode_         = 0x39;
static const long bctMicroPDF417_      = 0x54;
static const long bctMicroQR_          = 0x61;
static const long bctMSIPlessey        = 0x47;
static const long bctNVE18             = 0x4B;
static const long bctPDF417_           = 0x37;
static const long bctPDF417Truncated_  = 0x38;
static const long bctPharmaOneTrack    = 0x33;
static const long bctPharmaTwoTrack    = 0x35;
static const long bctPLANET            = 0x52;
static const long bctPlessey           = 0x56;
static const long bctPostNet           = 0x28;
static const long bctPZN               = 0x34;
static const long bctQRCode_           = 0x3A;
static const long bctRMQR_             = 0x91;
static const long bctRoyalMail4State   = 0x46;
static const long bctRSS_EXP_CC        = 0x86;
static const long bctRSS_EXPSTACK_CC   = 0x8B;
static const long bctRSS_LTD_CC        = 0x85;
static const long bctRSS14_CC          = 0x84;
static const long bctRSS14Stacked_CC   = 0x89;
static const long bctRSS14StackOMNI_CC = 0x8A;
static const long bctTelepen           = 0x20;
static const long bctUltracode_        = 0x90;
static const long bctUPCA              = 0x22;
static const long bctUPCA_CC           = 0x87;
static const long bctUPCACheckDigit    = 0x23;
static const long bctUPCE              = 0x25;
static const long bctUPCE_CC           = 0x88;
static const long bctUPCECheckDigit    = 0x26;
static const long bctUPNQR_            = 0x8F;
static const long bctUSPSOneCode       = 0x55;
static const long bctVIN               = 0x49;

struct TTestBarcode {
    long        BarcodeType;
    const char* BarcodeName;
    long        DataType;
    const char* Data;
    const char* Primary;
};

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

int main(int argc, char** argv){
    static const TTestBarcode TEST_CODES[] = {
        { bctAustraliaPost,     "Australia Post",                bcdtBinary,  "12345678", "" },
        { bctAustraliaRedir,    "Australia Redirect Code",       bcdtBinary,  "12345678", "" },
        { bctAustraliaReply,    "Australia Reply-Paid",          bcdtBinary,  "12345678", "" },
        { bctAustraliaRout,     "Australia Routing Code",        bcdtBinary,  "12345678", "" },
        { bctAztec_,            "Aztec binary mode",             bcdtBinary,  "123456789012", "" },
        { bctAztec_,            "Aztec GS1 Mode",                bcdtGS1Mode, "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917", "" },
        { bctAztecRunes_,       "Aztec Runes",                   bcdtBinary,  "123", "" },
        { bctC2Of5IATA,         "Code 2 of 5 IATA",              bcdtBinary,  "1234567890", "" },
        { bctC2Of5Industrial,   "Code 2 of 5 Industrial",        bcdtBinary,  "1234567890", "" },
        { bctC2Of5Interleaved,  "Code 2 of 5 Interleaved",       bcdtBinary,  "1234567890", "" },
        { bctC2Of5Logic,        "Code 2 of 5 Data Logic",        bcdtBinary,  "1234567890", "" },
        { bctC2Of5Matrix,       "Code 2 of 5 Matrix",            bcdtBinary,  "1234567890", "" },
        { bctChannelCode,       "Channel Code",                  bcdtBinary,  "1234567", "" },
        { bctCodabar,           "Codabar",                       bcdtBinary,  "A123456789B", "" },
        { bctCodablockF,        "Codablock-F",                   bcdtBinary,  "1234567890abcdefghijklmnopqrstuvwxyz", "" },
        { bctCode11,            "Code 11",                       bcdtBinary,  "1234567890", "" },
        { bctCode128,           "Code 128",                      bcdtBinary,  "1234567890", "" },
        { bctCode128B,          "Code 128",                      bcdtBinary,  "1234567890", "" },
        { bctCode16K,           "Code 16K binary mode",          bcdtBinary,  "[90]A1234567890", "" },
        { bctCode16K,           "Code 16K GS1 mode",             bcdtGS1Mode, "[90]A1234567890", "" },
        { bctCode32,            "Code 32",                       bcdtBinary,  "12345678", "" },
        { bctCode39,            "Code 39",                       bcdtBinary,  "1234567890", "" },
        { bctCode49,            "Code 49",                       bcdtBinary,  "1234567890", "" },
        { bctCode93,            "Code 93",                       bcdtBinary,  "1234567890", "" },
        { bctCodeOne_,          "Code One",                      bcdtBinary,  "1234567890", "" },
        { bctDAFT,              "DAFT Code",                     bcdtBinary,  "aftdaftdftaft", "" },
        { bctDataBarOmniTrunc,  "GS1 DataBar Omnidirectional",   bcdtBinary,  "0123456789012", "" },
        { bctDataBarExpStacked, "GS1 DataBar Stacked",           bcdtBinary,  "[90]1234567890", "" },
        { bctDataBarExpanded,   "GS1 DataBar Expanded",          bcdtBinary,  "[90]1234567890", "" },
        { bctDataBarLimited,    "GS1 DataBar Limited",           bcdtBinary,  "0123456789012", "" },
        { bctDataBarStacked,    "GS1 DataBar Stacked",           bcdtBinary,  "0123456789012", "" },
        { bctDataBarStackedO,   "GS1 DataBar Stacked Omni",      bcdtBinary,  "0123456789012", "" },
        { bctDataMatrix_,       "Data Matrix ISO 16022",         bcdtBinary,  "0123456789012", "" },
        { bctDotCode_,          "DotCode",                       bcdtBinary,  "0123456789012", "" },
        { bctDPD,               "DPD Code",                      bcdtBinary,  "1234567890123456789012345678", "" },
        { bctDPIdentCode,       "Deutsche Post Identcode",       bcdtBinary,  "12345678901", "" },
        { bctDPLeitcode,        "Deutsche Post Leitcode",        bcdtBinary,  "1234567890123", "" },
        { bctEAN128,            "EAN 128",                       bcdtBinary,  "[90]0101234567890128TEC-IT", "" },
        { bctEAN128_CC,         "EAN 128 Composite Code",        bcdtBinary,  "[10]1234-1234", "[90]123456" },
        { bctEAN14,             "EAN 14",                        bcdtBinary,  "1234567890", "" },
        { bctEANX,              "EAN X",                         bcdtBinary,  "1234567890", "" },
        { bctEANX_CC,           "EAN Composite Symbol",          bcdtBinary,  "[90]12341234", "12345678" },
        { bctEANXCheck,         "EAN + Check Digit",             bcdtBinary,  "12345", "" },
        { bctExtCode39,         "Ext. Code 3 of 9 (Code 39+)",   bcdtBinary,  "1234567890", "" },
        { bctFIM,               "FIM",                           bcdtBinary,  "d", "" },
        { bctFlattermarken,     "Flattermarken",                 bcdtBinary,  "11111111111111", "" },
        { bctHIBC_Aztec_,       "HIBC Aztec Code",               bcdtBinary,  "123456789012", "" },
        { bctHIBC_CodablockF,   "HIBC Codablock-F",              bcdtBinary,  "1234567890abcdefghijklmnopqrstuvwxyz", "" },
        { bctHIBC_Code128,      "HIBC Code 128",                 bcdtBinary,  "1234567890", "" },
        { bctHIBC_Code39,       "HIBC Code 39",                  bcdtBinary,  "1234567890", "" },
        { bctHIBC_DataMatrix_,  "HIBC Data Matrix",              bcdtBinary,  "0123456789012", "" },
        { bctHIBC_MicroPDF417_, "HIBC Micro PDF417",             bcdtBinary,  "01234567890abcde", "" },
        { bctHIBC_PDF417_,      "HIBC PDF417",                   bcdtBinary,  "01234567890abcde", "" },
        { bctHIBC_QR_,          "HIBC QR Code",                  bcdtBinary,  "01234567890abcde", "" },
        { bctISBNX,             "ISBN (EAN-13 with validation)", bcdtBinary,  "0123456789", "" },
        { bctITF14,             "ITF-14",                        bcdtBinary,  "0123456789", "" },
        { bctJapanPost,         "Japanese Postal Code",          bcdtBinary,  "0123456789", "" },
        { bctKIX,               "Dutch Post KIX Code",           bcdtBinary,  "0123456789", "" },
        { bctKoreaPost,         "Korea Post",                    bcdtBinary,  "123456", "" },
        { bctLOGMARS,           "LOGMARS",                       bcdtBinary,  "1234567890abcdef", "" },
        { bctMailmark,          "Royal Mail 4-State Mailmark",   bcdtBinary,  "11210012341234567AB19XY1A", "" },
        { bctMaxicode_,         "Maxicode",                      bcdtBinary,  "1234567890abcdef", "" },
        { bctMicroPDF417_,      "Micro PDF417",                  bcdtBinary,  "1234567890abcdef", "" },
        { bctMicroQR_,          "Micro QR Code",                 bcdtBinary,  "1234567890abcdef", "" },
        { bctMSIPlessey,        "MSI Plessey",                   bcdtBinary,  "12345678901", "" },
        { bctNVE18,             "NVE-18",                        bcdtBinary,  "1234567890123456", "" },
        { bctPDF417_,           "PDF417",                        bcdtBinary,  "1234567890abcdef", "" },
        { bctPDF417Truncated_,  "PDF417 Truncated",              bcdtBinary,  "1234567890abcdef", "" },
        { bctPharmaOneTrack,    "Pharmacode One-Track",          bcdtBinary,  "123456", "" },
        { bctPharmaTwoTrack,    "Pharmacode Two-Track",          bcdtBinary,  "123456", "" },
        { bctPLANET,            "PLANET",                        bcdtBinary,  "12345678901", "" },
        { bctPlessey,           "Plessey",                       bcdtBinary,  "12345678901", "" },
        { bctPostNet,           "PostNet",                       bcdtBinary,  "12345678901", "" },
        { bctPZN,               "PZN",                           bcdtBinary,  "1234567", "" },
        { bctQRCode_,           "QR Code",                       bcdtBinary,  "1234567890abcdef", "" },
        { bctRMQR_,             "Rect. Micro QR Code (rMQR)",    bcdtBinary,  "1234567890abcdef", "" },
        { bctRoyalMail4State,   "Royal Mail 4 State (RM4SCC)",   bcdtBinary,  "1234567890abcdef", "" },
        { bctRSS_EXP_CC,        "CS GS1 DataBar Ext. component", bcdtBinary,  "[90]12341234", "[10]12345678" },
        { bctRSS_EXPSTACK_CC,   "CS GS1 DataBar Exp. Stacked",   bcdtBinary,  "[90]12341234", "[10]12345678" },
        { bctRSS_LTD_CC,        "CS GS1 DataBar Limited",        bcdtBinary,  "[90]12341234", "1234567" },
        { bctRSS14_CC,          "CS GS1 DataBar-14 Linear",      bcdtBinary,  "[90]12341234", "1234567" },
        { bctRSS14Stacked_CC,   "CS GS1 DataBar-14 Stacked",     bcdtBinary,  "[90]12341234", "1234567" },
        { bctRSS14StackOMNI_CC, "CS GS1 DataBar-14 Stacked Omni",bcdtBinary,  "[90]12341234", "1234567" },
        { bctTelepen,           "Telepen Alpha",                 bcdtBinary,  "1234567890abcdef", "" },
        { bctUltracode_,        "Ultracode",                     bcdtBinary,  "1234567890abcdef", "" },
        { bctUPCA,              "UPC A",                         bcdtBinary,  "1234567890", "" },
        { bctUPCA_CC,           "CS UPC A linear",               bcdtBinary,  "[90]12341234", "1234567" },
        { bctUPCACheckDigit,    "UPC A + Check Digit",           bcdtBinary,  "12345678905", "" },
        { bctUPCE,              "UCP E",                         bcdtBinary,  "1234567", "" },
        { bctUPCE_CC,           "CS UPC E linear",               bcdtBinary,  "[90]12341234", "1234567" },
        { bctUPCECheckDigit,    "UCP E + Check Digit",           bcdtBinary,  "12345670", "" },
        { bctUPNQR_,            "UPNQR (Univ. Placilni Nalog QR)",bcdtBinary, "1234567890abcdef", "" },
        { bctUSPSOneCode,       "USPS OneCode",                  bcdtBinary,  "01234567094987654321", "" },
        { bctVIN,               "Vehicle Ident Number (USA)",    bcdtBinary,  "01234567094987654", "" },
    };

    const int cnt = (int)(sizeof(TEST_CODES) / sizeof(TEST_CODES[0]));  // 94

    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);

    pdfSetPageCoords(pdf, pcTopDown);

    TPDFBarcode2 bcd{};
    bcd.StructSize = sizeof(bcd);
    pdfInitBarcode2(&bcd);
    bcd.Options = bcoDefault | bcoUseActiveFont;

    double pw = pdfGetPageWidth(pdf) - 100.0;
    double ph = pdfGetPageHeight(pdf) - 100.0;
    double w = 100.0;
    double h = 120.0;
    int nx = (int)(pw / w);
    int ny = (int)(ph / h);
    double incX = w + (pw - nx * w) / (nx - 1);
    double incY = h + (ph - ny * h) / (ny - 1);
    h = 100.0;
    int i = 0;

    std::string outFile;

    while(i < cnt){
        pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 6.5, 1, cp1252);
        pdfSetLineWidth(pdf, 0.0);
        double y = 50.0;
        for(int yy = 1; yy <= ny; ++yy){
            double x = 50.0;
            for(int xx = 1; xx <= nx; ++xx){
                bcd.BarcodeType = TEST_CODES[i].BarcodeType;
                bcd.Data     = (char*)TEST_CODES[i].Data;
                bcd.DataType = TEST_CODES[i].DataType;
                bcd.Primary  = (char*)TEST_CODES[i].Primary;
                pdfWriteFTextExA(pdf, x, y - 10.0, w, -1.0, taCenter, TEST_CODES[i].BarcodeName);
                pdfRectangle(pdf, x, y, w, h, fmStroke);
                if(pdfInsertBarcode(pdf, x, y, w, h, coCenter, coCenter, &bcd) < 0){
                    pdfDeletePDF(pdf);
                    return 0;
                }
                i++;
                x = x + incX;
                if(i == cnt) break;
            }
            y = y + incY;
            if(i == cnt) break;
        }
        pdfEndPage(pdf);
    }

    if(pdfHaveOpenDoc(pdf) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    pdfCloseFile(pdf);
    printf("Barcodes \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}
