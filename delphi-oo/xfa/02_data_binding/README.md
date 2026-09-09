# 02 — Data Binding (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\02_data_binding`. Same fixture,
same real `LumasPdf.dll`, same render pipeline — the only difference is
that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class:
`TPDF.Create`/`pdf.CreateNewPDFA`/`pdf.CreateXFAStreamA`/
`pdf.RenderXFAForm`/`pdf.CloseFile`/`pdf.Free`) instead of the flat
`pdfXxx(Handle, ...)` functions the original uses.

Demonstrates the three data-binding modes an XFA form mixes in practice
(plan `XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec 6), all against **one**
realistic, genuinely nested `<xfa:datasets>` packet: implicit by-name
binding (containment-aware, two nesting levels), explicit
`<bind match="dataRef" ref="$data...."/>` against a SOM path 3/4 levels
deep, and `<bind match="none"/>` — a pure literal unaffected by a
same-named trap node in the dataset.

## Packet files are pre-split

`02_data_binding.template.xml` / `.datasets.xml` are raw bytes of the
original `.xdp`'s `<template>`/`<xfa:datasets>` subtrees (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`), copied in from the flat
example's own folder — read directly as bytes, no XML parsing needed.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 02_data_binding.dpr
02_data_binding.exe
```

Writes `02_data_binding.render.pdf` alongside the exe.

## Verified output (pdypdf `extract_text()`, this session)

Ran the built exe for real, then extracted page 1 text with `pypdf`
independently of the engine's own test suite — **all eight values match
exactly**, identical to the flat original's own verified checklist:

| Field | Binding kind | Resolved value seen in the PDF |
|---|---|---|
| Customer Name | implicit | `Acme Robotics LLC` |
| Account ID | implicit | `ACCT-88213` |
| Street | implicit (nested subform) | `500 Innovation Way` |
| State | implicit (nested subform) | `IL` |
| Zip | implicit (nested subform) | `62704` |
| Shipping City (SOM 3 deep) | explicit `dataRef` | `Springfield` |
| Primary Contact Email (SOM 4 deep) | explicit `dataRef` | `ap@acmerobotics.example` |
| Status (literal, match=none) | `match="none"` | `Active - Verified` (NOT `PENDING_CLOSURE`) |

The implicit fields found their by-name data siblings at both nesting
levels, both explicit fields resolved their full SOM paths correctly, and
the `match="none"` field's literal was untouched by the same-named trap
node — same result through the OO call surface as through the flat one.
