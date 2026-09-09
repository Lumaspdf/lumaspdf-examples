VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Fn12Evt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' Custom expression function GREET(name) -> 'Hello, <name>!' via the AX function
' event. Registered BEFORE open/render so the compiler resolves GREET.

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1

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

Private Function BuildXml() As String
    Dim s As String
    s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    s = s & "<report name=""CustomFn"" tagLangVersion=""1"">" & vbLf
    s = s & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    s = s & " <bands>" & vbLf
    s = s & "  <band kind=""reportheader"" name=""rh"" height=""24"">" & vbLf
    s = s & "   <text name=""g1"" x=""0"" y=""0""  w=""180"" h=""8"" fontSize=""16"">{{expr: GREET('World') }}</text>" & vbLf
    s = s & "   <text name=""g2"" x=""0"" y=""10"" w=""180"" h=""8"" fontSize=""12"">{{expr: GREET('LumasReport') }}</text>" & vbLf
    s = s & "  </band>" & vbLf
    s = s & " </bands>" & vbLf
    s = s & "</report>" & vbLf
    BuildXml = s
End Function

Public Sub Run()
    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, OutTxt As String

    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = Pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.LastErrorMessage: Exit Sub

    If Not Pdf.RptRegisterFunctionEvent(mEng, "GREET", 1) Then
        Debug.Print "RptRegisterFunctionEvent failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    End If
    Debug.Print "registered custom function GREET/1"

    Lrpt = App.Path & "\12_custom_function.lrpt"
    OutPdf = App.Path & "\12_custom_function.pdf"
    OutTxt = App.Path & "\12_custom_function.txt"
    WriteText Lrpt, BuildXml()

    Job = Pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    If Pdf.RptRender(Job) = 0 Then Debug.Print "render failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    If Pdf.RptExport(Job, 0, OutPdf) = 0 Then Debug.Print "export PDF failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    If Pdf.RptExport(Job, RPT_EXP_TEXT, OutTxt) = 0 Then Debug.Print "export TEXT failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "wrote " & OutPdf
    Debug.Print "OK"
    Pdf.RptCloseReport Job
Cleanup:
    Pdf.RptDeleteEngine mEng
End Sub

' GREET(name) -> 'Hello, <name>!'
Private Sub Pdf_OnRptFunction(ByVal FuncName As String, ByVal Args As Variant, ResultV As Variant, ResultCode As Long)
    Dim a As Variant
    If IsArray(Args) Then
        If UBound(Args) >= 0 Then a = Args(0) Else a = ""
    Else
        a = Args
    End If
    If UCase$(FuncName) = "GREET" Then
        ResultV = "Hello, " & a & "!"
    Else
        ResultV = ""
    End If
    ResultCode = 0
End Sub
