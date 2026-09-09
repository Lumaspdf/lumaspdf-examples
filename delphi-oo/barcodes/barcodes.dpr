program barcodes;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Writes every supported barcode type onto a grid of pages.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

type
  TTestBarcode = record
    BarcodeType: Integer;
    BarcodeName: PAnsiChar;
    DataType: Integer;    // 0 = bcdtBinary, 2 = bcdtGS1Mode
    Data: PAnsiChar;
    Primary: PAnsiChar;
  end;

const
  TEST_CODES: array[0..93] of TTestBarcode = (
    (BarcodeType: $3F; BarcodeName: 'Australia Post';                DataType: 0; Data: '12345678'; Primary: ''),
    (BarcodeType: $44; BarcodeName: 'Australia Redirect Code';       DataType: 0; Data: '12345678'; Primary: ''),
    (BarcodeType: $42; BarcodeName: 'Australia Reply-Paid';          DataType: 0; Data: '12345678'; Primary: ''),
    (BarcodeType: $43; BarcodeName: 'Australia Routing Code';        DataType: 0; Data: '12345678'; Primary: ''),
    (BarcodeType: $5C; BarcodeName: 'Aztec binary mode';             DataType: 0; Data: '123456789012'; Primary: ''),
    (BarcodeType: $5C; BarcodeName: 'Aztec GS1 Mode';                DataType: 2; Data: '[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917'; Primary: ''),
    (BarcodeType: $80; BarcodeName: 'Aztec Runes';                   DataType: 0; Data: '123'; Primary: ''),
    (BarcodeType: $04; BarcodeName: 'Code 2 of 5 IATA';              DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $07; BarcodeName: 'Code 2 of 5 Industrial';        DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $03; BarcodeName: 'Code 2 of 5 Interleaved';       DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $06; BarcodeName: 'Code 2 of 5 Data Logic';        DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $02; BarcodeName: 'Code 2 of 5 Matrix';            DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $8C; BarcodeName: 'Channel Code';                  DataType: 0; Data: '1234567'; Primary: ''),
    (BarcodeType: $12; BarcodeName: 'Codabar';                       DataType: 0; Data: 'A123456789B'; Primary: ''),
    (BarcodeType: $4A; BarcodeName: 'Codablock-F';                   DataType: 0; Data: '1234567890abcdefghijklmnopqrstuvwxyz'; Primary: ''),
    (BarcodeType: $01; BarcodeName: 'Code 11';                       DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $14; BarcodeName: 'Code 128';                      DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $3C; BarcodeName: 'Code 128';                      DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $17; BarcodeName: 'Code 16K binary mode';          DataType: 0; Data: '[90]A1234567890'; Primary: ''),
    (BarcodeType: $17; BarcodeName: 'Code 16K GS1 mode';             DataType: 2; Data: '[90]A1234567890'; Primary: ''),
    (BarcodeType: $81; BarcodeName: 'Code 32';                       DataType: 0; Data: '12345678'; Primary: ''),
    (BarcodeType: $08; BarcodeName: 'Code 39';                       DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $18; BarcodeName: 'Code 49';                       DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $19; BarcodeName: 'Code 93';                       DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $8D; BarcodeName: 'Code One';                      DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $5D; BarcodeName: 'DAFT Code';                     DataType: 0; Data: 'aftdaftdftaft'; Primary: ''),
    (BarcodeType: $1D; BarcodeName: 'GS1 DataBar Omnidirectional';   DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $51; BarcodeName: 'GS1 DataBar Stacked';           DataType: 0; Data: '[90]1234567890'; Primary: ''),
    (BarcodeType: $1F; BarcodeName: 'GS1 DataBar Expanded';          DataType: 0; Data: '[90]1234567890'; Primary: ''),
    (BarcodeType: $1E; BarcodeName: 'GS1 DataBar Limited';           DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $4F; BarcodeName: 'GS1 DataBar Stacked';           DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $50; BarcodeName: 'GS1 DataBar Stacked Omni';      DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $47; BarcodeName: 'Data Matrix ISO 16022';         DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $73; BarcodeName: 'DotCode';                       DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $60; BarcodeName: 'DPD Code';                      DataType: 0; Data: '1234567890123456789012345678'; Primary: ''),
    (BarcodeType: $16; BarcodeName: 'Deutsche Post Identcode';       DataType: 0; Data: '12345678901'; Primary: ''),
    (BarcodeType: $15; BarcodeName: 'Deutsche Post Leitcode';        DataType: 0; Data: '1234567890123'; Primary: ''),
    (BarcodeType: $10; BarcodeName: 'EAN 128';                       DataType: 0; Data: '[90]0101234567890128TEC-IT'; Primary: ''),
    (BarcodeType: $83; BarcodeName: 'EAN 128 Composite Code';        DataType: 0; Data: '[10]1234-1234'; Primary: '[90]123456'),
    (BarcodeType: $48; BarcodeName: 'EAN 14';                        DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $0D; BarcodeName: 'EAN X';                         DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $82; BarcodeName: 'EAN Composite Symbol';          DataType: 0; Data: '[90]12341234'; Primary: '12345678'),
    (BarcodeType: $0E; BarcodeName: 'EAN + Check Digit';             DataType: 0; Data: '12345'; Primary: ''),
    (BarcodeType: $09; BarcodeName: 'Ext. Code 3 of 9 (Code 39+)';   DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $31; BarcodeName: 'FIM';                           DataType: 0; Data: 'd'; Primary: ''),
    (BarcodeType: $1C; BarcodeName: 'Flattermarken';                 DataType: 0; Data: '11111111111111'; Primary: ''),
    (BarcodeType: $70; BarcodeName: 'HIBC Aztec Code';               DataType: 0; Data: '123456789012'; Primary: ''),
    (BarcodeType: $6E; BarcodeName: 'HIBC Codablock-F';              DataType: 0; Data: '1234567890abcdefghijklmnopqrstuvwxyz'; Primary: ''),
    (BarcodeType: $62; BarcodeName: 'HIBC Code 128';                 DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $63; BarcodeName: 'HIBC Code 39';                  DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $66; BarcodeName: 'HIBC Data Matrix';              DataType: 0; Data: '0123456789012'; Primary: ''),
    (BarcodeType: $6C; BarcodeName: 'HIBC Micro PDF417';             DataType: 0; Data: '01234567890abcde'; Primary: ''),
    (BarcodeType: $6A; BarcodeName: 'HIBC PDF417';                   DataType: 0; Data: '01234567890abcde'; Primary: ''),
    (BarcodeType: $68; BarcodeName: 'HIBC QR Code';                  DataType: 0; Data: '01234567890abcde'; Primary: ''),
    (BarcodeType: $45; BarcodeName: 'ISBN (EAN-13 with validation)'; DataType: 0; Data: '0123456789'; Primary: ''),
    (BarcodeType: $59; BarcodeName: 'ITF-14';                        DataType: 0; Data: '0123456789'; Primary: ''),
    (BarcodeType: $4C; BarcodeName: 'Japanese Postal Code';          DataType: 0; Data: '0123456789'; Primary: ''),
    (BarcodeType: $5A; BarcodeName: 'Dutch Post KIX Code';           DataType: 0; Data: '0123456789'; Primary: ''),
    (BarcodeType: $4D; BarcodeName: 'Korea Post';                    DataType: 0; Data: '123456'; Primary: ''),
    (BarcodeType: $32; BarcodeName: 'LOGMARS';                       DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $79; BarcodeName: 'Royal Mail 4-State Mailmark';   DataType: 0; Data: '11210012341234567AB19XY1A'; Primary: ''),
    (BarcodeType: $39; BarcodeName: 'Maxicode';                      DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $54; BarcodeName: 'Micro PDF417';                  DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $61; BarcodeName: 'Micro QR Code';                 DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $47; BarcodeName: 'MSI Plessey';                   DataType: 0; Data: '12345678901'; Primary: ''),
    (BarcodeType: $4B; BarcodeName: 'NVE-18';                        DataType: 0; Data: '1234567890123456'; Primary: ''),
    (BarcodeType: $37; BarcodeName: 'PDF417';                        DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $38; BarcodeName: 'PDF417 Truncated';              DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $33; BarcodeName: 'Pharmacode One-Track';          DataType: 0; Data: '123456'; Primary: ''),
    (BarcodeType: $35; BarcodeName: 'Pharmacode Two-Track';          DataType: 0; Data: '123456'; Primary: ''),
    (BarcodeType: $52; BarcodeName: 'PLANET';                        DataType: 0; Data: '12345678901'; Primary: ''),
    (BarcodeType: $56; BarcodeName: 'Plessey';                       DataType: 0; Data: '12345678901'; Primary: ''),
    (BarcodeType: $28; BarcodeName: 'PostNet';                       DataType: 0; Data: '12345678901'; Primary: ''),
    (BarcodeType: $34; BarcodeName: 'PZN';                           DataType: 0; Data: '1234567'; Primary: ''),
    (BarcodeType: $3A; BarcodeName: 'QR Code';                       DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $91; BarcodeName: 'Rect. Micro QR Code (rMQR)';    DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $46; BarcodeName: 'Royal Mail 4 State (RM4SCC)';   DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $86; BarcodeName: 'CS GS1 DataBar Ext. component'; DataType: 0; Data: '[90]12341234'; Primary: '[10]12345678'),
    (BarcodeType: $8B; BarcodeName: 'CS GS1 DataBar Exp. Stacked';   DataType: 0; Data: '[90]12341234'; Primary: '[10]12345678'),
    (BarcodeType: $85; BarcodeName: 'CS GS1 DataBar Limited';        DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $84; BarcodeName: 'CS GS1 DataBar-14 Linear';      DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $89; BarcodeName: 'CS GS1 DataBar-14 Stacked';     DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $8A; BarcodeName: 'CS GS1 DataBar-14 Stacked Omni';DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $20; BarcodeName: 'Telepen Alpha';                 DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $90; BarcodeName: 'Ultracode';                     DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $22; BarcodeName: 'UPC A';                         DataType: 0; Data: '1234567890'; Primary: ''),
    (BarcodeType: $87; BarcodeName: 'CS UPC A linear';               DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $23; BarcodeName: 'UPC A + Check Digit';           DataType: 0; Data: '12345678905'; Primary: ''),
    (BarcodeType: $25; BarcodeName: 'UCP E';                         DataType: 0; Data: '1234567'; Primary: ''),
    (BarcodeType: $88; BarcodeName: 'CS UPC E linear';               DataType: 0; Data: '[90]12341234'; Primary: '1234567'),
    (BarcodeType: $26; BarcodeName: 'UCP E + Check Digit';           DataType: 0; Data: '12345670'; Primary: ''),
    (BarcodeType: $8F; BarcodeName: 'UPNQR (Univ. Placilni Nalog QR)';DataType: 0; Data: '1234567890abcdef'; Primary: ''),
    (BarcodeType: $55; BarcodeName: 'USPS OneCode';                  DataType: 0; Data: '01234567094987654321'; Primary: ''),
    (BarcodeType: $49; BarcodeName: 'Vehicle Ident Number (USA)';    DataType: 0; Data: '01234567094987654'; Primary: '')
  );

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  outFile: AnsiString;
  x, y, w, h, pw, ph, incX, incY: Double;
  i, nx, ny, xx, yy, cnt: Integer;
  bcd: TPDFBarcode2;
