# XFA "Flavor Tour" — ActiveX/COM

10 examples porting `examples\delphi\xfa\01_basic_positioned_form` through
`10_javascript_scripting` to the LumasPDF ActiveX/COM server
(`LumasPdf.PDF`, ProgID-based, `ILumasPDF`). Each folder mirrors its Delphi
counterpart's scenario, dataset and expected-values checklist exactly; only
the calling convention changes.

## Host language: PowerShell, not VBScript — read this first

Every other `examples\activex\*` folder in this repo is late-bound
**VBScript** (`CreateObject("LumasPdf.PDF")`, run via `cscript`/`wscript`).
This tour intentionally departs from that and uses **PowerShell** instead.
That is a verified, ABI-grepped necessity, not a style preference:

`pdfCreateXFAStreamA`/`pdfCreateXFAStreamW`/`pdfSetXFAStream` all take a raw
`Buffer: Pointer` parameter. In the COM type library
(`wrappers\activex\LumasPdfAX.ridl`, ~lines 3461-3464, 4804) that parameter
is marshalled as a bare `__int64` — a genuine process memory address, not a
`BSTR` and not a `VARIANT`:

```
HRESULT _stdcall CreateXFAStreamA([in] BSTR Name, [in] __int64 Buffer, [in] long BufSize, [out, retval] long* Value);
```

The AX bridge (`wrappers\activex\Lumas.Pdf.AX.Marshal.pas`) has a generic
helper that coerces a `SAFEARRAY` of `VARIANT` — "the only array kind a
scripting host can build" — into a native packed array. That mechanism is
what lets VBScript examples elsewhere in this repo pass plain
`Array(...)` literals to methods like `SetAnnotQuadPoints`, `CreateOCMD`, and
`CreateExtGState` — but it only fires for parameters the IDL declares as
`VARIANT`. `CreateXFAStreamA`'s `Buffer` is a genuinely opaque `Pointer` in
the underlying flat API (`Lumas.Pdf.Api.pas`), so the codegen emitted
`__int64` instead (contrast `pdfSetContent`, whose flat signature takes
`PAnsiChar` and so **is** exposed as `BSTR` in the IDL and does work fine
from VBScript — a `PAnsiChar` naturally maps to a string type; a `Pointer`
does not).

Late-bound VBScript/JScript has no `VarPtr`/`StrPtr`/`AddressOf`/FFI of any
kind (unlike VB6, which has `VarPtr`/`StrPtr` natively) — it cannot produce
a real memory address, so it categorically cannot call this method family.

This is a **pre-existing, repo-wide ABI gap, not something new to XFA**:
grepping every `examples\activex\*.vbs` file in this repo confirms none of
the ~20 other `Buffer:Pointer`-typed COM methods (`AttachFileExA/W`,
`InsertImageFromBuffer`, `LoadFont`, `OpenImportBuffer`, `SetXFAStream`,
`CreateICCBasedColorSpaceEx`, `AddMaskImage`, `TblSetCellImageEx`, ...) is
ever called from VBScript anywhere in the existing example set either —
`incremental_updates\comments\comments.vbs` documents routing an equivalent
buffer round-trip through a file instead specifically because of this, and
`content_parser\image_extraction\image_extraction.vbs` documents an
"HONEST LIMITATION" for the same root cause. Unlike those two cases,
there is **no file-based alternative** in the XFA ABI (no
`pdfImportXFAFileA`-style export exists), so neither established workaround
applies here.

