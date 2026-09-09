Attribute VB_Name = "modPrintPdf"
Option Explicit
' ============================================================================
'  print_pdf -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors the
'  plain-DLL example at examples\Vb6\rendering_engine\print_pdf (read-only
'  reference, not modified). Loads a PDF, imports the first page and prints
'  it. A printer is chosen through the standard Print dialog (PrintDlg),
'  exactly as the reference original.
'
'  Mapping: pdfXxx(IPDF, args) -> pdf.Xxx(args); PrintPDFFileA's DC parameter
'  is a 64-bit handle in the ActiveX interface, which the mandated late-bound
'  CreateObject("LumasPdf.PDF") call marshals transparently through IDispatch
'  (unlike an early-bound reference, which cannot declare an I8 parameter).
'  Compile-only in an unattended/headless run (needs a printer + interactive
'  Print dialog); the printed-page confirmation only appears with both.
' ============================================================================

Private Type PRINTDLG
    lStructSize As Long
    hwndOwner As Long
    hDevMode As Long
    hDevNames As Long
    hDC As Long
    Flags As Long
    nFromPage As Integer
    nToPage As Integer
    nMinPage As Integer
    nMaxPage As Integer
    nCopies As Integer
    hInstance As Long
    lCustData As Long
    lpfnPrintHook As Long
    lpfnSetupHook As Long
    lpPrintTemplateName As Long
    lpSetupTemplateName As Long
    hPrintTemplate As Long
    hSetupTemplate As Long
End Type

Private Declare Function PrintDlg Lib "comdlg32.dll" Alias "PrintDlgA" (ByRef pPD As PRINTDLG) As Long
Private Declare Function DeleteDC Lib "gdi32" (ByVal hDC As Long) As Long

Private Const PD_RETURNDC As Long = &H100
Private Const PD_HIDEPRINTTOFILE As Long = &H100000
Private Const PD_DISABLEPRINTTOFILE As Long = &H80000
Private Const PD_NOSELECTION As Long = &H4

' ---- LumasPdf enum constants (no project reference -> declared by value;
'      see wrappers\vb6\LumasPDFInt.bas for the authoritative numbering) ------
Private Const ptOpen As Long = 0                    ' TPasswordType
Private Const ifImportAll As Long = &HFFFFFFE        ' TImportFlags
Private Const ifImportAsPage As Long = &H80000000
Private Const aePrint As Long = 2                    ' TOCAppEvent
Private Const pffDefault As Long = &H0               ' TPDFPrintFlags
Private Const pffAutoRotateAndCenter As Long = &H4
Private Const pffShrinkToPrintArea As Long = &H10

Private Function GetPrinterDC() As Long
    Dim pd As PRINTDLG
    pd.lStructSize = Len(pd)
    pd.Flags = PD_RETURNDC Or PD_HIDEPRINTTOFILE Or PD_DISABLEPRINTTOFILE Or PD_NOSELECTION
    If PrintDlg(pd) <> 0 Then
        GetPrinterDC = pd.hDC
    Else
        Debug.Print "Cancelled!"
        GetPrinterDC = 0
    End If
End Function

Public Sub Main()
    Dim pdf As Object
    Dim dc As Long

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFA ""   ' We create no PDF file in this example

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFileA(App.path & "\..\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

    ' We print only the first page in this example.
    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    ' ApplyAppEvent makes sure the same result is printed that Acrobat would print (layers, etc.).
    pdf.ApplyAppEvent aePrint, False

    dc = GetPrinterDC()
    If dc <> 0 Then
        If pdf.PrintPDFFileA("", "Test Print", dc, pffDefault Or pffAutoRotateAndCenter Or pffShrinkToPrintArea, 0, 0) Then
            Debug.Print "Page 1 successfully printed"
        End If
        DeleteDC dc
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "print_pdf"
End Sub
