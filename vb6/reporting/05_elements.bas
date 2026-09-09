Attribute VB_Name = "mod05_elements"
Option Explicit

' ===========================================================================
'  VB6 mirror of examples\delphi\reporting -- LumasReport (rpt*) exports.
'  Translated 1:1 from the Delphi original; OO/flat rpt* calls -> flat rpt*.
' ===========================================================================

Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

Private Pdf As CPDF
Private mEng As Long


Private mBmp() As Byte
Private mBi As Long

Private Function TrimNull(ByVal s As String) As String
    Dim p As Long
    p = InStr(s, Chr$(0))
    If p > 0 Then TrimNull = Left$(s, p - 1) Else TrimNull = s
End Function

Private Sub WriteText(ByVal Path As String, ByVal Content As String)
    Dim f As Integer
    f = FreeFile
    Open Path For Output As #f
    Print #f, Content;
    Close #f
End Sub

Private Sub DumpRptError(ByVal Eng As Long)
    Debug.Print "  ! " & Pdf.GetErrorMessage()
End Sub

Private Function BootEngine() As Boolean
    BootEngine = False
    Set Pdf = New CPDF
' pdf.RaiseExceptions = True
    Pdf.SetLicenseKey PDF_DEMO_KEY
    Call rptSetRptLicenseKeyA(Pdf.GetInstancePtr(), RPT_DEMO_KEY)
    mEng = rptCreateEngineA(Pdf.GetInstancePtr(), "")
    If mEng = 0 Then Debug.Print "rptCreateEngine failed: " & Pdf.GetErrorMessage(): Exit Function
    BootEngine = True
End Function

Private Sub PutB(ByVal v As Long)
    mBmp(mBi) = v And &HFF&
    mBi = mBi + 1
End Sub
Private Sub PutW(ByVal v As Long)
    PutB v And &HFF&
    PutB (v \ 256) And &HFF&
End Sub
Private Sub PutD(ByVal v As Long)
    PutB v And &HFF&
    PutB (v \ &H100&) And &HFF&
    PutB (v \ &H10000) And &HFF&
    PutB (v \ &H1000000) And &HFF&
End Sub

Private Sub WriteBmp8x8(ByVal Path As String)
    Dim X As Long, Y As Long, f As Integer
    ReDim mBmp(0 To 54 + 192 - 1)
    mBi = 0
    ' BITMAPFILEHEADER
    PutB Asc("B"): PutB Asc("M")
    PutD 54 + 192
    PutD 0
    PutD 54
    ' BITMAPINFOHEADER
    PutD 40
    PutD 8: PutD 8
    PutW 1
    PutW 24
    PutD 0
    PutD 192
    PutD 2835: PutD 2835
    PutD 0: PutD 0
    ' pixels bottom-up BGR
    For Y = 0 To 7
        For X = 0 To 7
            If ((X + Y) And 1) = 0 Then
                PutB 0: PutB 0: PutB 255
            Else
                PutB 255: PutB 0: PutB 0
            End If
        Next
    Next
    f = FreeFile
    Open Path For Binary As #f
    Put #f, , mBmp
    Close #f
End Sub

