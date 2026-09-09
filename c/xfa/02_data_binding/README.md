# XFA Flavor Tour (C) -- 02: Data Binding

C port of `examples\delphi\xfa\02_data_binding`. Demonstrates the three
data-binding modes an XFA form mixes in practice, all against **one**
realistic, genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding** (by-name, no `<bind>` element) -- `CustomerName`/
   `AccountId` resolve against `<Customer>`, and a nested `Address` subform
   resolves `Street`/`State`/`Zip` one level deeper against
   `<Customer><Address>`.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a genuinely
   nested SOM path -- `ShippingCityField` (3 levels deep) and
   `PrimaryContactEmailField` (4 levels deep).
3. **`<bind match="none"/>`** -- a pure literal (`AccountStatusField`),
   unaffected by a same-named trap node in the datasets packet.

## Files

- `02_data_binding.c` -- console driver.
- `02_data_binding.template.xml` / `02_data_binding.datasets.xml` -- the
  pre-split `<template>`/`<xfa:datasets>` packet bytes (raw bytes, no XML
  parsing needed in this driver).
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## Pipeline

Same as every example in this tour: `pdfNewPDF` -> `pdfCreateNewPDFA` ->
`pdfCreateXFAStreamA('template',...)` -> `pdfCreateXFAStreamA('datasets',...)`
-> `pdfRenderXFAForm` -> `pdfCloseFile`.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 02_data_binding.c /Fe:02_data_binding.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
02_data_binding.exe
```

Writes `02_data_binding.render.pdf` alongside the exe.

## Expected checklist

| Field | Binding kind | Resolved value |
|---|---|---|
| Customer Name | implicit | `Acme Robotics LLC` |
| Account ID | implicit | `ACCT-88213` |
| Street | implicit (nested subform) | `500 Innovation Way` |
| State | implicit (nested subform) | `IL` |
| Zip | implicit (nested subform) | `62704` |
| Shipping City (SOM 3 deep) | explicit `dataRef` | `Springfield` |
| Primary Contact Email (SOM 4 deep) | explicit `dataRef` | `ap@acmerobotics.example` |
| Status (literal, match=none) | `match="none"` | `Active - Verified` (NOT `PENDING_CLOSURE`) |

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction on the rendered PDF -- all 8 values
above appear exactly as expected, including the `match="none"` field
correctly ignoring the same-named `PENDING_CLOSURE` trap node.
