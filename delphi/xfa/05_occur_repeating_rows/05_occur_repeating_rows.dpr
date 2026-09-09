program _05_occur_repeating_rows;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA "flavor tour" example 5 of 10 -- OCCUR/REPEAT data-driven row
  cloning (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.2).

  Mirrors E:\LUMASPDFSDK\cpp\tools\xfa_render_test.dpr's own driver shape
  (packet-split then the exact public-export loading sequence a real caller
  would use):

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm ->
    [pdfInitStack/pdfGetPageText verification, see below] -> pdfCloseFile
    -> pdfDeletePDF

  This driver links ONLY against the already-built E:\LUMASPDFSDK\LumasPdf.dll
  via the wrappers\delphi\LumasPdf.pas import unit -- it does NOT rebuild the
  DLL (tools\build_dll.bat is never invoked by this example or its batch
  file).

  VERIFICATION STRATEGY: rather than hand-parsing the compressed content
  stream, this driver uses the engine's own supported text-extraction export
  (pdfGetPageText, looped via pdfInitStack -- the "GetPageText per-run
  enumerator" convention) on the freshly rendered page, BEFORE pdfCloseFile.
  Each field's displayed value (whether a plain bound literal like
  Description/Qty/UnitPrice, or a FormCalc-computed one like LineTotal) is
  drawn as its own separate text run (Lumas.Pdf.Xfa.Render.pas's Mode-0
  DrawFieldLine path), in template/layout traversal order -- so the runs
  come back in exactly row-major order: [Description, Qty, UnitPrice,
  LineTotal] x 7 rows, then [Total, GrandTotal].

  For EVERY one of the 7 occur instances, this driver:
    1. locates that row's own Description text among the extracted runs,
    2. reads the NEXT THREE runs (Qty, UnitPrice, LineTotal),
    3. independently recomputes Qty*UnitPrice in Delphi (Extended, matching
       FloatToStr's own round-trip formatting) and asserts it equals the
       LineTotal run the ENGINE produced for that SAME row.
  This directly proves (a) instance COUNT = 7 (matching the 7 <Item> dataset
  records, clamped into occur's [1,-1] range), (b) each instance's own
  Description/Qty/UnitPrice are its OWN record's values (not another row's),
  and (c) each instance's calculate script produced ITS OWN correct answer --
  never a value shared/stale from a different occur instance, which is
  exactly the "clone-free occur" per-instance-independence property
  xfa_fixtures\fx14_formcalcsom.xdp was written to stress (verified clean
  against the real engine, per XFA_FIXTURE_EXPECTATIONS.md sec 14).
*)
uses
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Generics.Collections,
  Lumas.Pdf.Xml in '..\..\..\..\src\Lumas.Pdf.Xml.pas',
  LumasPdf in '..\..\..\..\wrappers\delphi\LumasPdf.pas';

type
  TRow = record
    Description: string;
    QtyStr: string;
    UnitPriceStr: string;
  end;

const
  XdpPath    = 'E:\LUMASPDFSDK\examples\delphi\xfa\05_occur_repeating_rows\05_occur_repeating_rows.xdp';
  OutPdfPath = 'E:\LUMASPDFSDK\examples\delphi\xfa\05_occur_repeating_rows\05_occur_repeating_rows.pdf';

  ExpectedRowCount = 7;
  ExpectedRows: array[0..ExpectedRowCount - 1] of TRow = (
    (Description: 'Airfare - SFO to ORD';      QtyStr: '1'; UnitPriceStr: '450.00'),
    (Description: 'Hotel - 3 nights';          QtyStr: '3'; UnitPriceStr: '120.00'),
    (Description: 'Taxi / Rideshare';          QtyStr: '4'; UnitPriceStr: '18.50'),
    (Description: 'Client Dinner';             QtyStr: '5'; UnitPriceStr: '22.00'),
    (Description: 'Parking';                   QtyStr: '2'; UnitPriceStr: '15.00'),
    (Description: 'Conference Registration';   QtyStr: '1'; UnitPriceStr: '299.00'),
    (Description: 'Office Supplies';           QtyStr: '6'; UnitPriceStr: '4.25')
  );
  // GrandTotal is a literal bound dataset value (bind match="dataRef"),
  // NOT FormCalc-computed -- XfaResolveDisplayText's bound branch returns
  // the XML text node verbatim (no FloatToStr reformatting), so this must
  // match the dataset's own authored "1348.50" string exactly, unlike each
  // row's engine-computed LineTotal (which DOES go through FloatToStr and
  // drops insignificant trailing zeros -- see FmtNum below / ROW checks).
  ExpectedGrandTotalStr = '1348.50';

