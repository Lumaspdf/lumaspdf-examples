Attribute VB_Name = "mod08_custom_provider"
Option Explicit
' ============================================================================
'  ActiveX zero-wrapper conversion. RptRegisterProvider needs a native vtable of
'  C callback pointers, which the AX server bridges through COM events:
'  RptRegisterProviderEvent installs native trampolines that fire back as
'  OnRptOpen/OnRptGetSchema/OnRptFetch/OnRptGetVal/OnRptClose. VB6 sinks those
'  with WithEvents (class module Prov08Evt) -- driven from here.
' ============================================================================

Public Sub Main()
    Dim e As New Prov08Evt
    e.Run
End Sub
