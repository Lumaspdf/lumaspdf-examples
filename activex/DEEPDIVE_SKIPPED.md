# ActiveX skipped/degraded examples — deep-dive investigation (2026-07-20)

The first pass reported ~13 ActiveX examples as "impossible from VBScript". A deep dive into our OWN
COM wrapper (`wrappers\activex\*.pas`) shows most of that was **under-use of the wrapper, not a real wall**.
Two enabling mechanisms were found/added and PROVEN working from `cscript`:

## Mechanism 1 — COM connection-point EVENTS (already existed; agents didn't use them)
`LumasPdfAX` fires a `_ILumasPDFEvents` dispinterface with: `OnError, OnPageBreak, OnInitProgress,
OnProgress, OnEnumFont, OnEnumDocFont, OnEnumFontEx, OnFontNotFound, OnReplaceICCProfile`.
VBScript sinks them with `Set pdf = WScript.CreateObject("LumasPdf.PDF","PDF_")` + `Sub PDF_OnXxx(...)`.
**PROVEN:** a `PDF_OnError` handler captured the engine's "Font not found" during `SetFontA`.
So the callback the engine needs is delivered as a COM event — no function pointer required.

## Mechanism 2 — marshaller Variant-array COERCION (implemented this session)
`Lumas.Pdf.AX.Marshal.pas` used to REJECT `VT_ARRAY|VT_VARIANT` (E_INVALIDARG) — the only array kind a
script host can build. Added `CoerceVarArrayToBuf` + `vlArrayConv`: a VBScript `Array(...)` for a numeric
buffer param is now coerced element-by-element into a packed native buffer of the target scalar type
(freed by `Done`). AX rebuilt (x64+x32) + re-registered. **PROVEN:** `CreateOCMD(0, Array(oc1,oc2), 2)`
returned a valid OCMD handle from VBScript. Same path serves any `TFltPoint[]`/`Single[]`/`Int[]` param.

## Updated status of the ~13

| Example | Old verdict | Deep-dive verdict | Mechanism |
|---|---|---|---|
| layers/layers, layers/layer_tree (CreateOCMD) | degraded (AddObjectToLayer) | **FIXABLE — proper OCMD** | Coercion (proven) |
| annotations/quad_points (TFltPoint[]) | skipped | **FIXABLE** | Coercion |
| text_formatting (page-break → 1 col) | degraded | **FIXABLE — real multi-column** | OnPageBreak event |
| signed_pdfa (font/ICC callbacks) | degraded | **FIXABLE** | OnFontNotFound/OnReplaceICCProfile events |
| zugferd/conv_to_zugferd (font/ICC) | degraded | **FIXABLE** | same events |
| complex_text/alternate_fonts (SetAltFonts) | skipped | **FIXABLE w/ small AX add** | needs a string-pointer-array coercion (`vlStrPtrArray`) |
| annotations/measure_lines (TLineAnnotParms) | skipped | **needs AX helper** | scalar-arg `SetLineAnnotParmsEx(...)` OR field-array→record coercion |
| optimize (TPDFOptimizeParms) | degraded (skips Optimize) | **needs AX helper** | scalar-arg optimize helper OR field-array→record |
| transparency/alpha_transparency, softmask (TPDFExtGState) | skipped | **needs AX helper** | scalar setters (FillAlpha/StrokeAlpha/SoftMask) that build the ExtGState |
| content_parser/text_search, text_coordinates, text_extraction2, image_extraction (ParseContent) | skipped | **HARD** | needs a new ContentParser COM object firing per-op events (TPDFParseInterface = 63-fn vtable) |
| reporting/08 custom provider (RptRegisterProvider VTable) | skipped | **HARD** | needs a COM provider-object interface |
| reporting/12 custom function (RptRegisterFunction fn ptr) | skipped | **medium** | could map to an OnRptFunction event |

### Summary
- **6 examples immediately fixable** with the two proven mechanisms (coercion + events), no further engine work — just rewrite the `.vbs`.
- **~4 need small, well-scoped AX additions** (a string-pointer-array coercion; 2–3 scalar helper methods that build a record blob internally).
- **~5-6 are genuinely hard** (ParseContent's 63-function vtable + the rpt provider vtable) — they need new COM callback objects, i.e. real AX-layer feature work, not a VBScript trick.

So "13 impossible" → **~6 fixable now, ~4 fixable with minor AX work, ~5-6 truly need a callback-object redesign.**
The one hard limit is genuine: VBScript cannot supply a native stdcall function-pointer vtable, and the two
big offenders (ParseContent, rpt provider) are exactly that shape until the AX layer wraps them as COM objects/events.
