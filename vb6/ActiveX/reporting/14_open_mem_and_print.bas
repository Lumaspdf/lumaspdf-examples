Attribute VB_Name = "mod14_open_mem_and_print"
Option Explicit
' ===========================================================================
'  ActiveX/COM mirror of examples\Vb6\reporting\14_open_mem_and_print.bas.
'  Same feature, genuinely working (not emulated with a temp file): opening a
'  report straight from an in-memory buffer via RptOpenReportMem, then a
'  headless print via RptPrint.
'
'  RptOpenReportMem's .ridl signature is
'      RptOpenReportMem([in] long Engine, [in] __int64 Buf, [in] long Len)
'  -- Buf is a raw memory ADDRESS, not a marshalled byte array. That is only
'  meaningful because the LumasPdf ActiveX component is an IN-PROCESS COM
'  server (InprocServer32, apartment-threaded): it runs inside this very VB6
'  process's address space, so a pointer VB6 obtains with VarPtr() on one of
'  its OWN byte arrays is a perfectly valid address for the engine to read
'  directly -- no cross-process marshalling ever happens. (This would NOT
'  work against an out-of-process/EXE server.) VB6 has no native Int64, but
'  that is not a problem here: the call is late-bound through IDispatch, so
'  VB6 hands over the address as a plain Long inside a Variant and the
'  server's own `safecall` dispatch layer performs the ordinary OLE Variant
'  coercion up to Int64 before using it as a pointer (see
'  TLumasPDFAuto.RptOpenReportMem in Lumas.Pdf.AX.Impl.pas).
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Const RPT_EXP_PDF As Long = 0

Private pdf As Object       ' LumasPdf.PDF (late-bound)
Private mEng As Long

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

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""InMem"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
    s = s & "   <text name=""title"" x=""0"" y=""0""  w=""180"" h=""12"" fontSize=""20"" hAlign=""center"">In-memory report</text>" & vbLf
    s = s & "   <text name=""sub""   x=""0"" y=""14"" w=""180"" h=""6""  fontSize=""10"" hAlign=""center"">Opened via RptOpenReportMem -- a VarPtr() address into a VB6 byte array.</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""pageheader"" name=""ph"" height=""8"">" & vbLf
    s = s & "   <text name=""ph1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""9"" hAlign=""left"">LumasReport example 14 (ActiveX)</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""detail"" name=""det"" height=""8"">" & vbLf
    s = s & "   <text name=""d1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""11"" hAlign=""left"">This band was rendered straight from the in-process memory buffer.</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & "  <band kind=""pagefooter"" name=""pf"" height=""8"">" & vbLf
    s = s & "   <text name=""pf1"" x=""0"" y=""0"" w=""180"" h=""6"" fontSize=""8"" hAlign=""right"">page {{var:PageNo}} of {{var:TotalPages}}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

' Open a report directly from an in-memory buffer -- no temp .lrpt file.
Private Function OpenFromMemory(ByVal Xml As String) As Long
    Dim buf() As Byte
    Dim p As Long
    buf = StrConv(Xml, vbFromUnicode)      ' ASCII/UTF-8-compatible byte buffer
    p = VarPtr(buf(0))
    OpenFromMemory = pdf.RptOpenReportMem(mEng, CLng(p), UBound(buf) - LBound(buf) + 1)
    ' buf must outlive this call, which it does (still in scope) -- the engine
    ' reads/copies it synchronously during RptOpenReportMem itself.
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim Job As Long, Pages As Long
    Dim Dir_ As String, OutPdf As String, OutPrint As String

    If Not BootEngine() Then Exit Sub

    Dir_ = App.Path & "\"
    OutPdf = Dir_ & "14_open_mem.pdf"
    OutPrint = Dir_ & "14_printed.pdf"

    Debug.Print "== Open from memory (RptOpenReportMem, no temp file) =="
    Job = OpenFromMemory(BuildXml())
    If Job = 0 Then Debug.Print "  open failed: ": DumpRptError: GoTo Cleanup

    If pdf.RptRender(Job) = 0 Then Debug.Print "  render failed: ": DumpRptError: GoTo CloseJob
    Pages = pdf.RptGetPageCount(Job)
    Debug.Print "  rendered " & Pages & " page(s)"

    Debug.Print "== Export =="
    If pdf.RptExport(Job, RPT_EXP_PDF, OutPdf) = 0 Then Debug.Print "  export failed: ": DumpRptError: GoTo CloseJob
    Debug.Print "  wrote " & OutPdf

    Debug.Print "== Headless print =="
    If pdf.RptPrint(Job, "Microsoft Print to PDF", OutPrint) <> 0 Then
        Debug.Print "  ""Microsoft Print to PDF"" -> " & OutPrint
    Else
        Debug.Print "  ""Microsoft Print to PDF"" not available / print failed (non-fatal): " & pdf.LastErrorMessage
    End If
CloseJob:
    pdf.RptCloseReport Job

    Debug.Print "== Verify =="
    If (Dir(OutPdf) <> "") And (Pages >= 1) Then
        Debug.Print "  OK: " & OutPdf & " exists, report has " & Pages & " page(s)"
    Else
        Debug.Print "  VERIFY FAILED: in-memory PDF missing or zero pages"
    End If
Cleanup:
    pdf.RptDeleteEngine mEng
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "14_open_mem_and_print (ActiveX)"
End Sub
