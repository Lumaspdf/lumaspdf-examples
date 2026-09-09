Attribute VB_Name = "mod13_plugin"
Option Explicit
' ============================================================================
'  ActiveX zero-wrapper conversion. The custom expression function PlugDouble(x)
'  = x*2 is registered plugin-free through the AX function event
'  (RptRegisterFunctionEvent + OnRptFunction), sunk via WithEvents (Fn13Evt).
'
'  NOTE: the flat original also registered a custom EXPORTER (target 100) via
'  rptRegisterExporter, which takes a raw native function pointer (typelib
'  Int64 Fn) that VB6 early-binding cannot pass -- and the AX server exposes no
'  exporter EVENT. So the custom-exporter half (13_custom.out) is not
'  expressible from zero-wrapper VB6; the function half (13_plugin.pdf/.txt) is
'  ported in full.
' ============================================================================

Public Sub Main()
    Dim e As New Fn13Evt
    e.Run
End Sub