begin
  pdf := TPDF.Create;
  try
    pdf.CreateNewPDFA('');
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.SetPageCoords(Ord(pcTopDown));

    FillChar(bcd, SizeOf(bcd), 0);
    bcd.StructSize := SizeOf(TPDFBarcode2);
    pdfInitBarcode2(bcd);
    bcd.Options := bcoDefault or bcoUseActiveFont;

    cnt := 94;
    pw := pdf.GetPageWidth - 100.0;
    ph := pdf.GetPageHeight - 100.0;
    w := 100.0;
    h := 120.0;
    nx := Trunc(pw / w);
    ny := Trunc(ph / h);
    incX := w + (pw - nx * w) / (nx - 1);
    incY := h + (ph - ny * h) / (ny - 1);
    h := 100.0;
    i := 0;

    while i < cnt do
    begin
      pdf.Append;
      pdf.SetFontA('Helvetica', fsRegular, 6.5, True, cp1252);
      pdf.SetLineWidth(0.0);
      y := 50.0;
      for yy := 1 to ny do
      begin
        x := 50.0;
        for xx := 1 to nx do
        begin
          bcd.BarcodeType := TEST_CODES[i].BarcodeType;
          bcd.Data        := TEST_CODES[i].Data;
          bcd.DataType    := TEST_CODES[i].DataType;
          bcd.Primary     := TEST_CODES[i].Primary;
          pdf.WriteFTextExA(x, y - 10.0, w, -1.0, Ord(taCenter), TEST_CODES[i].BarcodeName);
          pdf.Rectangle(x, y, w, h, Ord(fmStroke));
          if pdf.InsertBarcode(x, y, w, h, coCenter, coCenter, bcd) < 0 then
            Exit;
          Inc(i);
          x := x + incX;
          if i = cnt then Break;
        end;
        y := y + incY;
        if i = cnt then Break;
      end;
      pdf.EndPage;
    end;

    outFile := '';
    if pdf.HaveOpenDoc then
    begin
      outFile := AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf');
      if not pdf.OpenOutputFileA(PAnsiChar(outFile)) then Exit;
    end;
    pdf.CloseFile;
    Writeln('Barcodes "' + string(outFile) + '" successfully created!');
  finally
    pdf.Free;
  end;
end.
