' barcodes -- VB.NET port of examples\Vb6\barcodes\barcodes.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module Barcodes
    Private errDel As TErrorProc

    ' TPDFBarcodeType values (full set declared locally, as in the VB6 template).
    Private Const bctAustraliaPost As Integer = &H3F
    Private Const bctAustraliaRedir As Integer = &H44
    Private Const bctAustraliaReply As Integer = &H42
    Private Const bctAustraliaRout As Integer = &H43
    Private Const bctAztec_ As Integer = &H5C
    Private Const bctAztecRunes_ As Integer = &H80
    Private Const bctC2Of5IATA As Integer = &H4
    Private Const bctC2Of5Industrial As Integer = &H7
    Private Const bctC2Of5Interleaved As Integer = &H3
    Private Const bctC2Of5Logic As Integer = &H6
    Private Const bctC2Of5Matrix As Integer = &H2
    Private Const bctChannelCode As Integer = &H8C
    Private Const bctCodabar As Integer = &H12
    Private Const bctCodablockF As Integer = &H4A
    Private Const bctCode11 As Integer = &H1
    Private Const bctCode128 As Integer = &H14
    Private Const bctCode128B As Integer = &H3C
    Private Const bctCode16K As Integer = &H17
    Private Const bctCode32 As Integer = &H81
    Private Const bctCode39 As Integer = &H8
    Private Const bctCode49 As Integer = &H18
    Private Const bctCode93 As Integer = &H19
    Private Const bctCodeOne_ As Integer = &H8D
    Private Const bctDAFT As Integer = &H5D
    Private Const bctDataBarOmniTrunc As Integer = &H1D
    Private Const bctDataBarExpStacked As Integer = &H51
    Private Const bctDataBarExpanded As Integer = &H1F
    Private Const bctDataBarLimited As Integer = &H1E
    Private Const bctDataBarStacked As Integer = &H4F
    Private Const bctDataBarStackedO As Integer = &H50
    Private Const bctDataMatrix_ As Integer = &H47
    Private Const bctDotCode_ As Integer = &H73
    Private Const bctDPD As Integer = &H60
    Private Const bctDPIdentCode As Integer = &H16
    Private Const bctDPLeitcode As Integer = &H15
    Private Const bctEAN128 As Integer = &H10
    Private Const bctEAN128_CC As Integer = &H83
    Private Const bctEAN14 As Integer = &H48
    Private Const bctEANX As Integer = &HD
    Private Const bctEANX_CC As Integer = &H82
    Private Const bctEANXCheck As Integer = &HE
    Private Const bctExtCode39 As Integer = &H9
    Private Const bctFIM As Integer = &H31
    Private Const bctFlattermarken As Integer = &H1C
    Private Const bctHIBC_Aztec_ As Integer = &H70
    Private Const bctHIBC_CodablockF As Integer = &H6E
    Private Const bctHIBC_Code128 As Integer = &H62
    Private Const bctHIBC_Code39 As Integer = &H63
    Private Const bctHIBC_DataMatrix_ As Integer = &H66
    Private Const bctHIBC_MicroPDF417_ As Integer = &H6C
    Private Const bctHIBC_PDF417_ As Integer = &H6A
    Private Const bctHIBC_QR_ As Integer = &H68
    Private Const bctISBNX As Integer = &H45
    Private Const bctITF14 As Integer = &H59
    Private Const bctJapanPost As Integer = &H4C
    Private Const bctKIX As Integer = &H5A
    Private Const bctKoreaPost As Integer = &H4D
    Private Const bctLOGMARS As Integer = &H32
    Private Const bctMailmark As Integer = &H79
    Private Const bctMaxicode_ As Integer = &H39
    Private Const bctMicroPDF417_ As Integer = &H54
    Private Const bctMicroQR_ As Integer = &H61
    Private Const bctMSIPlessey As Integer = &H47
    Private Const bctNVE18 As Integer = &H4B
    Private Const bctPDF417_ As Integer = &H37
    Private Const bctPDF417Truncated_ As Integer = &H38
    Private Const bctPharmaOneTrack As Integer = &H33
    Private Const bctPharmaTwoTrack As Integer = &H35
    Private Const bctPLANET As Integer = &H52
    Private Const bctPlessey As Integer = &H56
    Private Const bctPostNet As Integer = &H28
    Private Const bctPZN As Integer = &H34
    Private Const bctQRCode_ As Integer = &H3A
    Private Const bctRMQR_ As Integer = &H91
    Private Const bctRoyalMail4State As Integer = &H46
    Private Const bctRSS_EXP_CC As Integer = &H86
    Private Const bctRSS_EXPSTACK_CC As Integer = &H8B
    Private Const bctRSS_LTD_CC As Integer = &H85
    Private Const bctRSS14_CC As Integer = &H84
    Private Const bctRSS14Stacked_CC As Integer = &H89
    Private Const bctRSS14StackOMNI_CC As Integer = &H8A
    Private Const bctTelepen As Integer = &H20
    Private Const bctUltracode_ As Integer = &H90
    Private Const bctUPCA As Integer = &H22
    Private Const bctUPCA_CC As Integer = &H87
    Private Const bctUPCACheckDigit As Integer = &H23
    Private Const bctUPCE As Integer = &H25
    Private Const bctUPCE_CC As Integer = &H88
    Private Const bctUPCECheckDigit As Integer = &H26
    Private Const bctUPNQR_ As Integer = &H8F
    Private Const bctUSPSOneCode As Integer = &H55
    Private Const bctVIN As Integer = &H49

    Private Structure TTestBarcode
        Public BarcodeType As Integer
        Public BarcodeName As String
        Public DataType As Integer
        Public Data As String
        Public Primary As String
    End Structure

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function C(ByVal bt As Integer, ByVal nm As String, ByVal dt As Integer, ByVal dat As String, ByVal prim As String) As TTestBarcode
        Dim r As TTestBarcode
        r.BarcodeType = bt : r.BarcodeName = nm : r.DataType = dt : r.Data = dat : r.Primary = prim
        Return r
    End Function

    Sub Main()
        Dim binBinary As Integer = LumasPdfConsts.bcdtBinary
        Dim gs1 As Integer = LumasPdfConsts.bcdtGS1Mode
        Dim T As TTestBarcode() = New TTestBarcode() {
            C(bctAustraliaPost, "Australia Post", binBinary, "12345678", ""),
            C(bctAustraliaRedir, "Australia Redirect Code", binBinary, "12345678", ""),
            C(bctAustraliaReply, "Australia Reply-Paid", binBinary, "12345678", ""),
            C(bctAustraliaRout, "Australia Routing Code", binBinary, "12345678", ""),
            C(bctAztec_, "Aztec binary mode", binBinary, "123456789012", ""),
            C(bctAztec_, "Aztec GS1 Mode", gs1, "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917", ""),
            C(bctAztecRunes_, "Aztec Runes", binBinary, "123", ""),
            C(bctC2Of5IATA, "Code 2 of 5 IATA", binBinary, "1234567890", ""),
            C(bctC2Of5Industrial, "Code 2 of 5 Industrial", binBinary, "1234567890", ""),
            C(bctC2Of5Interleaved, "Code 2 of 5 Interleaved", binBinary, "1234567890", ""),
            C(bctC2Of5Logic, "Code 2 of 5 Data Logic", binBinary, "1234567890", ""),
            C(bctC2Of5Matrix, "Code 2 of 5 Matrix", binBinary, "1234567890", ""),
            C(bctChannelCode, "Channel Code", binBinary, "1234567", ""),
            C(bctCodabar, "Codabar", binBinary, "A123456789B", ""),
            C(bctCodablockF, "Codablock-F", binBinary, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
            C(bctCode11, "Code 11", binBinary, "1234567890", ""),
            C(bctCode128, "Code 128", binBinary, "1234567890", ""),
            C(bctCode128B, "Code 128", binBinary, "1234567890", ""),
            C(bctCode16K, "Code 16K binary mode", binBinary, "[90]A1234567890", ""),
            C(bctCode16K, "Code 16K GS1 mode", gs1, "[90]A1234567890", ""),
            C(bctCode32, "Code 32", binBinary, "12345678", ""),
            C(bctCode39, "Code 39", binBinary, "1234567890", ""),
            C(bctCode49, "Code 49", binBinary, "1234567890", ""),
            C(bctCode93, "Code 93", binBinary, "1234567890", ""),
            C(bctCodeOne_, "Code One", binBinary, "1234567890", ""),
            C(bctDAFT, "DAFT Code", binBinary, "aftdaftdftaft", ""),
            C(bctDataBarOmniTrunc, "GS1 DataBar Omnidirectional", binBinary, "0123456789012", ""),
            C(bctDataBarExpStacked, "GS1 DataBar Stacked", binBinary, "[90]1234567890", ""),
            C(bctDataBarExpanded, "GS1 DataBar Expanded", binBinary, "[90]1234567890", ""),
            C(bctDataBarLimited, "GS1 DataBar Limited", binBinary, "0123456789012", ""),
            C(bctDataBarStacked, "GS1 DataBar Stacked", binBinary, "0123456789012", ""),
            C(bctDataBarStackedO, "GS1 DataBar Stacked Omni", binBinary, "0123456789012", ""),
            C(bctDataMatrix_, "Data Matrix ISO 16022", binBinary, "0123456789012", ""),
            C(bctDotCode_, "DotCode", binBinary, "0123456789012", ""),
            C(bctDPD, "DPD Code", binBinary, "1234567890123456789012345678", ""),
            C(bctDPIdentCode, "Deutsche Post Identcode", binBinary, "12345678901", ""),
            C(bctDPLeitcode, "Deutsche Post Leitcode", binBinary, "1234567890123", ""),
            C(bctEAN128, "EAN 128", binBinary, "[90]0101234567890128TEC-IT", ""),
            C(bctEAN128_CC, "EAN 128 Composite Code", binBinary, "[10]1234-1234", "[90]123456"),
            C(bctEAN14, "EAN 14", binBinary, "1234567890", ""),
            C(bctEANX, "EAN X", binBinary, "1234567890", ""),
            C(bctEANX_CC, "EAN Composite Symbol", binBinary, "[90]12341234", "12345678"),
            C(bctEANXCheck, "EAN + Check Digit", binBinary, "12345", ""),
            C(bctExtCode39, "Ext. Code 3 of 9 (Code 39+)", binBinary, "1234567890", ""),
            C(bctFIM, "FIM", binBinary, "d", ""),
            C(bctFlattermarken, "Flattermarken", binBinary, "11111111111111", ""),
            C(bctHIBC_Aztec_, "HIBC Aztec Code", binBinary, "123456789012", ""),
            C(bctHIBC_CodablockF, "HIBC Codablock-F", binBinary, "1234567890abcdefghijklmnopqrstuvwxyz", ""),
            C(bctHIBC_Code128, "HIBC Code 128", binBinary, "1234567890", ""),
            C(bctHIBC_Code39, "HIBC Code 39", binBinary, "1234567890", ""),
            C(bctHIBC_DataMatrix_, "HIBC Data Matrix", binBinary, "0123456789012", ""),
            C(bctHIBC_MicroPDF417_, "HIBC Micro PDF417", binBinary, "01234567890abcde", ""),
            C(bctHIBC_PDF417_, "HIBC PDF417", binBinary, "01234567890abcde", ""),
            C(bctHIBC_QR_, "HIBC QR Code", binBinary, "01234567890abcde", ""),
            C(bctISBNX, "ISBN (EAN-13 with validation)", binBinary, "0123456789", ""),
            C(bctITF14, "ITF-14", binBinary, "0123456789", ""),
            C(bctJapanPost, "Japanese Postal Code", binBinary, "0123456789", ""),
            C(bctKIX, "Dutch Post KIX Code", binBinary, "0123456789", ""),
            C(bctKoreaPost, "Korea Post", binBinary, "123456", ""),
            C(bctLOGMARS, "LOGMARS", binBinary, "1234567890abcdef", ""),
            C(bctMailmark, "Royal Mail 4-State Mailmark", binBinary, "11210012341234567AB19XY1A", ""),
            C(bctMaxicode_, "Maxicode", binBinary, "1234567890abcdef", ""),
            C(bctMicroPDF417_, "Micro PDF417", binBinary, "1234567890abcdef", ""),
            C(bctMicroQR_, "Micro QR Code", binBinary, "1234567890abcdef", ""),
            C(bctMSIPlessey, "MSI Plessey", binBinary, "12345678901", ""),
            C(bctNVE18, "NVE-18", binBinary, "1234567890123456", ""),
            C(bctPDF417_, "PDF417", binBinary, "1234567890abcdef", ""),
            C(bctPDF417Truncated_, "PDF417 Truncated", binBinary, "1234567890abcdef", ""),
            C(bctPharmaOneTrack, "Pharmacode One-Track", binBinary, "123456", ""),
            C(bctPharmaTwoTrack, "Pharmacode Two-Track", binBinary, "123456", ""),
            C(bctPLANET, "PLANET", binBinary, "12345678901", ""),
            C(bctPlessey, "Plessey", binBinary, "12345678901", ""),
            C(bctPostNet, "PostNet", binBinary, "12345678901", ""),
            C(bctPZN, "PZN", binBinary, "1234567", ""),
            C(bctQRCode_, "QR Code", binBinary, "1234567890abcdef", ""),
            C(bctRMQR_, "Rect. Micro QR Code (rMQR)", binBinary, "1234567890abcdef", ""),
            C(bctRoyalMail4State, "Royal Mail 4 State (RM4SCC)", binBinary, "1234567890abcdef", ""),
            C(bctRSS_EXP_CC, "CS GS1 DataBar Ext. component", binBinary, "[90]12341234", "[10]12345678"),
            C(bctRSS_EXPSTACK_CC, "CS GS1 DataBar Exp. Stacked", binBinary, "[90]12341234", "[10]12345678"),
            C(bctRSS_LTD_CC, "CS GS1 DataBar Limited", binBinary, "[90]12341234", "1234567"),
            C(bctRSS14_CC, "CS GS1 DataBar-14 Linear", binBinary, "[90]12341234", "1234567"),
            C(bctRSS14Stacked_CC, "CS GS1 DataBar-14 Stacked", binBinary, "[90]12341234", "1234567"),
            C(bctRSS14StackOMNI_CC, "CS GS1 DataBar-14 Stacked Omni", binBinary, "[90]12341234", "1234567"),
            C(bctTelepen, "Telepen Alpha", binBinary, "1234567890abcdef", ""),
            C(bctUltracode_, "Ultracode", binBinary, "1234567890abcdef", ""),
            C(bctUPCA, "UPC A", binBinary, "1234567890", ""),
            C(bctUPCA_CC, "CS UPC A linear", binBinary, "[90]12341234", "1234567"),
            C(bctUPCACheckDigit, "UPC A + Check Digit", binBinary, "12345678905", ""),
            C(bctUPCE, "UCP E", binBinary, "1234567", ""),
            C(bctUPCE_CC, "CS UPC E linear", binBinary, "[90]12341234", "1234567"),
            C(bctUPCECheckDigit, "UCP E + Check Digit", binBinary, "12345670", ""),
            C(bctUPNQR_, "UPNQR (Univ. Placilni Nalog QR)", binBinary, "1234567890abcdef", ""),
            C(bctUSPSOneCode, "USPS OneCode", binBinary, "01234567094987654321", ""),
            C(bctVIN, "Vehicle Ident Number (USA)", binBinary, "01234567094987654", "")}

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        Dim bcd As TPDFBarcode2 = New TPDFBarcode2()
        bcd.StructSize = CUInt(Marshal.SizeOf(bcd))
        LumasPdf.pdfInitBarcode2(bcd)
        bcd.Options = LumasPdfConsts.bcoDefault Or LumasPdfConsts.bcoUseActiveFont

        Dim cnt As Integer = T.Length
        Dim pw As Double = LumasPdf.pdfGetPageWidth(pdf) - 100.0
        Dim ph As Double = LumasPdf.pdfGetPageHeight(pdf) - 100.0
        Dim w As Double = 100.0
        Dim h As Double = 120.0
        Dim nx As Integer = CInt(Math.Floor(pw / w))
        Dim ny As Integer = CInt(Math.Floor(ph / h))
        Dim incX As Double = w + (pw - nx * w) / (nx - 1)
        Dim incY As Double = h + (ph - ny * h) / (ny - 1)
        h = 100.0
        Dim i As Integer = 0
        Dim outFile As String = ""

        Do While i < cnt
            LumasPdf.pdfAppend(pdf)
            LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 6.5, True, TCodepage.cp1252)
            LumasPdf.pdfSetLineWidth(pdf, 0.0)
            Dim y As Double = 50.0
            Dim brk As Boolean = False
            For yy As Integer = 1 To ny
                Dim x As Double = 50.0
                For xx As Integer = 1 To nx
                    bcd.BarcodeType = T(i).BarcodeType
                    Dim pData As IntPtr = Marshal.StringToHGlobalAnsi(T(i).Data)
                    Dim pPrim As IntPtr = Marshal.StringToHGlobalAnsi(T(i).Primary)
                    bcd.Data = pData
                    bcd.DataType = T(i).DataType
                    bcd.Primary = pPrim
                    LumasPdf.pdfWriteFTextExW(pdf, x, y - 10.0, w, -1.0, LumasPdfConsts.taCenter, T(i).BarcodeName)
                    LumasPdf.pdfRectangle(pdf, x, y, w, h, TPathFillMode.fmStroke)
                    Dim rc As Integer = LumasPdf.pdfInsertBarcode(pdf, x, y, w, h, TCellAlign.coCenter, TCellAlign.coCenter, bcd)
                    Marshal.FreeHGlobal(pData)
                    Marshal.FreeHGlobal(pPrim)
                    If rc < 0 Then
                        LumasPdf.pdfDeletePDF(pdf)
                        Return
                    End If
                    i += 1
                    x += incX
                    If i = cnt Then brk = True : Exit For
                Next
                y += incY
                If brk Then Exit For
            Next
            LumasPdf.pdfEndPage(pdf)
        Loop

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        LumasPdf.pdfCloseFile(pdf)
        Console.WriteLine("Barcodes """ & outFile & """ successfully created!")
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
