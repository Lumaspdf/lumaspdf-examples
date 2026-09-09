program collections;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

type TTestBarcode = record
   BarcodeType: TPDFBarcodeType;
   BarcodeName: AnsiString;
   DataType:    TPDFBarcodeDataType;
   Data:        AnsiString;
   Primary:     AnsiString;
end;

const TEST_CODES: Array[0..93] of TTestBarcode =
(
   (BarcodeType: bctAustraliaPost;     BarcodeName: 'Australia Post';                        DataType: bcdtBinary;  Data: '12345678'; Primary: ''),
   (BarcodeType: bctAustraliaRedir;    BarcodeName: 'Australia Redirect Code';               DataType: bcdtBinary;  Data: '12345678'; Primary: ''),
   (BarcodeType: bctAustraliaReply;    BarcodeName: 'Australia Reply-Paid';                  DataType: bcdtBinary;  Data: '12345678'; Primary: ''),
   (BarcodeType: bctAustraliaRout;     BarcodeName: 'Australia Routing Code';                DataType: bcdtBinary;  Data: '12345678'; Primary: ''),
   (BarcodeType: bctAztec;             BarcodeName: 'Aztec binary mode';                     DataType: bcdtBinary;  Data: '123456789012'; Primary: ''),
   (BarcodeType: bctAztec;             BarcodeName: 'Aztec GS1 Mode';                        DataType: bcdtGS1Mode; Data: '[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917'; Primary: ''),
   (BarcodeType: bctAztecRunes;        BarcodeName: 'Aztec Runes';                           DataType: bcdtBinary;  Data: '123'; Primary: ''),
   (BarcodeType: bctC2Of5IATA;         BarcodeName: 'Code 2 of 5 IATA';                      DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctC2Of5Industrial;   BarcodeName: 'Code 2 of 5 Industrial';                DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctC2Of5Interleaved;  BarcodeName: 'Code 2 of 5 Interleaved';               DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctC2Of5Logic;        BarcodeName: 'Code 2 of 5 Data Logic';                DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctC2Of5Matrix;       BarcodeName: 'Code 2 of 5 Matrix';                    DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctChannelCode;       BarcodeName: 'Channel Code';                          DataType: bcdtBinary;  Data: '1234567'; Primary: ''),
   (BarcodeType: bctCodabar;           BarcodeName: 'Codabar';                               DataType: bcdtBinary;  Data: 'A123456789B'; Primary: ''),
   (BarcodeType: bctCodablockF;        BarcodeName: 'Codablock-F';                           DataType: bcdtBinary;  Data: '1234567890abcdefghijklmnopqrstuvwxyz'; Primary: ''),
   (BarcodeType: bctCode11;            BarcodeName: 'Code 11';                               DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCode128;           BarcodeName: 'Code 128';                              DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCode128B;          BarcodeName: 'Code 128';                              DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCode16K;           BarcodeName: 'Code 16K binary mode';                  DataType: bcdtBinary;  Data: '[90]A1234567890'; Primary: ''),
   (BarcodeType: bctCode16K;           BarcodeName: 'Code 16K GS1 mode';                     DataType: bcdtGS1Mode; Data: '[90]A1234567890'; Primary: ''),
   (BarcodeType: bctCode32;            BarcodeName: 'Code 32';                               DataType: bcdtBinary;  Data: '12345678'; Primary: ''),
   (BarcodeType: bctCode39;            BarcodeName: 'Code 39';                               DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCode49;            BarcodeName: 'Code 49';                               DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCode93;            BarcodeName: 'Code 93';                               DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctCodeOne;           BarcodeName: 'Code One';                              DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctDAFT;              BarcodeName: 'DAFT Code';                             DataType: bcdtBinary;  Data: 'aftdaftdftaft'; Primary: ''),
   (BarcodeType: bctDataBarOmniTrunc;  BarcodeName: 'GS1 DataBar Omnidirectional';           DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDataBarExpStacked; BarcodeName: 'GS1 DataBar Stacked';                   DataType: bcdtBinary;  Data: '[90]1234567890'; Primary: ''),
   (BarcodeType: bctDataBarExpanded;   BarcodeName: 'GS1 DataBar Expanded';                  DataType: bcdtBinary;  Data: '[90]1234567890'; Primary: ''),
   (BarcodeType: bctDataBarLimited;    BarcodeName: 'GS1 DataBar Limited';                   DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDataBarStacked;    BarcodeName: 'GS1 DataBar Stacked';                   DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDataBarStackedO;   BarcodeName: 'GS1 DataBar Stacked Omni';              DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDataMatrix;        BarcodeName: 'Data Matrix ISO 16022';                 DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDotCode;           BarcodeName: 'DotCode';                               DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctDPD;               BarcodeName: 'DPD Code';                              DataType: bcdtBinary;  Data: '1234567890123456789012345678'; Primary: ''),
   (BarcodeType: bctDPIdentCode;       BarcodeName: 'Deutsche Post Identcode';               DataType: bcdtBinary;  Data: '12345678901'; Primary: ''),
   (BarcodeType: bctDPLeitcode;        BarcodeName: 'Deutsche Post Leitcode';                DataType: bcdtBinary;  Data: '1234567890123'; Primary: ''),
   (BarcodeType: bctEAN128;            BarcodeName: 'EAN 128';                               DataType: bcdtBinary;  Data: '[90]0101234567890128TEC-IT'; Primary: ''),
   (BarcodeType: bctEAN128_CC;         BarcodeName: 'EAN 128 Composite Code';                DataType: bcdtBinary;  Data: '[10]1234-1234'; Primary: '[90]123456'),
   (BarcodeType: bctEAN14;             BarcodeName: 'EAN 14';                                DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctEANX;              BarcodeName: 'EAN X';                                 DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctEANX_CC;           BarcodeName: 'EAN Composite Symbol';                  DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '12345678'),
   (BarcodeType: bctEANXCheck;         BarcodeName: 'EAN + Check Digit';                     DataType: bcdtBinary;  Data: '12345'; Primary: ''),
   (BarcodeType: bctExtCode39;         BarcodeName: 'Ext. Code 3 of 9 (Code 39+)';           DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctFIM;               BarcodeName: 'FIM';                                   DataType: bcdtBinary;  Data: 'd'; Primary: ''),
   (BarcodeType: bctFlattermarken;     BarcodeName: 'Flattermarken';                         DataType: bcdtBinary;  Data: '11111111111111'; Primary: ''),
   (BarcodeType: bctHIBC_Aztec;        BarcodeName: 'HIBC Aztec Code';                       DataType: bcdtBinary;  Data: '123456789012'; Primary: ''),
   (BarcodeType: bctHIBC_CodablockF;   BarcodeName: 'HIBC Codablock-F';                      DataType: bcdtBinary;  Data: '1234567890abcdefghijklmnopqrstuvwxyz'; Primary: ''),
   (BarcodeType: bctHIBC_Code128;      BarcodeName: 'HIBC Code 128';                         DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctHIBC_Code39;       BarcodeName: 'HIBC Code 39';                          DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctHIBC_DataMatrix;   BarcodeName: 'HIBC Data Matrix';                      DataType: bcdtBinary;  Data: '0123456789012'; Primary: ''),
   (BarcodeType: bctHIBC_MicroPDF417;  BarcodeName: 'HIBC Micro PDF417';                     DataType: bcdtBinary;  Data: '01234567890abcde'; Primary: ''),
   (BarcodeType: bctHIBC_PDF417;       BarcodeName: 'HIBC PDF417';                           DataType: bcdtBinary;  Data: '01234567890abcde'; Primary: ''),
   (BarcodeType: bctHIBC_QR;           BarcodeName: 'HIBC QR Code';                          DataType: bcdtBinary;  Data: '01234567890abcde'; Primary: ''),
   (BarcodeType: bctISBNX;             BarcodeName: 'ISBN (EAN-13 with validation)';         DataType: bcdtBinary;  Data: '0123456789'; Primary: ''),
   (BarcodeType: bctITF14;             BarcodeName: 'ITF-14';                                DataType: bcdtBinary;  Data: '0123456789'; Primary: ''),
   (BarcodeType: bctJapanPost;         BarcodeName: 'Japanese Postal Code';                  DataType: bcdtBinary;  Data: '0123456789'; Primary: ''),
   (BarcodeType: bctKIX;               BarcodeName: 'Dutch Post KIX Code';                   DataType: bcdtBinary;  Data: '0123456789'; Primary: ''),
   (BarcodeType: bctKoreaPost;         BarcodeName: 'Korea Post';                            DataType: bcdtBinary;  Data: '123456'; Primary: ''),
   (BarcodeType: bctLOGMARS;           BarcodeName: 'LOGMARS';                               DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctMailmark;          BarcodeName: 'Royal Mail 4-State Mailmark';           DataType: bcdtBinary;  Data: '11210012341234567AB19XY1A'; Primary: ''),
   (BarcodeType: bctMaxicode;          BarcodeName: 'Maxicode';                              DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctMicroPDF417;       BarcodeName: 'Micro PDF417';                          DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctMicroQR;           BarcodeName: 'Micro QR Code';                         DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctMSIPlessey;        BarcodeName: 'MSI Plessey';                           DataType: bcdtBinary;  Data: '12345678901'; Primary: ''),
   (BarcodeType: bctNVE18;             BarcodeName: 'NVE-18';                                DataType: bcdtBinary;  Data: '1234567890123456'; Primary: ''),
   (BarcodeType: bctPDF417;            BarcodeName: 'PDF417';                                DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctPDF417Truncated;   BarcodeName: 'PDF417 Truncated';                      DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctPharmaOneTrack;    BarcodeName: 'Pharmacode One-Track';                  DataType: bcdtBinary;  Data: '123456'; Primary: ''),
   (BarcodeType: bctPharmaTwoTrack;    BarcodeName: 'Pharmacode Two-Track';                  DataType: bcdtBinary;  Data: '123456'; Primary: ''),
   (BarcodeType: bctPLANET;            BarcodeName: 'PLANET';                                DataType: bcdtBinary;  Data: '12345678901'; Primary: ''),
   (BarcodeType: bctPlessey;           BarcodeName: 'Plessey';                               DataType: bcdtBinary;  Data: '12345678901'; Primary: ''),
   (BarcodeType: bctPostNet;           BarcodeName: 'PostNet';                               DataType: bcdtBinary;  Data: '12345678901'; Primary: ''),
   (BarcodeType: bctPZN;               BarcodeName: 'PZN';                                   DataType: bcdtBinary;  Data: '1234567'; Primary: ''),
   (BarcodeType: bctQRCode;            BarcodeName: 'QR Code';                               DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctRMQR;              BarcodeName: 'Rect. Micro QR Code (rMQR)';            DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctRoyalMail4State;   BarcodeName: 'Royal Mail 4 State (RM4SCC)';           DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctRSS_EXP_CC;        BarcodeName: 'CS GS1 DataBar Ext. component';         DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '[10]12345678'),
   (BarcodeType: bctRSS_EXPSTACK_CC;   BarcodeName: 'CS GS1 DataBar Exp. Stacked';           DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '[10]12345678'),
   (BarcodeType: bctRSS_LTD_CC;        BarcodeName: 'CS GS1 DataBar Limited';                DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctRSS14_CC;          BarcodeName: 'CS GS1 DataBar-14 Linear';              DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctRSS14Stacked_CC;   BarcodeName: 'CS GS1 DataBar-14 Stacked';             DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctRSS14StackOMNI_CC; BarcodeName: 'CS GS1 DataBar-14 Stacked Omni';        DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctTelepen;           BarcodeName: 'Telepen Alpha';                         DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctUltracode;         BarcodeName: 'Ultracode';                             DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctUPCA;              BarcodeName: 'UPC A';                                 DataType: bcdtBinary;  Data: '1234567890'; Primary: ''),
   (BarcodeType: bctUPCA_CC;           BarcodeName: 'CS UPC A linear';                       DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctUPCACheckDigit;    BarcodeName: 'UPC A + Check Digit';                   DataType: bcdtBinary;  Data: '12345678905'; Primary: ''),
   (BarcodeType: bctUPCE;              BarcodeName: 'UCP E';                                 DataType: bcdtBinary;  Data: '1234567'; Primary: ''),
   (BarcodeType: bctUPCE_CC;           BarcodeName: 'CS UPC E linear';                       DataType: bcdtBinary;  Data: '[90]12341234'; Primary: '1234567'),
   (BarcodeType: bctUPCECheckDigit;    BarcodeName: 'UCP E + Check Digit';                   DataType: bcdtBinary;  Data: '12345670'; Primary: ''),
   (BarcodeType: bctUPNQR;             BarcodeName: 'UPNQR (Univ. Placilni Nalog QR)';       DataType: bcdtBinary;  Data: '1234567890abcdef'; Primary: ''),
   (BarcodeType: bctUSPSOneCode;       BarcodeName: 'USPS OneCode';                          DataType: bcdtBinary;  Data: '01234567094987654321'; Primary: ''),
   (BarcodeType: bctVIN;               BarcodeName: 'Vehicle Ident Number (USA)';            DataType: bcdtBinary;  Data: '01234567094987654'; Primary: '')
);