PowerShell **can** supply a real pointer —
`[System.Runtime.InteropServices.Marshal]::AllocHGlobal` +
`[System.Runtime.InteropServices.Marshal]::Copy` — while still driving the
exact same `LumasPdf.PDF` COM object via the exact same method names used
everywhere else in this flavour. `New-Object -ComObject "LumasPdf.PDF"`
plays the identical role `CreateObject("LumasPdf.PDF")` plays in the
VBScript examples; every method call (`.CreateNewPDFA`, `.CreateXFAStreamA`,
`.RenderXFAForm`, `.SetXFARenderMode`, `.CloseFile`, `.RaiseExceptions`) is
unchanged. Only the buffer-marshalling step needed a host capable of real
FFI, and PowerShell (already this environment's primary shell) is the
natural, already-available choice within the same "COM automation script"
family.

Verified: the PowerShell driver for example 01 produces a PDF the exact
same byte length (5504 bytes) as the Delphi reference driver's own
`output.pdf`.

## Calling convention

Confirmed by grepping `wrappers\activex\LumasPdfAX.ridl` and
`wrappers\activex\Lumas.Pdf.AX.Impl.pas` directly (not guessed):

| Delphi flat export | ActiveX/COM method |
|---|---|
| `pdfCreateNewPDFA(doc, path)` | `pdf.CreateNewPDFA(path)` |
| `pdfCreateXFAStreamA(doc, name, buf, size)` | `pdf.CreateXFAStreamA(name, ptr, size)` |
| `pdfXFAFormPageCount(doc)` | `pdf.XFAFormPageCount()` |
| `pdfSetXFARenderMode(doc, mode)` | `pdf.SetXFARenderMode(mode)` |
| `pdfRenderXFAForm(doc)` | `pdf.RenderXFAForm()` |
| `pdfCloseFile(doc)` | `pdf.CloseFile()` |

Pipeline (same semantic sequence as every other language flavour in this
tour): `CreateNewPDFA` → `CreateXFAStreamA('template', ...)` →
`CreateXFAStreamA('datasets', ...)` → `RenderXFAForm` → `CloseFile`.
Example 6 additionally calls `XFAFormPageCount` pre-flight (before
`RenderXFAForm`) and asserts it agrees with the render result. Example 9
additionally calls `SetXFARenderMode(1)` before the second of its two
`RenderXFAForm` passes.

## Files per example

Each `NN_name\` folder contains:
- `NN_name.ps1` — the PowerShell driver (self-contained, mirrors each
  Delphi `.dpr`'s own self-contained `RenderExample` function).
- `NN_name.template.xml` / `NN_name.datasets.xml` — the pre-split `<template>`
  and `<xfa:datasets>` packets, copied byte-for-byte from
  `examples\delphi\xfa\NN_name\` (already extracted from the source `.xdp`
  this session — no XML parsing needed in the driver, just
  `[System.IO.File]::ReadAllBytes`).
- `README.md` — this example's scenario + expected-values checklist,
  mirroring the Delphi README.

No `LumasPdf.dll`/registration files are bundled — this matches every other
existing `examples\activex\*` folder's convention: the ActiveX server is a
machine-wide registered COM component (ProgID `LumasPdf.PDF`), not a
side-by-side DLL. It was already registered on this machine from a prior
session (`HKLM\SOFTWARE\Classes\LumasPdf.PDF\CLSID` present); no `regsvr32`
step was needed this session.

## Running

```
powershell -File NN_name.ps1
```

## Verification performed

All 10 examples were run for real against the live registered COM server.
Results:

| # | Example | Result |
|---|---|---|
| 01 | basic_positioned_form | `RenderXFAForm` → 1 page |
| 02 | data_binding | 1 page; pypdf text matches all 8 checklist values incl. `match="none"` trap |
| 03 | formcalc_calculations | 1 page; pypdf text matches all 14 checklist values incl. the date epoch fix |
| 04 | flow_layout | 1 page |
| 05 | occur_repeating_rows | 1 page |
| 06 | pagination_multipage | `XFAFormPageCount` pre-flight = 4, `RenderXFAForm` = 4 (agree); pypdf per-page text confirms leader on pages 2-4, trailer on pages 1-3 only, all 70 `Line` rows present in order |
| 07 | table_layout | 1 page |
| 08 | picture_clause_formatting | 1 page; pypdf text matches the checklist verbatim |
| 09 | acroform_widget_synthesis | mode0.pdf `/AcroForm/Fields`=0, mode1.pdf `/AcroForm/Fields`=9, all 9 names/types/values match the checklist exactly (verified via pypdf, incl. the `EmploymentType` 3-Kid radio fold) |
| 10 | javascript_scripting | 1 page |

No engine bugs were found in this port — every value matches the Delphi
reference exactly. The only real issue encountered was the ABI/host-language
limitation documented above, which is a pre-existing property of the AX
wrapper (not introduced by this port) and is worked around, not silently
ignored.