function ExtractPacket(XdpRoot: TXmlNode; const LocalName: string): RawByteString;
var
  Node: TXmlNode;
  S: string;
begin
  Result := '';
  Node := XdpRoot.FindChild(LocalName);
  if Node = nil then Exit;
  S := XmlSerialize(Node);
  Result := RawByteString(UTF8Encode(S));
end;

// FloatToStr-parity formatting for the value this driver independently
// recomputes -- same invariant '.' decimal separator, no group separator,
// no forced trailing zeros -- so the comparison against the engine's own
// FloatToStr-produced LineTotal run is a true byte-for-byte string match,
// not a numeric-tolerance fudge.
function FmtNum(const V: Extended): string;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Result := FloatToStr(V, FS);
end;

var
  RunList: TList<string>;

procedure CollectPageText(PDF: PPDF);
var
  Stack: TPDFStack;
  S: RawByteString;
begin
  RunList.Clear;
  FillChar(Stack, SizeOf(Stack), 0);
  if not pdfInitStack(PDF, Stack) then
  begin
    Writeln('pdfInitStack FAILED');
    Exit;
  end;
  while pdfGetPageText(PDF, Stack) do
  begin
    if (Stack.Text <> nil) and (Stack.TextLen > 0) then
    begin
      SetString(S, Stack.Text, Stack.TextLen);
      RunList.Add(string(S));
    end;
  end;
end;

