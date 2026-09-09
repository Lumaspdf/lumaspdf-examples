Attribute VB_Name = "mod12_custom_function"
Option Explicit
' ============================================================================
'  ActiveX zero-wrapper conversion. RptRegisterFunction needs a native C
'  function pointer; the AX server bridges it through a COM event:
'  RptRegisterFunctionEvent installs a native trampoline that fires back as
'  OnRptFunction. VB6 sinks it with WithEvents (class Fn12Evt). The handler
'  computes GREET(name) -> 'Hello, <name>!' and returns it via ResultV.
' ============================================================================

Public Sub Main()
    Dim e As New Fn12Evt
    e.Run
End Sub
