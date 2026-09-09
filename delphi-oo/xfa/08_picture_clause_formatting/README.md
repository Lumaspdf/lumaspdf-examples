# 08 — Picture-Clause Formatting (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\08_picture_clause_formatting`.
Same fixture, same real `LumasPdf.dll`, same render pipeline — the only
difference is that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class, including
`pdf.SetXFAScriptEnabled`) instead of the flat `pdfXxx(Handle, ...)`
functions the original uses.

Demonstrates the XFA dynamic engine's `<format><picture>` formatter (plan
sec 6.4, `Lumas.Pdf.Xfa.Picture.pas`): real `num{}`/`date{}`/`text{}`
picture patterns applied both to plain **bound** data values and to a
value produced by a FormCalc **`<calculate>`** script (`GrandTotalField`),
proving the calculate-then-format pipeline order.

## Packet files are pre-split

`08_picture_clause_formatting.template.xml` / `.datasets.xml` are raw bytes
of the original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 08_picture_clause_formatting.dpr
08_picture_clause_formatting.exe
```

Writes `08_picture_clause_formatting.pdf` alongside the exe.

## Verified output (pypdf `extract_text()`, this session)

Ran the built exe for real, then extracted page 1 text with `pypdf` —
**byte-for-byte identical** to the flat original's own verified checklist:

```
Purchase Receipt -- Picture-Clause Formatting
Customer: Acme Corp
Unit Price: 1,875.50
Discount: ($125.00)
Date: July 24, 2026
Phone: 555-123-4567
845.25 620.00 410.25
Grand Total: 1,875.50
```

`GrandTotalField` has no literal `<value>` and a bound fallback of `0.00`
— its rendered `1,875.50` can only come from the `<calculate>` script
(`Item1Price + Item2Price + Item3Price`) actually running and the picture
formatter (`num{zzz,zz9.99}`) then being applied to that result. It lands
on the exact same displayed number as `UnitPriceField` (`1,875.50`) despite
one being a plain bound value and the other a FormCalc sum.