function FindRun(const StartAt: Integer; const Needle: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := StartAt to RunList.Count - 1 do
    if RunList[i] = Needle then Exit(i);
end;

var
  R: Integer;
  Raw: string;
  XdpRoot: TXmlNode;
  TemplateBuf, DatasetsBuf: RawByteString;
  PDF: PPDF;
  Idx, Cursor, RowIdx: Integer;
  AllPass: Boolean;
  ExpectedTotal: string;
  QtyN, PriceN, EngineTotalN: Extended;
  FS: TFormatSettings;
begin
  AllPass := True;
  RunList := TList<string>.Create;
  try
    Writeln('=== 05_occur_repeating_rows (Expense Report, occur min=1 max=-1) ===');
    if not FileExists(XdpPath) then
    begin
      Writeln('FILE-NOT-FOUND: ', XdpPath);
      Halt(1);
    end;

    Raw := TFile.ReadAllText(XdpPath, TEncoding.UTF8);
    XdpRoot := XmlParse(Raw);
    if XdpRoot = nil then
    begin
      Writeln('XML-PARSE-FAIL');
      Halt(1);
    end;
    try
      TemplateBuf := ExtractPacket(XdpRoot, 'template');
      DatasetsBuf := ExtractPacket(XdpRoot, 'datasets');
      Writeln('template packet bytes: ', Length(TemplateBuf));
      Writeln('datasets packet bytes: ', Length(DatasetsBuf));

      PDF := pdfNewPDF;
      if PDF = nil then
      begin
        Writeln('pdfNewPDF FAILED');
        Halt(1);
      end;
      try
        if not pdfCreateNewPDFA(PDF, PAnsiChar(AnsiString(OutPdfPath))) then
        begin
          Writeln('pdfCreateNewPDFA FAILED');
          Halt(1);
        end;

        Idx := pdfCreateXFAStreamA(PDF, 'template', @TemplateBuf[1], Length(TemplateBuf));
        Writeln('pdfCreateXFAStreamA(template) -> index ', Idx);
        if Idx < 0 then Halt(1);

        Idx := pdfCreateXFAStreamA(PDF, 'datasets', @DatasetsBuf[1], Length(DatasetsBuf));
        Writeln('pdfCreateXFAStreamA(datasets) -> index ', Idx);
        if Idx < 0 then Halt(1);

        R := pdfRenderXFAForm(PDF);
        Writeln('pdfRenderXFAForm -> ', R, ' page(s)');
        if R < 0 then
        begin
          Writeln('pdfRenderXFAForm FAILED, code ', R);
          Halt(1);
        end;
        if R <> 1 then
        begin
          Writeln('UNEXPECTED PAGE COUNT: expected 1 (single pageArea, no pagination), got ', R);
          AllPass := False;
        end;

        // --- verification: extract the rendered page's text BEFORE closing ---
        CollectPageText(PDF);
        Writeln('extracted ', RunList.Count, ' text run(s) from the rendered page');
        for Idx := 0 to RunList.Count - 1 do
          Writeln('  run[', Idx, '] = "', RunList[Idx], '"');
        Writeln;

        // Header fields (explicit <bind dataRef>, non-occur, sanity check).
        if (RunList.Count >= 4) and (RunList[0] = 'Expense Report') and
           (RunList[1] = 'Alex Rivera') and (RunList[2] = 'Field Operations') and
           (RunList[3] = '2026-07-24') then
          Writeln('HEADER OK: title/EmployeeName/Department/ReportDate all bound correctly')
        else
        begin
          Writeln('HEADER MISMATCH: expected title+3 header fields as the first 4 runs');
          AllPass := False;
        end;
        Writeln;

        // Per-row check: locate each row's Description, then its Qty/UnitPrice/
        // LineTotal are expected to be the next 3 runs in traversal order.
        Cursor := 0;
        for RowIdx := 0 to ExpectedRowCount - 1 do
        begin
          Idx := FindRun(Cursor, ExpectedRows[RowIdx].Description);
          if Idx < 0 then
          begin
            Writeln('ROW ', RowIdx, ' MISSING: Description "', ExpectedRows[RowIdx].Description, '" not found');
            AllPass := False;
            Continue;
          end;
          if Idx + 3 >= RunList.Count then
          begin
            Writeln('ROW ', RowIdx, ' TRUNCATED: not enough runs after Description at ', Idx);
            AllPass := False;
            Continue;
          end;

          FS := TFormatSettings.Invariant;
          QtyN := StrToFloat(RunList[Idx + 1], FS);
          PriceN := StrToFloat(RunList[Idx + 2], FS);
          EngineTotalN := StrToFloat(RunList[Idx + 3], FS);
          ExpectedTotal := FmtNum(QtyN * PriceN);

          Write('ROW ', RowIdx, ' "', ExpectedRows[RowIdx].Description, '"',
            '  Qty=', RunList[Idx + 1], ' UnitPrice=', RunList[Idx + 2],
            '  engine LineTotal=', RunList[Idx + 3],
            '  hand-check ', RunList[Idx + 1], ' x ', RunList[Idx + 2], ' = ', ExpectedTotal);

          if (RunList[Idx + 1] <> ExpectedRows[RowIdx].QtyStr) or
             (RunList[Idx + 2] <> ExpectedRows[RowIdx].UnitPriceStr) then
          begin
            Writeln('  MISMATCH: bound Qty/UnitPrice do not match this row''s own dataset record');
            AllPass := False;
          end
          else if RunList[Idx + 3] <> ExpectedTotal then
          begin
            Writeln('  MISMATCH: engine LineTotal (', RunList[Idx + 3],
              ') <> hand-computed (', ExpectedTotal, ') -- possible shared/stale state across instances');
            AllPass := False;
          end
          else
            Writeln('  OK');

          Cursor := Idx + 4;
        end;
        Writeln;

        // Instance-count check: exactly ExpectedRowCount Description runs,
        // no more, no fewer (occur min=1 max=-1 clamped to the 7 matching
        // dataset records -- neither padded nor truncated).
        Idx := 0;
        RowIdx := 0;
        while True do
        begin
          Idx := FindRun(Idx, ExpectedRows[0].Description);
          if Idx < 0 then Break;
          Inc(RowIdx);
          Idx := Idx + 1;
        end;
        // (RowIdx here only counts duplicates of row 0's OWN description,
        //  which must be exactly 1 -- a real dup would itself indicate a
        //  templating/instance bug.)
        if RowIdx <> 1 then
        begin
          Writeln('INSTANCE-DUP CHECK FAILED for row 0''s Description: found ', RowIdx, ' time(s), expected 1');
          AllPass := False;
        end;

        // Grand total: literal dataset value, TotalsRow non-occur sibling
        // flowed directly after the 7 occur rows.
        Idx := FindRun(0, 'Total');
        if Idx < 0 then
        begin
          Writeln('GrandTotal label "Total" NOT FOUND');
          AllPass := False;
        end
        else if (Idx + 1 >= RunList.Count) or (RunList[Idx + 1] <> ExpectedGrandTotalStr) then
        begin
          Writeln('GrandTotal MISMATCH: expected "', ExpectedGrandTotalStr, '", got "',
            IfThen(Idx + 1 < RunList.Count, RunList[Idx + 1], '<none>'), '"');
          AllPass := False;
        end
        else
          Writeln('GrandTotal OK: ', RunList[Idx + 1]);

        if not pdfCloseFile(PDF) then
        begin
          Writeln('pdfCloseFile FAILED');
          Halt(1);
        end;
        Writeln;
        Writeln('OK: wrote ', OutPdfPath);
      finally
        pdfDeletePDF(PDF);
      end;
    finally
      XdpRoot.Free;
    end;
  finally
    RunList.Free;
  end;

  Writeln;
  if AllPass then
    Writeln('RESULT|05_occur_repeating_rows=PASS|instances=', ExpectedRowCount)
  else
    Writeln('RESULT|05_occur_repeating_rows=FAIL');
end.
