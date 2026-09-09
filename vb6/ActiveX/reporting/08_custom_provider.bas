Attribute VB_Name = "mod08_custom_provider"
Option Explicit
' ============================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\08_custom_provider.bas.
'  RptRegisterProvider (flat DLL) needs a native vtable of C callback
'  pointers, which has no representation across a COM automation boundary.
'  The ActiveX server instead bridges this through COM events:
'  RptRegisterProviderEvent installs native trampolines that fire back as
'  OnRptOpen/OnRptGetSchema/OnRptFetch/OnRptGetVal/OnRptClose on the
'  LumasPDF object's default source interface. VB6 sinks those with
'  WithEvents (class module Prov08Evt, early-bound to the LumasPdfAX type
'  library) -- driven from here. See Prov08Evt.cls for the full note.
' ============================================================================

Public Sub Main()
    Dim e As New Prov08Evt
    e.Run
End Sub
