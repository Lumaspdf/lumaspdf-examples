# XFA Flavor Tour -- 02: Data Binding

Example 2 of 10 in the LumasPDF XFA "flavor tour". Demonstrates the three
data-binding modes an XFA form mixes in practice (plan
`XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec 6), all against **one** realistic,
genuinely nested `<xfa:datasets>` packet.

## Files

- `02_data_binding.xdp` -- the form: a `<template>` packet and an
  `<xfa:datasets>` packet bundled under one `<xdp:xdp>` root.
- `02_data_binding.dpr` -- console driver, mirrors
  `cpp\tools\xfa_render_test.dpr` exactly (same DLL export sequence: `pdfNewPDF`
  -> `pdfCreateNewPDFA` -> `pdfCreateXFAStreamA` x2 -> `pdfRenderXFAForm` ->
  `pdfCloseFile`). Parses the `.xdp` with `Lumas.Pdf.Xml`, splits out the
  `<template>`/`<datasets>` subtrees, and hands each to the engine as its own
  packet buffer.
- `build_02_data_binding.bat` -- compiles with `dcc64`, copies the already-built
  `LumasPdf.dll` next to the exe, and runs it.

## What the form demonstrates

**1. Implicit binding (by-name, no `<bind>` element at all).**
`CustomerName` and `AccountId` fields sit inside `<subform name="Customer">`,
which itself has no `<bind>` -- so it defaults to `match="once"` and resolves
by name against the current data context. Because `form1` is the template's
root subform, that context starts at the datasets `<data>` root itself, so
`Customer` resolves to the top-level `<Customer>` node, and its two child
fields then resolve by name against *that* node. A further nested
`<subform name="Address">` (also no `<bind>`) repeats the same pattern one
level deeper, so `Street`/`State`/`Zip` resolve against `<Customer><Address>`.
This proves implicit binding is containment-aware -- each container resolves
its own data context for its children -- not a single flat name scan.

**2. Explicit `<bind match="dataRef" ref="$data...."/>` against a genuinely
nested SOM path.** Both fields below live directly under the root `form1`,
*outside* the `Customer`/`Address` subforms, so containment gives them
nothing -- only the ref's own dotted path can resolve them:
- `ShippingCityField` -> `$data.Customer.Address.City` (3 levels deep)
- `PrimaryContactEmailField` -> `$data.Customer.Billing.Contact.Email`
  (4 levels deep)

**3. `<bind match="none"/>` -- pure literal, unaffected by data.**
`AccountStatusField`'s value is the template literal `"Active - Verified"`.
As a genuine test (not just an absence of data), the datasets packet also
contains a *same-named* top-level `<AccountStatusField>PENDING_CLOSURE</AccountStatusField>`
node that an implicit lookup would otherwise have matched -- proving
`match="none"` really suppresses binding rather than merely never colliding
with anything.

## How to run

```
build_02_data_binding.bat
```

This does **not** rebuild `LumasPdf.dll` -- it links `wrappers\delphi\LumasPdf.pas`
against the engine DLL exactly as already built, copying the current
`<repo root>\LumasPdf.dll` next to the exe (standard DLL-search-order
convention every example in this project follows), then runs the driver,
producing `02_data_binding.render.pdf`.

## Verified output (rendered PDF page 1 content stream)

Extracted via `pypdf` from the actual rendered PDF -- each field's caption and
resolved value appear as adjacent `Tj` text-showing operators:

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

All eight values match expectations exactly: the implicit fields found their
by-name data siblings at both nesting levels, both explicit fields resolved
their full SOM paths correctly (including the 4-level-deep email), and the
`match="none"` field's literal was untouched by the same-named trap node in
the datasets packet.
