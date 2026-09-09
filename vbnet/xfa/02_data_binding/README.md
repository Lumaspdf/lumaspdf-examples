# 02 - Data Binding (VB.NET)

VB.NET port of `examples\delphi\xfa\02_data_binding`. Demonstrates the three
data-binding modes an XFA form mixes in practice, all against **one**
realistic, genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding (by-name, no `<bind>` element at all).** `CustomerName`
   and `AccountId` resolve against `<Customer>`; a nested `Address` subform
   resolves `Street`/`State`/`Zip` one level deeper.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a genuinely
   nested SOM path: `ShippingCityField` -> `$data.Customer.Address.City` (3
   levels deep), `PrimaryContactEmailField` ->
   `$data.Customer.Billing.Contact.Email` (4 levels deep).
3. **`<bind match="none"/>`** -- pure literal (`"Active - Verified"`),
   unaffected by a same-named trap node (`AccountStatusField`=`PENDING_CLOSURE`)
   in the datasets packet.

## Files

- `02_data_binding.vb` -- console driver. Reads the two pre-split packet
  files directly and renders through `LumasPdf.VB.dll`'s `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm ->
  pdfCloseFile` pipeline.
- `02_data_binding.template.xml` / `.datasets.xml` -- packet bytes, copied
  from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:02_data_binding.exe 02_data_binding.vb
02_data_binding.exe
```

Writes `02_data_binding.render.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, extracted via `pypdf`)

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

All eight values confirmed to match exactly against the real rendered PDF
(`pdfRenderXFAForm` returns `1`, `RESULT|02_data_binding=1`), re-verified in
this VB.NET port with `pypdf`'s `extract_text()` -- identical to the Delphi
original's checklist.
