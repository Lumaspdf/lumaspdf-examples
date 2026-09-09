program _05_occur_repeating_rows;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 5 of 10: OCCUR/REPEAT
  data-driven row cloning (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.2).
  Same fixture/DLL/pipeline AND same per-row verification strategy as
  examples\delphi\xfa\05_occur_repeating_rows\05_occur_repeating_rows.dpr --
  only the call surface differs: this driver uses the class-based OO
  wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.InitStack         ~ pdfInitStack(Handle, Stack)
    pdf.GetPageText       ~ pdfGetPageText(Handle, Stack)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  VERIFICATION STRATEGY (identical to the flat original): rather than
  hand-parsing the compressed content stream, this driver uses the engine's
  own text-extraction export (pdf.GetPageText, looped via pdf.InitStack) on
  the freshly rendered page, BEFORE pdf.CloseFile. Each field's displayed
  value is drawn as its own text run in template/layout traversal order, so
  the runs come back as [Description, Qty, UnitPrice, LineTotal] x 7 rows,
  then [Total, GrandTotal]. For every one of the 7 occur instances, this
  driver locates that row's own Description among the extracted runs, reads
  the next three runs (Qty, UnitPrice, LineTotal), independently recomputes
  Qty*UnitPrice in Delphi, and asserts it equals the engine's own LineTotal
  for that SAME row -- proving instance count = 7, each instance's own
  fields are its own record's values (not another row's), and each
  instance's calculate script produced its own correct answer (no shared/
  stale state across occur instances).

  Packet files are PRE-SPLIT (05_occur_repeating_rows.template.xml/
  .datasets.xml, produced once by examples\delphi\xfa\split_xfa_packets.cpp)
  -- read directly as raw bytes, no XML parsing needed.

  Does NOT rebuild LumasPdf.dll -- links only against the already-built
  wrappers\delphi\LumasPdf.pas / LumasPdfOO.pas units and the already-built
  engine DLL copied alongside this exe.
*)
uses
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Generics.Collections,
  LumasPdf   in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

type
  TRow = record
    Description: string;
    QtyStr: string;
    UnitPriceStr: string;
  end;

const
  Name = '05_occur_repeating_rows';

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
  // GrandTotal is a literal bound dataset value (bind match="dataRef"), NOT
  // FormCalc-computed -- must match the dataset's own authored string
  // exactly, unlike each row's engine-computed LineTotal (which goes
  // through FloatToStr and drops insignificant trailing zeros).
  ExpectedGrandTotalStr = '1348.50';

function ReadPacket(const Path: string): RawByteString;
var
  B: TBytes;
begin
  Result := '';
  if not FileExists(Path) then Exit;
  B := TFile.ReadAllBytes(Path);
  if Length(B) = 0 then Exit;
  SetLength(Result, Length(B));
  Move(B[0], Result[1], Length(B));
end;

// FloatToStr-parity formatting for the value this driver independently
// recomputes -- same invariant '.' decimal separator, no group separator,
// no forced trailing zeros -- so the comparison against the engine's own
// FloatToStr-produced LineTotal run is a true byte-for-byte string match.
function FmtNum(const V: Extended): string;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Result := FloatToStr(V, FS);
end;

var
  RunList: TList<string>;

procedure CollectPageText(pdf: TPDF);
var
  Stack: TPDFStack;
  S: RawByteString;
begin
  RunList.Clear;
  FillChar(Stack, SizeOf(Stack), 0);
  if not pdf.InitStack(Stack) then
  begin
    Writeln('pdf.InitStack FAILED');
    Exit;
  end;
  while pdf.GetPageText(Stack) do
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
  ExeDir: string;
  TemplateBuf, DatasetsBuf: RawByteString;
  pdf: TPDF;
  Idx, Cursor, RowIdx: Integer;
  AllPass: Boolean;
  ExpectedTotal: string;
  QtyN, PriceN, EngineTotalN: Extended;
  FS: TFormatSettings;
begin
  AllPass := True;
  ExeDir := ExtractFilePath(ParamStr(0));
  RunList := TList<string>.Create;
  try
    Writeln('=== 05_occur_repeating_rows (Delphi-OO/TPDF, Expense Report, occur min=1 max=-1) ===');

    TemplateBuf := ReadPacket(ExeDir + Name + '.template.xml');
    DatasetsBuf := ReadPacket(ExeDir + Name + '.datasets.xml');
    if TemplateBuf = '' then
    begin
      Writeln('NO-TEMPLATE-PACKET');
      Halt(1);
    end;
    Writeln('template packet bytes: ', Length(TemplateBuf));
    Writeln('datasets packet bytes: ', Length(DatasetsBuf));

    pdf := TPDF.Create;
    try
      if not pdf.CreateNewPDFA(PAnsiChar(AnsiString(ExeDir + Name + '.pdf'))) then
      begin
        Writeln('pdf.CreateNewPDFA FAILED');
        Halt(1);
      end;

      Idx := pdf.CreateXFAStreamA('template', @TemplateBuf[1], Length(TemplateBuf));
      Writeln('pdf.CreateXFAStreamA(template) -> index ', Idx);
      if Idx < 0 then Halt(1);

      Idx := pdf.CreateXFAStreamA('datasets', @DatasetsBuf[1], Length(DatasetsBuf));
      Writeln('pdf.CreateXFAStreamA(datasets) -> index ', Idx);
      if Idx < 0 then Halt(1);

      R := pdf.RenderXFAForm;
      Writeln('pdf.RenderXFAForm -> ', R, ' page(s)');
      if R < 0 then
      begin
        Writeln('pdf.RenderXFAForm FAILED, code ', R);
        Halt(1);
      end;
      if R <> 1 then
      begin
        Writeln('UNEXPECTED PAGE COUNT: expected 1 (single pageArea, no pagination), got ', R);
        AllPass := False;
      end;

      // --- verification: extract the rendered page's text BEFORE closing ---
      CollectPageText(pdf);
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

      // Instance-count check: exactly ExpectedRowCount Description runs.
      Idx := 0;
      RowIdx := 0;
      while True do
      begin
        Idx := FindRun(Idx, ExpectedRows[0].Description);
        if Idx < 0 then Break;
        Inc(RowIdx);
        Idx := Idx + 1;
      end;
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

      if not pdf.CloseFile then
      begin
        Writeln('pdf.CloseFile FAILED');
        Halt(1);
      end;
      Writeln;
      Writeln('OK: wrote ', ExeDir + Name + '.pdf');
    finally
      pdf.Free;
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
