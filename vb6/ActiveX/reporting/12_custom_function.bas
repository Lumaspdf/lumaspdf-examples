Attribute VB_Name = "mod12_custom_function"
Option Explicit
' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\12_custom_function.bas.
'  Original feature: a custom expression function GREET(name) -> 'Hello,
'  <name>!' registered with the flat DLL's rptRegisterFunctionA, which takes a
'  raw native callback pointer (AddressOf) + a UserData pointer -- fine for a
'  straight Declare call, but not something an Automation/IDispatch boundary
'  can carry (the .ridl types the equivalent parameters as opaque __int64
'  Fn/UserData -- nowhere for VB6 to marshal a callable target).
'
'  INVESTIGATED: the AX server does expose a genuine bridge for this --
'  RptRegisterFunctionEvent installs a native trampoline that fires the
'  OnRptFunction event on the component's single shared default source
'  interface (_ILumasPDFEvents) whenever GREET(...) is evaluated. VBScript can
'  sink this (WScript.CreateObject(..., "prefix_") + a Sub prefix_OnRptFunction)
'  because VBScript resolves event handlers by NAME at runtime through
'  IDispatch, one method at a time.
'
'  Classic VB6 cannot use that bridge, and this was verified empirically, not
'  assumed: VB6's WithEvents requires the compiler to fully resolve the ENTIRE
'  shared event interface at compile time (it has to build sink stubs/DISPIDs
'  for every member, not just the one handler you write), and a minimal test
'  project here --
'      Public WithEvents Pdf As LumasPdfAX.LumasPDF     ' + nothing else
'  -- already fails with "TestEvt.cls could not be loaded" the moment VB6
'  tries to compile the class, even with ZERO event handlers implemented.
'  (A plain `Dim x As New LumasPdfAX.LumasPDF`, with no WithEvents, compiles
'  and runs fine -- so the huge 1388-method ILumasPDF interface itself is not
'  the problem.) The likely cause: _ILumasPDFEvents is one interface shared by
'  ALL of the component's events, and at least one of the OTHER events on it
'  (e.g. OnEnumDocFont's `[in] __int64 PDFFont` parameter) uses a raw 64-bit
'  integer, a type classic VB6 has no native representation for -- and WithEvents
'  can't partially bind to only the members it understands.
'
'  Net result: RptRegisterFunctionEvent + OnRptFunction is NOT reachable from
'  classic VB6 (unlike VBScript/.NET/C++), so this example demonstrates the
'  reachable subset instead -- the SAME "Hello, <name>!" output, built from
'  ONLY the engine's built-in, fully-supported features: RptSetParamStr to
'  hand values in from VB6, and the report's native {{var:...}} interpolation
'  (which freely mixes with surrounding literal text, e.g. "Hello, {{var:Name}}!")
'  to do the string composition -- no custom function, no event, no plugin.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Const RPT_EXP_PDF As Long = 0
Const RPT_EXP_TEXT As Long = 5

Private pdf As Object       ' LumasPdf.PDF (late-bound)
Private mEng As Long

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer, b() As Byte
    f = FreeFile
    On Error Resume Next
    Kill Path
    On Error GoTo 0
    b = StrConv(Content, vbFromUnicode)
    Open Path For Binary Access Write As #f
    Put #f, 1, b
    Close #f
End Sub

Private Sub DumpRptError()
    Debug.Print "  ! " & pdf.LastErrorMessage
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set pdf = CreateObject("LumasPdf.PDF")
    ' pdf.RaiseExceptions = True
    pdf.SetLicenseKey PDF_DEMO_KEY
    pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "RptCreateEngine failed: " & pdf.LastErrorMessage: Exit Function
    BootEngine = True
End Function

' GREET(name) = 'Hello, ' & name & '!' reproduced with a declared <param> plus
' the tag language's own text interpolation -- no custom function needed.
Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""CustomFn"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <params>" & vbLf
    s = s & "  <param name=""Name1"" default=""(unset)""/>" & vbLf
    s = s & "  <param name=""Name2"" default=""(unset)""/>" & vbLf
    s = s & " </params>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""30"">" & vbLf
    s = s & "   <text name=""g1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">Hello, {{var:Name1}}!</text>" & vbLf
    s = s & "   <text name=""g2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">Hello, {{var:Name2}}!</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, OutTxt As String

    If Not BootEngine() Then Exit Sub

    Lrpt = App.Path & "\12_custom_function.lrpt"
    OutPdf = App.Path & "\12_custom_function.pdf"
    OutTxt = App.Path & "\12_custom_function.txt"
    WriteText Lrpt, BuildXml()

    Job = pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed": DumpRptError: GoTo Cleanup

    ' Values driven in from VB6 at JOB level -- the reachable equivalent of
    ' GREET('World') / GREET('LumasReport').
    pdf.RptSetParamStr Job, "Name1", "World"
    pdf.RptSetParamStr Job, "Name2", "LumasReport"

    If pdf.RptRender(Job) = 0 Then Debug.Print "render failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    If pdf.RptExport(Job, RPT_EXP_PDF, OutPdf) = 0 Then Debug.Print "export PDF failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    If pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "export TEXT failed": DumpRptError: pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "wrote " & OutPdf & "  +  " & OutTxt
    Debug.Print "OK (custom-function/event bridge NOT reachable from classic VB6 -- see header comment; reproduced via RptSetParamStr + {{var:}} instead)"
    pdf.RptCloseReport Job
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "12_custom_function (ActiveX)"
End Sub