procedure TestBarcodes();
var pdf: TPDF; outFile: String; x, y, w, h, pw, ph, incX, incY: Double; i, nx, ny, xx, yy, cnt: Integer; b: ^TTestBarcode; bcd: TPDFBarcode2;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.CreateNewPDF(''); // The output file is opened later
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.SetPageCoords(pcTopDown);

      pdf.InitBarcode2(bcd);

      bcd.Options := bcoDefault or bcoUseActiveFont;

      cnt  := Length(TEST_CODES);
      pw   := pdf.GetPageWidth  - 100.0;
      ph   := pdf.GetPageHeight - 100.0;
      w    := 100.0;
      h    := 120.0;
      nx   := Trunc(pw / w);
      ny   := Trunc(ph / h);
      incX := w + (pw - nx * w) / (nx-1);
      incY := h + (ph - ny * h) / (ny-1);
      h    := 100.0;
      i    := 0;
      
      while i < cnt do begin
         pdf.Append;
            pdf.SetFont('Helvetica', fsRegular, 6.5, true, cp1252);
            pdf.SetLineWidth(0.0);
            y := 50.0;
            for yy := 1 to ny do begin
               x := 50.0;
               for xx := 1 to nx do begin
                  b := @TEST_CODES[i];
                  bcd.BarcodeType := b^.BarcodeType;
                  bcd.Data        := PAnsiChar(b^.Data);
                  bcd.DataType    := b^.DataType;
                  bcd.Primary     := PAnsiChar(b^.Primary);
                  pdf.WriteFTextEx(x, y-10.0, w, -1.0, taCenter, b^.BarcodeName);
                  pdf.Rectangle(x, y, w, h, fmStroke);
                  if pdf.InsertBarcode(x, y, w, h, coCenter, coCenter, bcd) < 0 then begin
                     pdf.Free;
                     Exit;
                  end;
                  Inc(i);
                  x := x + incX;
                  if i = cnt then break;
               end;
               y := y + incY;
               if i = cnt then break;
            end;
         pdf.EndPage;
      end;

      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
      end;
      pdf.CloseFile;
      Writeln(Format('Barcodes "%s" successfully created!', [outFile]));
      ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
end;

begin
   TestBarcodes;
end.