Public Sub Main()
    Dim Job As Long
    Dim Lrpt As String, Sub_ As String, Img As String, OutPdf As String, Xml As String

    If Not BootEngine() Then Exit Sub

    Lrpt = App.Path & "\05_elements.lrpt"
    Sub_ = App.Path & "\05_sub.lrpt"
    Img = App.Path & "\05_img.bmp"
    OutPdf = App.Path & "\05_elements.pdf"

    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""Sub"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""70"" height=""30"" marginLeft=""1"" marginTop=""1"" marginRight=""1"" marginBottom=""1""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""sh"" height=""10"">" & vbLf
    Xml = Xml & "   <text name=""st"" x=""0"" y=""0"" w=""66"" h=""6"" fontSize=""8"">Subreport content here.</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText Sub_, Xml
    WriteBmp8x8 Img
    Xml = ""
    Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
    Xml = Xml & "<report name=""Elements"" tagLangVersion=""1"">" & vbLf
    Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
    Xml = Xml & " <bands>" & vbLf
    Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""150"">" & vbLf
    Xml = Xml & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">Every Element Kind</text>" & vbLf
    Xml = Xml & "   <text name=""note""  x=""0"" y=""12"" w=""180"" h=""6"" fontSize=""9"" hAlign=""center"">text / line / shape / image / barcode / subreport</text>" & vbLf
    Xml = Xml & "   <line  name=""rule"" x=""0"" y=""20"" w=""180"" h=""0.3"" toX=""180"" toY=""0""/>" & vbLf
    Xml = Xml & "   <shape name=""rect"" x=""0""  y=""26"" w=""55"" h=""22"" shape=""0""/>" & vbLf
    Xml = Xml & "   <shape name=""rrct"" x=""63"" y=""26"" w=""55"" h=""22"" shape=""1""/>" & vbLf
    Xml = Xml & "   <shape name=""elps"" x=""126"" y=""26"" w=""55"" h=""22"" shape=""2""/>" & vbLf
    Xml = Xml & "   <text name=""l1"" x=""0""   y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=0 rect</text>" & vbLf
    Xml = Xml & "   <text name=""l2"" x=""63""  y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=1 roundrect</text>" & vbLf
    Xml = Xml & "   <text name=""l3"" x=""126"" y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=2 ellipse</text>" & vbLf
    Xml = Xml & "   <image name=""pic"" x=""0"" y=""58"" w=""24"" h=""24"" source=""" & Img & """ stretch=""1""/>" & vbLf
    Xml = Xml & "   <text name=""il"" x=""0"" y=""83"" w=""40"" h=""5"" fontSize=""7"">8x8 BMP image</text>" & vbLf
    Xml = Xml & "   <barcode name=""qr""  x=""40""  y=""58"" w=""24"" h=""24"" type=""0"" text=""QR:LumasReport""/>" & vbLf
    Xml = Xml & "   <barcode name=""pdf"" x=""70""  y=""58"" w=""40"" h=""24"" type=""1"" text=""PDF417-DATA-001""/>" & vbLf
    Xml = Xml & "   <barcode name=""dm""  x=""116"" y=""58"" w=""24"" h=""24"" type=""2"" text=""DataMatrix99""/>" & vbLf
    Xml = Xml & "   <barcode name=""az""  x=""146"" y=""58"" w=""24"" h=""24"" type=""3"" text=""AZTEC-XYZ""/>" & vbLf
    Xml = Xml & "   <text name=""bl"" x=""40"" y=""83"" w=""140"" h=""5"" fontSize=""7"">barcodes: QR / PDF417 / DataMatrix / Aztec</text>" & vbLf
    Xml = Xml & "   <subreport name=""sub"" x=""0"" y=""92"" w=""90"" h=""30"" ref=""05_sub.lrpt""/>" & vbLf
    Xml = Xml & "   <text name=""sl"" x=""0"" y=""123"" w=""120"" h=""5"" fontSize=""7"">^ subreport (05_sub.lrpt) merged above</text>" & vbLf
    Xml = Xml & "  </band>" & vbLf
    Xml = Xml & " </bands>" & vbLf
    Xml = Xml & "</report>" & vbLf
    WriteText Lrpt, Xml

    Job = rptOpenReport(mEng, Lrpt)
    If Job = 0 Then
        Debug.Print "open failed": DumpRptError mEng: GoTo Cleanup
    End If
    If rptRender(Job) = 0 Then
        Debug.Print "render failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "rendered " & rptGetPageCount(Job) & " page(s)"
    If rptExportA(Job, 0, OutPdf) = 0 Then
        Debug.Print "export failed": DumpRptError mEng: rptCloseReport Job: GoTo Cleanup
    End If
    Debug.Print "wrote " & OutPdf
    rptCloseReport Job
Cleanup:
    rptDeleteEngine mEng
End Sub
