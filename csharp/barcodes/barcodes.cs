//  barcodes -- C# port of examples\Vb6\barcodes\barcodes.bas
//  Writes every supported barcode type onto a grid of pages.
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Barcodes
{
    static TErrorProc _err = ErrProc;
    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                       // We try to continue if an error occurs
    }

    // TPDFBarcodeType values
    const int bctAustraliaPost = 0x3F, bctAustraliaRedir = 0x44, bctAustraliaReply = 0x42, bctAustraliaRout = 0x43;
    const int bctAztec = 0x5C, bctAztecRunes = 0x80, bctC2Of5IATA = 0x4, bctC2Of5Industrial = 0x7;
    const int bctC2Of5Interleaved = 0x3, bctC2Of5Logic = 0x6, bctC2Of5Matrix = 0x2, bctChannelCode = 0x8C;
    const int bctCodabar = 0x12, bctCodablockF = 0x4A, bctCode11 = 0x1, bctCode128 = 0x14, bctCode128B = 0x3C;
    const int bctCode16K = 0x17, bctCode32 = 0x81, bctCode39 = 0x8, bctCode49 = 0x18, bctCode93 = 0x19;
    const int bctCodeOne = 0x8D, bctDAFT = 0x5D, bctDataBarOmniTrunc = 0x1D, bctDataBarExpStacked = 0x51;
    const int bctDataBarExpanded = 0x1F, bctDataBarLimited = 0x1E, bctDataBarStacked = 0x4F, bctDataBarStackedO = 0x50;
    const int bctDataMatrix = 0x47, bctDotCode = 0x73, bctDPD = 0x60, bctDPIdentCode = 0x16, bctDPLeitcode = 0x15;
    const int bctEAN128 = 0x10, bctEAN128_CC = 0x83, bctEAN14 = 0x48, bctEANX = 0xD, bctEANX_CC = 0x82, bctEANXCheck = 0xE;
    const int bctExtCode39 = 0x9, bctFIM = 0x31, bctFlattermarken = 0x1C, bctHIBC_Aztec = 0x70, bctHIBC_CodablockF = 0x6E;
    const int bctHIBC_Code128 = 0x62, bctHIBC_Code39 = 0x63, bctHIBC_DataMatrix = 0x66, bctHIBC_MicroPDF417 = 0x6C;
    const int bctHIBC_PDF417 = 0x6A, bctHIBC_QR = 0x68, bctISBNX = 0x45, bctITF14 = 0x59, bctJapanPost = 0x4C;
    const int bctKIX = 0x5A, bctKoreaPost = 0x4D, bctLOGMARS = 0x32, bctMailmark = 0x79, bctMaxicode = 0x39;
    const int bctMicroPDF417 = 0x54, bctMicroQR = 0x61, bctMSIPlessey = 0x47, bctNVE18 = 0x4B, bctPDF417 = 0x37;
    const int bctPDF417Truncated = 0x38, bctPharmaOneTrack = 0x33, bctPharmaTwoTrack = 0x35, bctPLANET = 0x52;
    const int bctPlessey = 0x56, bctPostNet = 0x28, bctPZN = 0x34, bctQRCode = 0x3A, bctRMQR = 0x91;
    const int bctRoyalMail4State = 0x46, bctRSS_EXP_CC = 0x86, bctRSS_EXPSTACK_CC = 0x8B, bctRSS_LTD_CC = 0x85;
    const int bctRSS14_CC = 0x84, bctRSS14Stacked_CC = 0x89, bctRSS14StackOMNI_CC = 0x8A, bctTelepen = 0x20;
    const int bctUltracode = 0x90, bctUPCA = 0x22, bctUPCA_CC = 0x87, bctUPCACheckDigit = 0x23, bctUPCE = 0x25;
    const int bctUPCE_CC = 0x88, bctUPCECheckDigit = 0x26, bctUPNQR = 0x8F, bctUSPSOneCode = 0x55, bctVIN = 0x49;

    struct TestBarcode
    {
        public int BarcodeType; public string BarcodeName; public int DataType; public string Data; public string Primary;
        public TestBarcode(int bt, string nm, int dt, string dat, string prim)
        { BarcodeType = bt; BarcodeName = nm; DataType = dt; Data = dat; Primary = prim; }
    }

    static void Main()
    {
        int B = LumasPdfConsts.bcdtBinary, G = LumasPdfConsts.bcdtGS1Mode;
        var C = new List<TestBarcode>
        {
            new TestBarcode(bctAustraliaPost, "Australia Post", B, "12345678", ""),
            new TestBarcode(bctAustraliaRedir, "Australia Redirect Code", B, "12345678", ""),
            new TestBarcode(bctAustraliaReply, "Australia Reply-Paid", B, "12345678", ""),
            new TestBarcode(bctAustraliaRout, "Australia Routing Code", B, "12345678", ""),
            new TestBarcode(bctAztec, "Aztec binary mode", B, "123456789012", ""),
            new TestBarcode(bctAztec, "Aztec GS1 Mode", G, "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917", ""),
            new TestBarcode(bctAztecRunes, "Aztec Runes", B, "123", ""),
            new TestBarcode(bctC2Of5IATA, "Code 2 of 5 IATA", B, "1234567890", ""),
            new TestBarcode(bctC2Of5Industrial, "Code 2 of 5 Industrial", B, "1234567890", ""),
            new TestBarcode(bctC2Of5Interleaved, "Code 2 of 5 Interleaved", B, "1234567890", ""),
            new TestBarcode(bctC2Of5Logic, "Code 2 of 5 Data Logic", B, "1234567890", ""),
            new TestBarcode(bctC2Of5Matrix, "Code 2 of 5 Matrix", B, "1234567890", ""),
            new TestBarcode(bctChannelCode, "Channel Code", B, "1234567", ""),
            new TestBarcode(bctCodabar, "Codabar", B, "A123456789B", ""),
            new TestBarcode(bctCodablockF, "Codablock-F", B, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
            new TestBarcode(bctCode11, "Code 11", B, "1234567890", ""),
            new TestBarcode(bctCode128, "Code 128", B, "1234567890", ""),
            new TestBarcode(bctCode128B, "Code 128", B, "1234567890", ""),
            new TestBarcode(bctCode16K, "Code 16K binary mode", B, "[90]A1234567890", ""),
            new TestBarcode(bctCode16K, "Code 16K GS1 mode", G, "[90]A1234567890", ""),
            new TestBarcode(bctCode32, "Code 32", B, "12345678", ""),
            new TestBarcode(bctCode39, "Code 39", B, "1234567890", ""),
            new TestBarcode(bctCode49, "Code 49", B, "1234567890", ""),
            new TestBarcode(bctCode93, "Code 93", B, "1234567890", ""),
            new TestBarcode(bctCodeOne, "Code One", B, "1234567890", ""),
            new TestBarcode(bctDAFT, "DAFT Code", B, "aftdaftdftaft", ""),
            new TestBarcode(bctDataBarOmniTrunc, "GS1 DataBar Omnidirectional", B, "0123456789012", ""),
            new TestBarcode(bctDataBarExpStacked, "GS1 DataBar Stacked", B, "[90]1234567890", ""),
            new TestBarcode(bctDataBarExpanded, "GS1 DataBar Expanded", B, "[90]1234567890", ""),
            new TestBarcode(bctDataBarLimited, "GS1 DataBar Limited", B, "0123456789012", ""),
            new TestBarcode(bctDataBarStacked, "GS1 DataBar Stacked", B, "0123456789012", ""),
            new TestBarcode(bctDataBarStackedO, "GS1 DataBar Stacked Omni", B, "0123456789012", ""),
            new TestBarcode(bctDataMatrix, "Data Matrix ISO 16022", B, "0123456789012", ""),
            new TestBarcode(bctDotCode, "DotCode", B, "0123456789012", ""),
            new TestBarcode(bctDPD, "DPD Code", B, "1234567890123456789012345678", ""),
            new TestBarcode(bctDPIdentCode, "Deutsche Post Identcode", B, "12345678901", ""),
            new TestBarcode(bctDPLeitcode, "Deutsche Post Leitcode", B, "1234567890123", ""),
            new TestBarcode(bctEAN128, "EAN 128", B, "[90]0101234567890128TEC-IT", ""),
            new TestBarcode(bctEAN128_CC, "EAN 128 Composite Code", B, "[10]1234-1234", "[90]123456"),
            new TestBarcode(bctEAN14, "EAN 14", B, "1234567890", ""),
            new TestBarcode(bctEANX, "EAN X", B, "1234567890", ""),
            new TestBarcode(bctEANX_CC, "EAN Composite Symbol", B, "[90]12341234", "12345678"),
            new TestBarcode(bctEANXCheck, "EAN + Check Digit", B, "12345", ""),
            new TestBarcode(bctExtCode39, "Ext. Code 3 of 9 (Code 39+)", B, "1234567890", ""),
            new TestBarcode(bctFIM, "FIM", B, "d", ""),
            new TestBarcode(bctFlattermarken, "Flattermarken", B, "11111111111111", ""),
            new TestBarcode(bctHIBC_Aztec, "HIBC Aztec Code", B, "123456789012", ""),
            new TestBarcode(bctHIBC_CodablockF, "HIBC Codablock-F", B, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
            new TestBarcode(bctHIBC_Code128, "HIBC Code 128", B, "1234567890", ""),
            new TestBarcode(bctHIBC_Code39, "HIBC Code 39", B, "1234567890", ""),
            new TestBarcode(bctHIBC_DataMatrix, "HIBC Data Matrix", B, "0123456789012", ""),
            new TestBarcode(bctHIBC_MicroPDF417, "HIBC Micro PDF417", B, "01234567890abcde", ""),
            new TestBarcode(bctHIBC_PDF417, "HIBC PDF417", B, "01234567890abcde", ""),
            new TestBarcode(bctHIBC_QR, "HIBC QR Code", B, "01234567890abcde", ""),
            new TestBarcode(bctISBNX, "ISBN (EAN-13 with validation)", B, "0123456789", ""),
            new TestBarcode(bctITF14, "ITF-14", B, "0123456789", ""),
            new TestBarcode(bctJapanPost, "Japanese Postal Code", B, "0123456789", ""),
            new TestBarcode(bctKIX, "Dutch Post KIX Code", B, "0123456789", ""),
            new TestBarcode(bctKoreaPost, "Korea Post", B, "123456", ""),
            new TestBarcode(bctLOGMARS, "LOGMARS", B, "1234567890abcdef", ""),
            new TestBarcode(bctMailmark, "Royal Mail 4-State Mailmark", B, "11210012341234567AB19XY1A", ""),
            new TestBarcode(bctMaxicode, "Maxicode", B, "1234567890abcdef", ""),
            new TestBarcode(bctMicroPDF417, "Micro PDF417", B, "1234567890abcdef", ""),
            new TestBarcode(bctMicroQR, "Micro QR Code", B, "1234567890abcdef", ""),
            new TestBarcode(bctMSIPlessey, "MSI Plessey", B, "12345678901", ""),
            new TestBarcode(bctNVE18, "NVE-18", B, "1234567890123456", ""),
            new TestBarcode(bctPDF417, "PDF417", B, "1234567890abcdef", ""),
            new TestBarcode(bctPDF417Truncated, "PDF417 Truncated", B, "1234567890abcdef", ""),
            new TestBarcode(bctPharmaOneTrack, "Pharmacode One-Track", B, "123456", ""),
            new TestBarcode(bctPharmaTwoTrack, "Pharmacode Two-Track", B, "123456", ""),
            new TestBarcode(bctPLANET, "PLANET", B, "12345678901", ""),
            new TestBarcode(bctPlessey, "Plessey", B, "12345678901", ""),
            new TestBarcode(bctPostNet, "PostNet", B, "12345678901", ""),
            new TestBarcode(bctPZN, "PZN", B, "1234567", ""),
            new TestBarcode(bctQRCode, "QR Code", B, "1234567890abcdef", ""),
            new TestBarcode(bctRMQR, "Rect. Micro QR Code (rMQR)", B, "1234567890abcdef", ""),
            new TestBarcode(bctRoyalMail4State, "Royal Mail 4 State (RM4SCC)", B, "1234567890abcdef", ""),
            new TestBarcode(bctRSS_EXP_CC, "CS GS1 DataBar Ext. component", B, "[90]12341234", "[10]12345678"),
            new TestBarcode(bctRSS_EXPSTACK_CC, "CS GS1 DataBar Exp. Stacked", B, "[90]12341234", "[10]12345678"),
            new TestBarcode(bctRSS_LTD_CC, "CS GS1 DataBar Limited", B, "[90]12341234", "1234567"),
            new TestBarcode(bctRSS14_CC, "CS GS1 DataBar-14 Linear", B, "[90]12341234", "1234567"),
            new TestBarcode(bctRSS14Stacked_CC, "CS GS1 DataBar-14 Stacked", B, "[90]12341234", "1234567"),
            new TestBarcode(bctRSS14StackOMNI_CC, "CS GS1 DataBar-14 Stacked Omni", B, "[90]12341234", "1234567"),
            new TestBarcode(bctTelepen, "Telepen Alpha", B, "1234567890abcdef", ""),
            new TestBarcode(bctUltracode, "Ultracode", B, "1234567890abcdef", ""),
            new TestBarcode(bctUPCA, "UPC A", B, "1234567890", ""),
            new TestBarcode(bctUPCA_CC, "CS UPC A linear", B, "[90]12341234", "1234567"),
            new TestBarcode(bctUPCACheckDigit, "UPC A + Check Digit", B, "12345678905", ""),
            new TestBarcode(bctUPCE, "UCP E", B, "1234567", ""),
            new TestBarcode(bctUPCE_CC, "CS UPC E linear", B, "[90]12341234", "1234567"),
            new TestBarcode(bctUPCECheckDigit, "UCP E + Check Digit", B, "12345670", ""),
            new TestBarcode(bctUPNQR, "UPNQR (Univ. Placilni Nalog QR)", B, "1234567890abcdef", ""),
            new TestBarcode(bctUSPSOneCode, "USPS OneCode", B, "01234567094987654321", ""),
            new TestBarcode(bctVIN, "Vehicle Ident Number (USA)", B, "01234567094987654", ""),
        };

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        TPDFBarcode2 bcd = new TPDFBarcode2();
        bcd.StructSize = (uint)Marshal.SizeOf(typeof(TPDFBarcode2));
        LumasPdf.pdfInitBarcode2(ref bcd);
        bcd.Options = LumasPdfConsts.bcoDefault | LumasPdfConsts.bcoUseActiveFont;

        int cnt = C.Count;
        double pw = LumasPdf.pdfGetPageWidth(pdf) - 100.0;
        double ph = LumasPdf.pdfGetPageHeight(pdf) - 100.0;
        double w = 100.0, h = 120.0;
        int nx = (int)(pw / w);
        int ny = (int)(ph / h);
        double incX = w + (pw - nx * w) / (nx - 1);
        double incY = h + (ph - ny * h) / (ny - 1);
        h = 100.0;
        int i = 0;
        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");

        while (i < cnt)
        {
            LumasPdf.pdfAppend(pdf);
            LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 6.5, true, TCodepage.cp1252);
            LumasPdf.pdfSetLineWidth(pdf, 0.0);
            double y = 50.0;
            for (int yy = 1; yy <= ny; yy++)
            {
                double x = 50.0;
                for (int xx = 1; xx <= nx; xx++)
                {
                    bcd.BarcodeType = C[i].BarcodeType;
                    IntPtr dataPtr = Marshal.StringToHGlobalAnsi(C[i].Data);
                    IntPtr primPtr = Marshal.StringToHGlobalAnsi(C[i].Primary);
                    bcd.Data = dataPtr;
                    bcd.DataType = C[i].DataType;
                    bcd.Primary = primPtr;
                    LumasPdf.pdfWriteFTextExW(pdf, x, y - 10.0, w, -1.0, (int)LumasPdfConsts.taCenter, C[i].BarcodeName);
                    LumasPdf.pdfRectangle(pdf, x, y, w, h, (int)TPathFillMode.fmStroke);
                    int rc = LumasPdf.pdfInsertBarcode(pdf, x, y, w, h, TCellAlign.coCenter, TCellAlign.coCenter, ref bcd);
                    Marshal.FreeHGlobal(dataPtr);
                    Marshal.FreeHGlobal(primPtr);
                    if (rc < 0)
                    {
                        LumasPdf.pdfDeletePDF(pdf);
                        return;
                    }
                    i++;
                    x += incX;
                    if (i == cnt) break;
                }
                y += incY;
                if (i == cnt) break;
            }
            LumasPdf.pdfEndPage(pdf);
        }

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
        }
        LumasPdf.pdfCloseFile(pdf);
        Console.WriteLine("Barcodes \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}
