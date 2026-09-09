VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Prov08Evt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' Custom data provider (4 rows x 5 typed columns) delivered to the engine via
' the AX provider events. Schema is an array of Array(FieldName, FieldKind).

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Const vkNull As Long = 0
Private Const vkBool As Long = 1
Private Const vkInt As Long = 2
Private Const vkFloat As Long = 3
Private Const vkDate As Long = 4
Private Const vkStr As Long = 5

Public WithEvents Pdf As CPDF
Attribute Pdf.VB_VarHelpID = -1

Private mEng As Long
Private gId(0 To 3) As Long
Private gPrice(0 To 3) As Double
Private gName(0 To 3) As String
Private gActive(0 To 3) As Boolean
Private gHasNote(0 To 3) As Boolean
Private gNote(0 To 3) As String
Private gRow As Long

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

Private Sub InitData()
    gId(0) = 1: gPrice(0) = 12.5:  gName(0) = "Alpha": gActive(0) = True:  gHasNote(0) = True:  gNote(0) = "first"
    gId(1) = 2: gPrice(1) = 9.99:  gName(1) = "Beta":  gActive(1) = False: gHasNote(1) = True:  gNote(1) = "second"
    gId(2) = 3: gPrice(2) = 0:     gName(2) = "Gamma": gActive(2) = True:  gHasNote(2) = False: gNote(2) = ""
    gId(3) = 4: gPrice(3) = 47.75: gName(3) = "Delta": gActive(3) = True:  gHasNote(3) = True:  gNote(3) = "fourth"
End Sub

Public Sub Run()
    Dim Job As Long
    Dim Lrpt As String, OutPdf As String, OutTxt As String, Xml As String

    InitData

    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Pdf.RptSetRptLicenseKey RPT_DEMO_KEY
    mEng = Pdf.RptCreateEngine("")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.LastErrorMessage: Exit Sub

    If Not Pdf.RptRegisterProviderEvent(mEng, "mydata") Then
        Debug.Print "RptRegisterProviderEvent failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    End If
    Debug.Print "registered custom provider ""mydata"""

    Lrpt = App.Path & "\08_custom.lrpt"
    OutPdf = App.Path & "\08_custom.pdf"
    OutTxt = App.Path & "\08_custom.txt"
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""CustomProvider"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <datasources><datasource alias=""d"" provider=""mydata"" conn="""" query=""""/></datasources>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""12"">" & vbLf
    Xml = Xml & "   <text name=""t"" x=""0"" y=""0"" w=""180"" h=""8"" fontSize=""16"" hAlign=""center"" wordWrap=""0"">Custom Provider - typed rows</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""pageheader"" name=""ph"" height=""7"">" & vbLf
    Xml = Xml & "   <text name=""h1"" x=""0""   y=""0"" w=""20"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Id</text>" & vbLf
    Xml = Xml & "   <text name=""h2"" x=""22""  y=""0"" w=""40"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Name</text>" & vbLf
    Xml = Xml & "   <text name=""h3"" x=""64""  y=""0"" w=""30"" h=""5"" fontSize=""9"" bold=""1"" hAlign=""right"" wordWrap=""0"">Price</text>" & vbLf
    Xml = Xml & "   <text name=""h4"" x=""98""  y=""0"" w=""24"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Active</text>" & vbLf
    Xml = Xml & "   <text name=""h5"" x=""126"" y=""0"" w=""50"" h=""5"" fontSize=""9"" bold=""1"" wordWrap=""0"">Note</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & "  <band kind=""detail"" name=""det"" height=""6"" data=""d"">" & vbLf
    Xml = Xml & "   <text name=""c1"" x=""0""   y=""0"" w=""20"" h=""5"" fontSize=""9"" wordWrap=""0"">{{Id}}</text>" & vbLf
    Xml = Xml & "   <text name=""c2"" x=""22""  y=""0"" w=""40"" h=""5"" fontSize=""9"" wordWrap=""0"">{{Name}}</text>" & vbLf
    Xml = Xml & "   <text name=""c3"" x=""64""  y=""0"" w=""30"" h=""5"" fontSize=""9"" hAlign=""right"" wordWrap=""0"">{{expr: FORMATNUM('#,##0.00', Price) }}</text>" & vbLf
    Xml = Xml & "   <text name=""c4"" x=""98""  y=""0"" w=""24"" h=""5"" fontSize=""9"" wordWrap=""0"">{{expr: CSTR(Active) }}</text>" & vbLf
    Xml = Xml & "   <text name=""c5"" x=""126"" y=""0"" w=""50"" h=""5"" fontSize=""9"" wordWrap=""0"">{{expr: IFNULL(Note, '(none)') }}</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText Lrpt, Xml

    Job = Pdf.RptOpenReport(mEng, Lrpt)
    If Job = 0 Then Debug.Print "open failed: " & Pdf.LastErrorMessage: GoTo Cleanup
    If Pdf.RptRender(Job) = 0 Then Debug.Print "render failed: " & Pdf.LastErrorMessage: Pdf.RptCloseReport Job: GoTo Cleanup
    Debug.Print "rendered " & Pdf.RptGetPageCount(Job) & " page(s) from the custom provider"
    Pdf.RptExport Job, 0, OutPdf
    Pdf.RptExport Job, RPT_EXP_TEXT, OutTxt
    Debug.Print "wrote " & OutPdf & "  +  " & OutTxt
    Pdf.RptCloseReport Job
Cleanup:
    Pdf.RptDeleteEngine mEng
End Sub

' ---- provider event handlers ------------------------------------------------

Private Sub Pdf_OnRptOpen(ByVal ProviderName As String, ByVal Conn As String, ByVal Query As String, ByVal CursorId As Long, ResultCode As Long)
    gRow = -1
    ResultCode = 0
End Sub

Private Sub Pdf_OnRptGetSchema(ByVal CursorId As Long, Schema As Variant, ResultCode As Long)
    Schema = Array( _
        Array("Id", vkInt), _
        Array("Price", vkFloat), _
        Array("Name", vkStr), _
        Array("Active", vkBool), _
        Array("Note", vkStr))
    ResultCode = 0
End Sub

Private Sub Pdf_OnRptFetch(ByVal CursorId As Long, HasRow As Variant, ResultCode As Long)
    gRow = gRow + 1
    HasRow = (gRow <= UBound(gId))
    ResultCode = 0
End Sub

Private Sub Pdf_OnRptGetVal(ByVal CursorId As Long, ByVal AField As Long, AValue As Variant, ResultCode As Long)
    Select Case AField
        Case 0: AValue = gId(gRow)
        Case 1: AValue = gPrice(gRow)
        Case 2: AValue = gName(gRow)
        Case 3: AValue = gActive(gRow)
        Case 4: If gHasNote(gRow) Then AValue = gNote(gRow) Else AValue = Null
        Case Else: AValue = Null
    End Select
    ResultCode = 0
End Sub

Private Sub Pdf_OnRptClose(ByVal CursorId As Long, ResultCode As Long)
    ResultCode = 0
End Sub
