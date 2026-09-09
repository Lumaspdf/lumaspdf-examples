# VB6 → ActiveX zero-wrapper conversion (read fully)

Convert each VB6 example from the flat DLL wrapper to the **registered ActiveX object**, with
**ZERO wrapper modules** (no LumasPdf.bas, no LumasPdfApi1-4). Early-bind to the LumasPdfAX type
library — the OO object + ALL enums + ALL constants come from the typelib. This is the user's
required VB6 model. Reference example already done: `examples\Vb6\hello_world` — mirror its shape.

## The `.vbp` (replace the 5 wrapper Module lines with ONE Reference line)
```
Type=Exe
Reference=*\G{E2FE2B22-5FF6-5275-A6E7-575E68D36DDD}#1.0#0#..\..\..\wrappers\activex\bin32\LumasPdfAX32.dll#LumasPdfAX
Module=mod<Name>; <name>.bas
Startup="Sub Main"
ExeName32="<name>.exe"
Name="<name>"
```
Adjust the `..\..\..\` depth to reach `wrappers\activex\bin32\LumasPdfAX32.dll` from the example folder
(depth-1 folder e.g. `bookmarks\` = `..\..\`; depth-2 e.g. `acroform\check_boxes\` = `..\..\..\`;
`reporting\` = `..\..\`). For a **callback** example that needs a `.cls` (see below), add a `Class=` line.

## The `.bas` — translation rules
- `Dim pdf As New LumasPdfAX.LumasPDF` (library=LumasPdfAX, coclass=LumasPDF). `pdf.RaiseExceptions = True`.
- Flat `pdfFoo(handle, args)` → OO `pdf.Foo args` (drop the `pdf` prefix AND the handle first-arg).
  Keep the `A`/`W` suffix exactly (e.g. `pdfCreateNewPDFA p, ""` → `pdf.CreateNewPDFA ""`;
  `pdfSetFontA p, "Arial", fsBold, 12#, 1, cp1252` → `pdf.SetFontA "Arial", fsBold, 12#, True, cp1252`).
  LongBool args: pass `True`/`False`. Return-value checks: methods return the same value (`If pdf.Append ...`).
- Enums (fsItalic, cp1252, taCenter, diCreator, dtFit, fmFill, ...) AND constants (PDF_RED, NO_COLOR,
  RPT_EXP_PDF, RPT_FEAT_*, E_WARNING, ...) come from the TLB — use them by name directly, NO local consts.
- DELETE the flat helpers that the wrapper needed: the error callback (`ErrProc`/`SetOnErrorProc AddressOf`),
  `PtrToAnsi`/`CopyMemory`/`lstrlen` declares, `FnPtr`/`VarPtr` marshalling. Errors now come as VB6
  exceptions — wrap risky calls in `On Error` where the original tolerated errors, or rely on RaiseExceptions.
- Handle string/pointer OUT params via the AX object's OO signatures (many now return values or take OleVariant).
  The matching ActiveX **`.vbs`** port at `examples\activex\<same-subpath>\<name>.vbs` shows the exact OO call
  shapes (method names, arg order, enum values) — USE IT as the primary translation reference; the flat
  `.bas` shows the full logic/fixtures. (VB6 uses the same method names as the .vbs.)

## Callback examples → `WithEvents` class (early-bound)
If the flat example used a REAL callback (page-break, parse/ParseContent, rpt custom function/provider,
font-not-found/ICC — NOT just an error callback), the AX delivers it as a COM event. VB6 sinks events with
`WithEvents`, which requires a **class module**. Add `<Name>Evt.cls`:
```
VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "<Name>Evt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Public WithEvents Pdf As LumasPdfAX.LumasPDF
Attribute Pdf.VB_VarHelpID = -1
' event names/args mirror the .vbs PDF_OnXxx handlers; every event has a trailing ResultCode
Private Sub Pdf_OnPageBreak(ByVal LastPosX As Double, ByVal LastPosY As Double, ByVal PageBreak As Long, ResultCode As Long)
    ...
End Sub
```
Drive it from Sub Main: `Dim e As New <Name>Evt : Set e.Pdf = New LumasPdfAX.LumasPDF : e.Pdf.CreateNewPDFA ...`.
For rpt custom function/provider/exporter and ParseContent use the SAME COM methods the .vbs uses
(`pdf.RptRegisterFunctionEvent`, `pdf.RptRegisterProviderEvent`, `pdf.ParseContentEvents`) + the matching
`Pdf_OnRptFunction`/`Pdf_OnParse*` event subs. (These VB6 examples end up ~identical to the .vbs, just
compiled + early-bound.) If a specific example genuinely can't be expressed (same limits the .vbs hit —
e.g. image_extraction pixel buffer), keep it running with the same graceful degradation the .vbs used.

## Build + verify
Prereq: the 32-bit AX server is registered (`regsvr32 /s wrappers\activex\bin32\LumasPdfAX32.dll` — already done).
Build with `tools\build_vb6.bat <name>.vbp <errlog>` (CRLF-normalise .bas/.cls/.vbp first:
`sed -i 's/\r$//; s/$/\r/' *.bas *.cls *.vbp`). Run the exe fresh and confirm it reproduces the same
output the flat version produced (valid `%PDF`, correct sizes). Same fixtures as before (sample_multipage.pdf,
test_files\*, Northwind.mdb, test_cert.pfx pw 123456). print_pdf = compile-only (printer). pdfviewer = the
embedded viewer blocks (8s-timeout = PASS). Delete the old flat `.exe`; keep the folder's staged engine DLL.

Write results to a per-batch report. Return a concise table: example -> CONVERTED+BUILD ok/RUN ok / issue.
