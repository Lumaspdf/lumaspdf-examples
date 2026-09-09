# 04 - Flow Layout (C#)

C# port of `examples\delphi\xfa\04_flow_layout`. Demonstrates **flow layout**
(`layout="tb"` / `layout="lr-tb"`): containers whose children carry no fixed
position and are placed automatically by the layout engine.

`04_flow_layout.xdp` is a one-page "Employment Application" with two sibling
flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with `w`/`h` but no `y`. Stacked vertically
  with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each tag
  its own `<field>` with `w`/`h` but no `x`. Packed left-to-right, wrapping
  when the next tag would overflow the content width.

## Files

- `04_flow_layout.cs` -- console driver.
- `04_flow_layout.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\04_flow_layout 04_flow_layout.cs
.\04_flow_layout.exe
```

Writes `04_flow_layout.pdf` alongside the exe.

## Expected checklist

### `TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `w=540 h=24`, gap=0)

| Node | expected x,y |
|---|---|
| Clause1 | 36, 92 |
| Clause2 | 36, 116 |
| Clause3 | 36, 140 |
| Clause4 | 36, 164 |
| Clause5 | 36, 188 |
| Clause6 | 36, 212 |

### `SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each child `w=110 h=20`)

| Node | expected x,y | line |
|---|---|---|
| Skill1 (Delphi) | 36, 270 | 1 |
| Skill2 (C++17) | 146, 270 | 1 |
| Skill3 (Python) | 256, 270 | 1 |
| Skill4 (SQL Server) | 366, 270 | 1 |
| Skill5 (REST APIs) | 36, 290 | 2 |
| Skill6 (Docker) | 146, 290 | 2 |
| Skill7 (Git) | 256, 290 | 2 |
| Skill8 (Linux) | 366, 290 | 2 |
| Skill9 (AWS Cloud) | 36, 310 | 3 |

3 lines total (4 + 4 + 1 tags). `pdfRenderXFAForm` should return `1`.
