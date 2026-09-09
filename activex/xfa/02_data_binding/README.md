# 02 — Data Binding (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\02_data_binding`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates the three data-binding modes an XFA form mixes in practice,
all against one genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding** (by-name, no `<bind>`) — containment-aware:
   `CustomerName`/`AccountId` resolve against `<Customer>`, and
   `Street`/`State`/`Zip` (nested one level deeper) resolve against
   `<Customer><Address>`.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a
   genuinely nested SOM path: `ShippingCityField` → `$data.Customer.Address.City`
   (3 levels deep), `PrimaryContactEmailField` →
   `$data.Customer.Billing.Contact.Email` (4 levels deep).
3. **`<bind match="none"/>`** — pure literal. The datasets packet also
   contains a same-named trap node (`<AccountStatusField>PENDING_CLOSURE</AccountStatusField>`)
   that an implicit lookup would otherwise match, proving `match="none"`
   really suppresses binding.

## Run

```
powershell -File 02_data_binding.ps1
```

## Verified output (pypdf text extraction of page 1)

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

All eight values confirmed via `pypdf` against the actual rendered
`output.pdf` — exact match with the Delphi reference's own checklist.
