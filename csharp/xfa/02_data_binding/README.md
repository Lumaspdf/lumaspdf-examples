# 02 - Data Binding (C#)

C# port of `examples\delphi\xfa\02_data_binding`. Demonstrates the three
data-binding modes an XFA form mixes in practice, all against **one**
realistic, genuinely nested `<xfa:datasets>` packet.

## What the form demonstrates

**1. Implicit binding (by-name, no `<bind>` element at all).**
`CustomerName` and `AccountId` fields sit inside `<subform name="Customer">`,
resolving by name against the datasets root; a nested `<subform
name="Address">` repeats the pattern one level deeper for `Street`/`State`/
`Zip`.

**2. Explicit `<bind match="dataRef" ref="$data...."/>` against a genuinely
nested SOM path** -- `ShippingCityField` (`$data.Customer.Address.City`, 3
levels deep) and `PrimaryContactEmailField`
(`$data.Customer.Billing.Contact.Email`, 4 levels deep).

**3. `<bind match="none"/>` -- pure literal, unaffected by data.**
`AccountStatusField`'s value is the template literal `"Active - Verified"`,
proven not to be overridden even though the datasets packet also contains a
same-named, decoy `<AccountStatusField>PENDING_CLOSURE</AccountStatusField>`.

## Files

- `02_data_binding.cs` -- console driver.
- `02_data_binding.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\02_data_binding 02_data_binding.cs
.\02_data_binding.exe
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

`pdfRenderXFAForm` should return `1`.
