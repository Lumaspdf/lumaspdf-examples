# 06 — Multi-Page Pagination (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\06_pagination_multipage`. Same
fixture, same real `LumasPdf.dll`, same render pipeline, same
`CheckPageCount=4` pre-flight assertion as the flat original — the only
difference is that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class, including
`pdf.XFAFormPageCount`) instead of the flat `pdfXxx(Handle, ...)` functions.

Demonstrates full multi-page pagination (plan sec 5.4): `pageSet`/
`pageArea`/`contentArea`, forced overflow of a 70-row repeating template
across several pages, and leader/trailer "continued" banner subforms via
`<overflow leader=... trailer=...>`. A 400pt-tall `contentArea`, 20pt rows,
20pt leader/trailer forces exactly **4** pages (19+18+18+15=70 rows).

## Packet files are pre-split

`06_pagination_multipage.template.xml` / `.datasets.xml` are raw bytes of
the original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 06_pagination_multipage.dpr
06_pagination_multipage.exe
```

Writes `06_pagination_multipage.pdf` alongside the exe. The driver calls
`pdf.XFAFormPageCount` (the OO equivalent of `pdfXFAFormPageCount`) BEFORE
`pdf.RenderXFAForm` and asserts the two agree with the hand-derived
`CheckPageCount=4`.

## Verified (this session)

Run output:
```
pdf.XFAFormPageCount (pre-flight, before any AppendPage) -> 4
pdf.RenderXFAForm -> 4
RESULT|06_pagination_multipage=4
```

Independently cross-checked via `pypdf`: `len(reader.pages) == 4`, and each
page's extracted text confirms the leader/trailer pattern:

| Page | Leader ("continued from previous page") | Trailer ("continued on next page") |
|---|---|---|
| 0 | no | yes |
| 1 | yes | yes |
| 2 | yes | yes |
| 3 (last) | yes | **no** |

Page 3's last line is `Firmware Update Package (Row 70) 5 49.95` — the
70th and final line item, confirming no rows were dropped or duplicated
across the 4-page split. Identical result to the flat original.
